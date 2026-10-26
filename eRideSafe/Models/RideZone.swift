import Foundation
import MapKit
import SwiftUI

enum ZoneLevel: String, Codable {
    case green
    case yellow
    case orange
    case red
    case black

    var title: String {
        switch self {
        case .green: "Local road"
        case .yellow: "Shared-use path"
        case .orange: "Elevated traffic stress"
        case .red: "High traffic stress"
        case .black: "Motorized use restricted"
        }
    }

    var color: Color {
        switch self {
        case .green: Color.green
        case .yellow: Color.yellow
        case .orange: Color.orange
        case .red: Color.red
        case .black: Color.black
        }
    }
}

enum RideFacilityType: String, Codable {
    case pavedSharedUsePath
    case roadway
    case naturalSurfaceTrail

    var title: String {
        switch self {
        case .pavedSharedUsePath: "Paved shared-use path"
        case .roadway: "Public roadway"
        case .naturalSurfaceTrail: "Natural-surface trail or boardwalk"
        }
    }
}

enum RidePermission {
    case legal(message: String)
    case caution(message: String)
    case conditional(message: String)
    case prohibited(message: String)

    var title: String {
        switch self {
        case .legal: "Access allowed"
        case .caution: "Allowed · use caution"
        case .conditional: "Conditional access"
        case .prohibited: "Not permitted"
        }
    }

    var systemImage: String {
        switch self {
        case .legal: "checkmark.circle.fill"
        case .caution: "exclamationmark.triangle.fill"
        case .conditional: "checkmark.shield.fill"
        case .prohibited: "xmark.octagon.fill"
        }
    }

    var color: Color {
        switch self {
        case .legal: Color.green
        case .caution: Color.orange
        case .conditional: Color.orange
        case .prohibited: Color.red
        }
    }

    var message: String {
        switch self {
        case .legal(let message), .caution(let message), .conditional(let message), .prohibited(let message): message
        }
    }

    var isProhibited: Bool {
        if case .prohibited = self { return true }
        return false
    }
}

struct RideZone: Identifiable {
    let id = UUID()
    let name: String
    let facility: RideFacilityType
    let level: ZoneLevel
    let coordinates: [CLLocationCoordinate2D]
    let referenceCoordinate: CLLocationCoordinate2D
    let detectionToleranceMeters: CLLocationDistance
    let speedLimitMPH: Double?
    let detail: String
    let geometrySource: String

    var permissionSourceTitle: String {
        name == "East Lake Sammamish Trail"
            ? "King County Parks rules"
            : "City of Sammamish e-bike guidance"
    }

    var permissionSourceURL: URL {
        if name == "East Lake Sammamish Trail" {
            return URL(string: "https://kingcounty.gov/en/dept/dnrp/nature-recreation/parks-recreation/king-county-parks/about-us/parks-rules")!
        }
        return URL(string: "https://www.sammamish.us/government/police/e-bicycles-e-motorcycles/")!
    }

