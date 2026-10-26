import Foundation

enum ReportCategory: String, CaseIterable, Identifiable, Codable {
    case nearMiss = "Near-miss"
    case infrastructureGap = "Infrastructure gap"
    case obstruction = "Obstruction"
    case speedConcern = "Speed concern"
    case illegalRiding = "Illegal riding"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .nearMiss: "car.side.fill"
        case .infrastructureGap: "road.lanes"
        case .obstruction: "exclamationmark.triangle.fill"
        case .speedConcern: "bolt.fill"
        case .illegalRiding: "scooter"
        }
    }
}

struct SafetyReport: Identifiable, Codable, Equatable {
    let id: UUID
    let category: ReportCategory
    let notes: String
    let latitude: Double?
    let longitude: Double?
    let createdAt: Date

    // Local cache / pre-upload photo. Cloud reports normally leave this nil and
    // fetch their image lazily from the reportPhotos collection.
    let photoData: Data?

    // Optional fields keep previously cached reports backwards compatible.
    let photoAvailable: Bool?
    let ownerUID: String?
    let deviceClassRawValue: String?

    var hasPhoto: Bool {
        photoData != nil || photoAvailable == true
    }

    var isCloudReport: Bool {
        ownerUID != nil
    }

    init(
        id: UUID = UUID(),
        category: ReportCategory,
        notes: String,
        latitude: Double?,
        longitude: Double?,
        createdAt: Date = Date(),
        photoData: Data?,
        photoAvailable: Bool? = nil,
        ownerUID: String? = nil,
        deviceClassRawValue: String? = nil
    ) {
        self.id = id
        self.category = category
        self.notes = notes
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
        self.photoData = photoData
        self.photoAvailable = photoAvailable
        self.ownerUID = ownerUID
        self.deviceClassRawValue = deviceClassRawValue
    }
}
