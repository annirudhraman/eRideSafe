#!/usr/bin/env python3
"""Regenerate the offline Sammamish public street overlays from the city's GIS.

Uses only Python's standard library. --input accepts a previously fetched ArcGIS
feature array for offline verification. --check validates without changing Swift.
No route connections or legal access rules are inferred by this data importer.
"""

import argparse
import collections
import hashlib
import json
import math
from pathlib import Path
import re
import urllib.parse
import urllib.request


SOURCE = "https://maps.sammamishwa.gov/arcgis/rest/services/Roads/Streets/MapServer/0"
OUTPUT = Path(__file__).resolve().parents[1] / "eRideSafe/Models/SafetyMapData.swift"
BEGIN = "    // BEGIN GENERATED PUBLIC STREETS"
END = "    // END GENERATED PUBLIC STREETS"
ROAD_CLASSES = {"Local", "Local Access", "Collector", "Minor Arterial", "Principal Arterial"}
LOCAL_CLASSES = {"Local", "Local Access"}
SIMPLIFY_METERS = 1.0
PRECISION = 1_000_000


def request(params):
    url = SOURCE + "/query?" + urllib.parse.urlencode({"f": "json", **params})
    with urllib.request.urlopen(url, timeout=60) as response:
        result = json.load(response)
    if "error" in result:
        raise RuntimeError(result["error"])
    return result


def fetch_features():
    params = {
        "where": "PubPvt = 'Public' AND Owner = 'Sammamish' AND InCity = 'Y'",
        "outFields": "OBJECTID,FULLNAME,PubPvt,Owner,InCity,FuncClass,FuncType",
        "returnGeometry": "true",
        "outSR": 4326,
        "orderByFields": "OBJECTID ASC",
    }
    expected_count = request({"where": params["where"], "returnCountOnly": "true"})["count"]
    features = []
    while True:
        result = request({**params, "resultOffset": len(features), "resultRecordCount": 1000})
        page = result.get("features", [])
        if result.get("exceededTransferLimit") and not page:
            raise RuntimeError("GIS pagination stopped before all records were returned")
        features.extend(page)
        if not result.get("exceededTransferLimit"):
            break
    if len(features) != expected_count:
        raise RuntimeError(f"GIS count changed or response was truncated: {len(features)} != {expected_count}")
    return features


def distance_squared(point, start, end):
    dx, dy = end[0] - start[0], end[1] - start[1]
    length = dx * dx + dy * dy
    t = max(0, min(1, ((point[0] - start[0]) * dx + (point[1] - start[1]) * dy) / length)) if length else 0
    return (point[0] - start[0] - t * dx) ** 2 + (point[1] - start[1] - t * dy) ** 2


def simplify(path):
    # Local equirectangular distances are sufficient over this one city's extent.
    # Keep each source path's endpoints and never join separate source features.
    scale_x = 111_320 * math.cos(math.radians(sum(p[1] for p in path) / len(path)))
    xy = [(p[0] * scale_x, p[1] * 111_320) for p in path]
    keep = {0, len(path) - 1}
    stack = [(0, len(path) - 1)]
    while stack:
        start, end = stack.pop()
        if end <= start + 1:
            continue
        deviation, index = max((distance_squared(xy[i], xy[start], xy[end]), i) for i in range(start + 1, end))
        if deviation > SIMPLIFY_METERS ** 2:
            keep.add(index)
            stack.extend([(start, index), (index, end)])
    retained = sorted(keep)
    # Validate the simplification bound against every original vertex.
    for start, end in zip(retained, retained[1:]):
        assert all(distance_squared(xy[i], xy[start], xy[end]) <= SIMPLIFY_METERS ** 2 + 1e-8 for i in range(start, end + 1))
    return [path[i] for i in retained]


def encode(path):
    previous = [0, 0]
    encoded = []
    for longitude, latitude, *_ in path:
        for axis, number in enumerate((latitude, longitude)):
            value = round(number * PRECISION)
            delta = value - previous[axis]
            previous[axis] = value
            delta = ~(delta << 1) if delta < 0 else delta << 1
            while delta >= 0x20:
                encoded.append(chr((0x20 | (delta & 0x1F)) + 63))
                delta >>= 5
            encoded.append(chr(delta + 63))
    return "".join(encoded)