    func permission(for deviceClass: DeviceClass) -> RidePermission {
        switch facility {
        case .pavedSharedUsePath:
            switch deviceClass {
            case .class1, .class2:
                let limit = speedLimitMPH.map { " Keep to the \(Int($0)) mph limit." } ?? " Follow the posted speed limit."
                return .legal(message: "Class 1 and 2 e-bikes are permitted on this paved shared-use path.\(limit) Yield to pedestrians and obey closures.")
            case .class3:
                return .prohibited(message: "Class 3 e-bikes are not permitted on this shared-use path. Use an allowed roadway facility; slowing down does not change the bike's class.")
            case .electricMotorcycle:
                return .prohibited(message: "Electric motorcycles are not permitted on shared-use paths, sidewalks, or recreational trails.")
            }

        case .naturalSurfaceTrail:
            return .prohibited(message: "Sammamish prohibits all e-bike classes and electric motorcycles on natural-surface trails and boardwalks unless signs explicitly allow them.")

        case .roadway:
            if deviceClass == .electricMotorcycle {
                return .conditional(message: "Use the roadway only with a street-legal motorcycle, license plate, required lighting and mirrors, registration, insurance, a licensed rider with the required endorsement, and a DOT-approved helmet. Bicycle lanes and shared-use paths are not motorcycle routes.")
            }

            let ageRequirement = deviceClass == .class3 ? " Riders must be 16 or older." : ""
            let access = "\(deviceClass.shortTitle) e-bikes may use this public roadway and its bicycle lanes where provided.\(ageRequirement) Follow traffic laws and posted restrictions."
            switch level {
            case .green:
                return .legal(message: "\(access) Watch for driveways, turning vehicles, and people crossing.")
            case .yellow, .orange:
                return .caution(message: "\(access) This collector or arterial calls for extra care at junctions and alongside traffic. A mapped road does not guarantee a separate bike lane.")
            case .red:
                return .caution(message: "\(access) This principal arterial needs extra care around through traffic and turning vehicles. Check the available space before choosing this route.")
            case .black:
                return .caution(message: "\(access) Check signs and conditions before proceeding.")
            }
        }
    }

    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        guard let first = coordinates.first else { return .greatestFiniteMagnitude }
        guard coordinates.count > 1 else {
            return MKMapPoint(first).distance(to: MKMapPoint(coordinate))
        }

        let point = MKMapPoint(coordinate)
        var minimumDistance = CLLocationDistance.greatestFiniteMagnitude

        for index in 0..<(coordinates.count - 1) {
            let start = MKMapPoint(coordinates[index])
            let end = MKMapPoint(coordinates[index + 1])
            let deltaX = end.x - start.x
            let deltaY = end.y - start.y
            let lengthSquared = (deltaX * deltaX) + (deltaY * deltaY)

            let closestPoint: MKMapPoint
            if lengthSquared == 0 {
                closestPoint = start
            } else {
                let projection = ((point.x - start.x) * deltaX + (point.y - start.y) * deltaY) / lengthSquared
                let clampedProjection = min(1, max(0, projection))
                closestPoint = MKMapPoint(
                    x: start.x + clampedProjection * deltaX,
                    y: start.y + clampedProjection * deltaY
                )
            }

            minimumDistance = min(minimumDistance, point.distance(to: closestPoint))
        }

        return minimumDistance
    }
}

