# Map data and verification

The offline road snapshot was retrieved on September 5, 2026 from the [City of Sammamish street centerline service](https://maps.sammamishwa.gov/arcgis/rest/services/Roads/Streets/MapServer/0). The service description reports “Last Update: 3/10/2021”; retrieval does not establish that every street or attribute is current. Temporary closures and new construction are not included.

## Coverage

- 2,562 separate geometry paths across 632 unique public street names.
- 334 arterial/collector paths (156 minor arterial, 76 principal arterial, 102 collector), covering 41 street names. These restore detailed geometry and missing sections of the previous 50 simplified caution overlays.
- 2,228 local-road paths covering 612 names; some street names span multiple classifications.
- Only named streets with `PubPvt = Public`, `Owner = Sammamish`, `InCity = Y`, and a recognized public-road classification are included. Driveways, private classifications, and unknown classifications are excluded.
- Individual source paths remain separate; disconnected segments are never joined. Geometry is simplified to a maximum 1 m deviation before six-decimal coordinate encoding. The original 145,360 vertices become 11,380 vertices.
- Local roads appear at street scale; arterial and collector overlays remain visible at city scale. These classifications identify a road's network role, not measured danger, traffic volume, or bicycle-lane availability.

The two existing paved shared paths retain their WSDOT/City GIS geometry. Existing natural-surface trail geometry is retained. These older layers were not newly surveyed in this update.

Schools appear as 17 physical-location markers with no radius overlays or invented school-zone boundaries. Existing school point locations are retained except that the incorrect separate Renaissance point was removed: [Renaissance's school site](https://rsar.lwsd.org/about-us) places it at the Eastlake campus. The marker names both schools. School proximity reminders use an internal 300 m awareness distance; this is not a legal zone. [City guidance](https://www.sammamish.us/government/public-works/traffic-engineering/school-zone-safety/) defines school zones using the start/end signs and active flashers.

## Access rules

Road geometry does not itself establish a bicycle permission. The class rules follow [City e-bike guidance](https://www.sammamish.us/government/police/e-bicycles-e-motorcycles/), [RCW 46.61.710](https://app.leg.wa.gov/rcw/default.aspx?cite=46.61.710), [the Class 3 age rule](https://apps.leg.wa.gov/RCW/default.aspx?cite=46.20.500), and [King County Parks rules](https://kingcounty.gov/en/dept/dnrp/nature-recreation/parks-recreation/king-county-parks/about-us/parks-rules), checked September 5, 2026.

Class 1–3 e-bikes can use public roadway bicycle facilities subject to posted restrictions. Class 3 riders must be at least 16. Electric motorcycle roadway access is conditional on street-legal equipment and rider requirements and does not include bicycle lanes. The two identified shared paths permit Classes 1 and 2, prohibit Class 3 and motorcycles, and have 15 mph guidance. The map does not assign guessed speed limits to roadways. Road detail sheets link to the governing guidance.

Map matching uses narrow road/path tolerances and returns no access assertion when parallel facilities cannot be distinguished. The map and Ride Mode require reported horizontal accuracy of 12 m or better for a facility status; users can always inspect a route manually.

## Refresh and checks

From the project root:

```sh
python3 scripts/update_safety_map_roads.py
bash scripts/test-map-models.sh
```

The importer uses only Python's standard library. It validates pagination, public ownership, coordinate bounds, simplification deviation, and source identifiers. `--snapshot-output <file.json>` saves source features; `--input <file.json> --check` reproduces and verifies the embedded Swift without network access. A SHA-256 digest of selected geometry and attributes is included in the generated source.

The Swift regression script compiles the actual models and verifies class permissions, ambiguous parallel roads/paths, nil roadway limits, coordinate validity, and expanded street coverage. Build verification uses the existing eRideSafe Xcode project and iOS Simulator SDK. Temporary simulator UI checks and build output live in `.codex-work`.

## Verification completed September 5, 2026

- Original Xcode project: Debug simulator build succeeded for arm64 and x86_64.
- Actual-model Swift regression checks passed.
- Cached GIS regeneration matched the embedded Swift exactly.
- iPhone 17 Pro / iOS 26.2: class switching, school search and details, detail dismissal, shared-path class comparison, roadway taps and class comparison, and satellite layer switching were exercised. The focused roadway/layer UI test passed. School and path flows passed before an earlier test's incorrectly positioned map tap was corrected.
- Visual review caught and fixed an unsupported school symbol and overlapping labels. Search selection now explicitly closes its sheet before changing the map camera.
- Latest school and class-comparison screenshots: `.codex-work/map-preview.png` and `.codex-work/map-class-access.png`.