def road_name(name):
    words = name.strip().title().split()
    return " ".join(word.upper() if word.upper() in {"NE", "SE", "NW", "SW", "N", "S", "E", "W"} else re.sub(r"(\d+)(Th|St|Nd|Rd)", lambda match: match[0].lower(), word) for word in words)


def generate(features):
    by_category = {"cautionRoads": [], "localRoads": []}
    seen = set()
    counts = collections.Counter()
    source_subset = []
    source_vertices = rendered_vertices = 0
    for feature in sorted(features, key=lambda f: f["attributes"]["OBJECTID"]):
        attributes = feature["attributes"]
        identifier = attributes["OBJECTID"]
        assert identifier not in seen, f"Duplicate feature {identifier}"
        seen.add(identifier)
        if not (attributes.get("PubPvt") == "Public" and attributes.get("Owner") == "Sammamish" and attributes.get("InCity") == "Y"):
            continue
        classification = attributes.get("FuncClass")
        if classification not in ROAD_CLASSES or not attributes.get("FULLNAME") or attributes.get("FuncType") == "Driveway":
            continue
        source_subset.append({"id": identifier, "name": attributes["FULLNAME"], "class": classification, "geometry": feature["geometry"]})
        category = "localRoads" if classification in LOCAL_CLASSES else "cautionRoads"
        context = "Local Access" if classification in LOCAL_CLASSES else classification
        for path_index, path in enumerate(feature["geometry"]["paths"]):
            if len(path) < 2:
                raise ValueError(f"Invalid street path: {identifier}/{path_index}")
            # Catch wrong coordinate order, wrong spatial reference or remote data.
            assert all(-122.15 < p[0] < -121.95 and 47.54 < p[1] < 47.71 for p in path), identifier
            simplified = simplify(path)
            polyline = encode(simplified)
            fields = [f"city-street-{identifier}-{path_index}", road_name(attributes["FULLNAME"]), context, polyline]
            assert all("\t" not in field and "\n" not in field for field in fields)
            by_category[category].append("        " + "\t".join(fields))
            counts[context] += 1
            source_vertices += len(path)
            rendered_vertices += len(simplified)

    digest = hashlib.sha256(json.dumps(source_subset, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
    sections = [BEGIN,
        "    // Generated by scripts/update_safety_map_roads.py; do not edit these rows.",
        "    // Public, in-city, named streets only. Maximum simplification deviation: 1 m.",
        "    // Six-decimal polyline coordinates retain bends and source path endpoints.",
        f"    // Geometry/attribute SHA-256: {digest}",
        f'    static let streetGeometrySource = "City of Sammamish street centerlines"',
        f'    static let streetGeometrySourceURL = URL(string: "{SOURCE}")!', ""]
    for category, rows in by_category.items():
        sections += [f'    static let {category}: [SafetyMapLine] = decodeStreetRows(#"""', *rows, '        """#)', ""]
    sections += [END]
    print(f"Validated {sum(counts.values())} public street paths: {dict(counts)}")
    print(f"Vertices: {source_vertices:,} -> {rendered_vertices:,}; source SHA-256 {digest}")
    return "\n".join(sections)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, help="Read cached ArcGIS features instead of fetching")
    parser.add_argument("--snapshot-output", type=Path, help="Optionally save the downloaded feature array")
    parser.add_argument("--check", action="store_true", help="Verify generated Swift is unchanged")
    args = parser.parse_args()
    features = json.loads(args.input.read_text()) if args.input else fetch_features()
    if args.snapshot_output:
        args.snapshot_output.write_text(json.dumps(features, separators=(",", ":")) + "\n")
    generated = generate(features)
    current = OUTPUT.read_text()
    if BEGIN in current:
        start = current.index(BEGIN)
        end = current.index(END, start) + len(END)
    else:
        start = current.index("    static let cautionRoads:")
        end = current.index("    static let restrictedTrails:")
        generated += "\n\n"
    updated = current[:start] + generated + current[end:]
    if args.check:
        if current != updated:
            raise SystemExit("Generated streets differ; regenerate and review the map data")
        print("Generated street data matches the checked-in Swift.")
    else:
        OUTPUT.write_text(updated)


if __name__ == "__main__":
    main()
