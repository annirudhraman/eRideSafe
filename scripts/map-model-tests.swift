import Foundation
import MapKit

/// Run from the project root with: bash scripts/test-map-models.sh
@main
enum MapModelTests {
    static func main() {
        checkPermissions()
        checkProximity()
        checkStreetCoverage()
        print("Map model checks passed: class access, parallel road/path detection, and public street coverage.")
    }

    private static func checkPermissions() {
        for path in SammamishZones.sharedPaths {
            for bikeClass: DeviceClass in [.class1, .class2] {
                guard case .legal = path.permission(for: bikeClass) else {
                    fatalError("Class 1/2 should be allowed on the two verified shared paths")
                }
            }
            assert(path.permission(for: .class3).isProhibited)
            assert(path.permission(for: .electricMotorcycle).isProhibited)
            assert(path.speedLimitMPH == 15)
        }

        for road in SammamishZones.roadways {
            for bikeClass: DeviceClass in [.class1, .class2, .class3] {
                assert(!road.permission(for: bikeClass).isProhibited, "Traffic caution must not become an access ban")
            }
            assert(road.permission(for: .class3).message.contains("16 or older"))
            guard case .conditional = road.permission(for: .electricMotorcycle) else {
                fatalError("Motorcycle access needs street-legal vehicle and rider requirements")
            }
            assert(road.speedLimitMPH == nil, "Street classification is not a posted speed limit")
        }

        let naturalTrail = zone(name: "Natural trail", facility: .naturalSurfaceTrail, offset: 0)
        for bikeClass in DeviceClass.allCases {
            assert(naturalTrail.permission(for: bikeClass).isProhibited)
        }
    }

    private static func checkProximity() {
        let path = zone(name: "Path", facility: .pavedSharedUsePath, offset: 0)
        let road = zone(name: "Parallel road", facility: .roadway, offset: 20)
        let candidates = [path, road]

        assert(SammamishZones.nearestZone(to: nil, among: candidates) == nil)
        assert(path.distance(to: coordinate(east: 0)) < 0.01)
        assert(abs(path.distance(to: coordinate(east: 10)) - 10) < 0.1)
        assert(SammamishZones.nearestZone(to: coordinate(east: 2), among: candidates)?.id == path.id)
        assert(SammamishZones.nearestZone(to: coordinate(east: 18), among: candidates)?.id == road.id)
        assert(SammamishZones.nearestZone(to: coordinate(east: 10), among: candidates) == nil,
               "A point between parallel facilities must not imply a class-specific rule")
        assert(SammamishZones.nearestZone(to: coordinate(east: -12.5), among: [path]) == nil,
               "The old 40–55m path catchment must not return")
        assert(SammamishZones.nearestZone(to: coordinate(east: 60), among: candidates) == nil)

        let fartherRoad = zone(name: "Farther road", facility: .roadway, offset: 30)
        assert(SammamishZones.nearestZone(to: coordinate(east: 13), among: [path, fartherRoad]) == nil,
               "Do not skip a nearer unmatched path and snap to a farther road")

        let empty = RideZone(name: "Empty", facility: .roadway, level: .green,
                             coordinates: [], referenceCoordinate: coordinate(east: 0),
                             detectionToleranceMeters: 18, speedLimitMPH: nil,
                             detail: "", geometrySource: "Test fixture")
        assert(SammamishZones.nearestZone(to: coordinate(east: 0), among: [empty]) == nil)
    }

    private static func checkStreetCoverage() {
        assert(SammamishZones.sharedPaths.count == 2)
        assert(SafetyMapData.localRoads.count > 100, "Local road coverage should extend beyond the old two paths")
        assert(SafetyMapData.cautionRoads.count > 50, "Caution coverage should retain detailed city street segments")
        assert(SammamishZones.roadways.count == SafetyMapData.localRoads.count + SafetyMapData.cautionRoads.count)
        assert(Set((SafetyMapData.localRoads + SafetyMapData.cautionRoads).map(\.id)).count == SammamishZones.roadways.count)
        assert(SammamishZones.all.count == SammamishZones.roadways.count + 2)
        for road in SammamishZones.roadways {
            assert(road.coordinates.count >= 2)
            assert(road.coordinates.allSatisfy { CLLocationCoordinate2DIsValid($0) })
            assert(!road.geometrySource.isEmpty)
        }
    }

    private static func zone(name: String, facility: RideFacilityType, offset: Double) -> RideZone {
        RideZone(name: name, facility: facility, level: facility == .roadway ? .orange : .yellow,
                 coordinates: [coordinate(east: offset, north: -100), coordinate(east: offset, north: 100)],
                 referenceCoordinate: coordinate(east: offset),
                 detectionToleranceMeters: facility == .roadway ? 18 : 12,
                 speedLimitMPH: facility == .roadway ? nil : 15,
                 detail: "", geometrySource: "Test fixture")
    }

    private static func coordinate(east: Double, north: Double = 0) -> CLLocationCoordinate2D {
        let origin = MKMapPoint(CLLocationCoordinate2D(latitude: 47.6, longitude: -122.03))
        let scale = MKMapPointsPerMeterAtLatitude(47.6)
        return MKMapPoint(x: origin.x + east * scale, y: origin.y - north * scale).coordinate
    }
}