enum SammamishZones {
    static let sharedPaths: [RideZone] = [
        RideZone(
            name: "East Lake Sammamish Trail",
            facility: .pavedSharedUsePath,
            level: .yellow,
            coordinates: [
                .init(latitude: 47.6599713, longitude: -122.0961978),
                .init(latitude: 47.6581105, longitude: -122.0950338),
                .init(latitude: 47.6564481, longitude: -122.0941900),
                .init(latitude: 47.6561000, longitude: -122.0938428),
                .init(latitude: 47.6552173, longitude: -122.0924811),
                .init(latitude: 47.6545795, longitude: -122.0919038),
                .init(latitude: 47.6519505, longitude: -122.0901668),
                .init(latitude: 47.6503598, longitude: -122.0896457),
                .init(latitude: 47.6499226, longitude: -122.0893697),
                .init(latitude: 47.6477122, longitude: -122.0868447),
                .init(latitude: 47.6460949, longitude: -122.0856324),
                .init(latitude: 47.6447421, longitude: -122.0837147),
                .init(latitude: 47.6406910, longitude: -122.0799046),
                .init(latitude: 47.6368673, longitude: -122.0744721),
                .init(latitude: 47.6361930, longitude: -122.0736900),
                .init(latitude: 47.6339020, longitude: -122.0718170),
                .init(latitude: 47.6329022, longitude: -122.0711630),
                .init(latitude: 47.6319482, longitude: -122.0707905),
                .init(latitude: 47.6266434, longitude: -122.0705226),
                .init(latitude: 47.6249017, longitude: -122.0711776),
                .init(latitude: 47.6240367, longitude: -122.0711907),
                .init(latitude: 47.6232167, longitude: -122.0707606),
                .init(latitude: 47.6217995, longitude: -122.0694818),
                .init(latitude: 47.6187702, longitude: -122.0681979),
                .init(latitude: 47.6178049, longitude: -122.0679339),
                .init(latitude: 47.6132128, longitude: -122.0684730),
                .init(latitude: 47.6124154, longitude: -122.0687073),
                .init(latitude: 47.6114770, longitude: -122.0693421),
                .init(latitude: 47.6049580, longitude: -122.0766858),
                .init(latitude: 47.6034787, longitude: -122.0781303),
                .init(latitude: 47.6014425, longitude: -122.0796095),
                .init(latitude: 47.5973930, longitude: -122.0816009),
                .init(latitude: 47.5964721, longitude: -122.0824858),
                .init(latitude: 47.5953814, longitude: -122.0845509),
                .init(latitude: 47.5948811, longitude: -122.0851837),
                .init(latitude: 47.5928936, longitude: -122.0861212),
                .init(latitude: 47.5917250, longitude: -122.0872923),
                .init(latitude: 47.5910163, longitude: -122.0876067),
                .init(latitude: 47.5902748, longitude: -122.0873809),
                .init(latitude: 47.5862840, longitude: -122.0843575),
                .init(latitude: 47.5857161, longitude: -122.0841409),
                .init(latitude: 47.5842872, longitude: -122.0839619),
                .init(latitude: 47.5826007, longitude: -122.0827374),
                .init(latitude: 47.5821785, longitude: -122.0820194),
                .init(latitude: 47.5817006, longitude: -122.0807999),
                .init(latitude: 47.5811997, longitude: -122.0781489),
                .init(latitude: 47.5808833, longitude: -122.0772617),
                .init(latitude: 47.5803356, longitude: -122.0762756),
                .init(latitude: 47.5793651, longitude: -122.0753229),
                .init(latitude: 47.5759777, longitude: -122.0734688),
                .init(latitude: 47.5751270, longitude: -122.0724236)
            ],
            referenceCoordinate: .init(latitude: 47.6217995, longitude: -122.0694818),
            detectionToleranceMeters: 12,
            speedLimitMPH: 15,
            detail: "Class 1 and 2 e-bikes are allowed; Class 3 is prohibited. The trail speed limit is 15 mph. Check King County notices for temporary closures.",
            geometrySource: "WSDOT Active Transportation Data — East Lake Sammamish Trail"
        ),
        RideZone(
            name: "228th Avenue East-Side Shared Path",
            facility: .pavedSharedUsePath,
            level: .yellow,
            coordinates: [
                .init(latitude: 47.5861600, longitude: -122.0353566),
                .init(latitude: 47.5881023, longitude: -122.0352595),
                .init(latitude: 47.5881813, longitude: -122.0352006),
                .init(latitude: 47.5885186, longitude: -122.0353163),
                .init(latitude: 47.5916289, longitude: -122.0352714),
                .init(latitude: 47.5918726, longitude: -122.0351740),
                .init(latitude: 47.5921225, longitude: -122.0352827),
                .init(latitude: 47.5953327, longitude: -122.0352584),
                .init(latitude: 47.5955418, longitude: -122.0351587),
                .init(latitude: 47.5958284, longitude: -122.0352699),
                .init(latitude: 47.5976000, longitude: -122.0352682),
                .init(latitude: 47.5976628, longitude: -122.0353132),
                .init(latitude: 47.5981367, longitude: -122.0353172),
                .init(latitude: 47.5988930, longitude: -122.0352972),
                .init(latitude: 47.5990482, longitude: -122.0351744),
                .init(latitude: 47.5993175, longitude: -122.0351449),
                .init(latitude: 47.5994024, longitude: -122.0352602),
                .init(latitude: 47.5995321, longitude: -122.0353067),
                .init(latitude: 47.6013948, longitude: -122.0353376),
                .init(latitude: 47.6015079, longitude: -122.0352931),
                .init(latitude: 47.6016440, longitude: -122.0351316),
                .init(latitude: 47.6018989, longitude: -122.0351980),
                .init(latitude: 47.6019916, longitude: -122.0353114),
                .init(latitude: 47.6021173, longitude: -122.0353561),
                .init(latitude: 47.6046437, longitude: -122.0353186),
                .init(latitude: 47.6055917, longitude: -122.0352124),
                .init(latitude: 47.6058474, longitude: -122.0353037),
                .init(latitude: 47.6077280, longitude: -122.0353162),
                .init(latitude: 47.6080682, longitude: -122.0353057),
                .init(latitude: 47.6081097, longitude: -122.0352591),
                .init(latitude: 47.6091038, longitude: -122.0353261),
                .init(latitude: 47.6093053, longitude: -122.0352192),
                .init(latitude: 47.6095441, longitude: -122.0353179),
                .init(latitude: 47.6120819, longitude: -122.0353188),
                .init(latitude: 47.6126564, longitude: -122.0352536),
                .init(latitude: 47.6127593, longitude: -122.0353172),
                .init(latitude: 47.6128278, longitude: -122.0352553),
                .init(latitude: 47.6130499, longitude: -122.0352048),
                .init(latitude: 47.6133401, longitude: -122.0352987),
                .init(latitude: 47.6161317, longitude: -122.0353309),
                .init(latitude: 47.6164940, longitude: -122.0352916)
            ],
            referenceCoordinate: .init(latitude: 47.6055917, longitude: -122.0352124),
            detectionToleranceMeters: 12,
            speedLimitMPH: 15,
            detail: "The paved path on the east side of 228th Avenue between SE 24th Street and NE 8th Street allows Class 1 and 2 e-bikes. Class 3 is prohibited.",
            geometrySource: "City of Sammamish ADA sidewalk GIS — mapped east-side segments"
        )
    ]

    /// Public, open streets only. The source classification indicates the road's
    /// network role, not a measured bicycle safety score or a bike-lane inventory.
    static let roadways: [RideZone] = (SafetyMapData.localRoads + SafetyMapData.cautionRoads).compactMap { road in
        guard road.coordinates.count > 1 else { return nil }
        let classification = road.context.lowercased()
        let level: ZoneLevel
        if classification.contains("principal") {
            level = .red
        } else if classification.contains("arterial") || classification.contains("collector") {
            level = .orange
        } else {
            level = .green
        }

        return RideZone(
            name: road.name,
            facility: .roadway,
            level: level,
            coordinates: road.coordinates,
            referenceCoordinate: road.coordinates[road.coordinates.count / 2],
            detectionToleranceMeters: 18,
            speedLimitMPH: nil,
            detail: "\(road.context) in the City street inventory. Classes 1, 2, and 3 may use the roadway, subject to signs and traffic laws. Road classification guides the caution overlay; it does not establish traffic speed, a protected bike lane, or current conditions. Follow posted speed limits.",
            geometrySource: road.geometrySource
        )
    }

    static let all = sharedPaths + roadways

    static func nearestZone(to coordinate: CLLocationCoordinate2D?, among zones: [RideZone] = all) -> RideZone? {
        guard let coordinate else { return nil }
        let candidates = zones
            .map { zone in (zone: zone, distance: zone.distance(to: coordinate)) }
            .sorted { $0.distance < $1.distance }
        guard let nearest = candidates.first,
              nearest.distance <= nearest.zone.detectionToleranceMeters else { return nil }

        // A GPS point between a roadway and its parallel path cannot establish
        // which access rules apply. Returning nil avoids a false prohibition.
        if candidates.contains(where: {
            $0.zone.facility != nearest.zone.facility && $0.distance - nearest.distance < 8
        }) {
            return nil
        }

        return nearest.zone
    }
}
