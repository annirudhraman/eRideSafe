import Foundation

enum RideAlertMode: String, CaseIterable, Identifiable {
    case haptics
    case sound
    case hapticsAndSound

    var id: String { rawValue }

    var title: String {
        switch self {
        case .haptics: "Haptics"
        case .sound: "Sound"
        case .hapticsAndSound: "Both"
        }
    }

    var systemImage: String {
        switch self {
        case .haptics: "iphone.radiowaves.left.and.right"
        case .sound: "speaker.wave.2.fill"
        case .hapticsAndSound: "waveform.and.person.filled"
        }
    }

    var detail: String {
        switch self {
        case .haptics: "Vibration patterns only. No spoken alerts or alert sounds."
        case .sound: "Short alert tones only. No spoken alerts."
        case .hapticsAndSound: "Vibration patterns and short alert tones. No spoken alerts."
        }
    }

    var usesHaptics: Bool {
        self != .sound
    }

    var usesSound: Bool {
        self != .haptics
    }
}

enum RideAlertSound: String, CaseIterable, Identifiable {
    case chime
    case pulse
    case urgent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chime: "Chime"
        case .pulse: "Pulse"
        case .urgent: "Urgent"
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var hasCompletedBikeSetup: Bool {
        didSet { UserDefaults.standard.set(hasCompletedBikeSetup, forKey: Keys.hasCompletedBikeSetup) }
    }

    @Published var selectedDeviceClass: DeviceClass {
        didSet { UserDefaults.standard.set(selectedDeviceClass.rawValue, forKey: Keys.deviceClass) }
    }

    @Published var deviceClassSavedAt: Date? {
        didSet { UserDefaults.standard.set(deviceClassSavedAt, forKey: Keys.deviceClassSavedAt) }
    }

    @Published var completedLessonIDs: Set<Int> {
        didSet { UserDefaults.standard.set(Array(completedLessonIDs), forKey: Keys.completedLessons) }
    }

    @Published var certificateDate: Date? {
        didSet { UserDefaults.standard.set(certificateDate, forKey: Keys.certificateDate) }
    }

    @Published var rideAlertMode: RideAlertMode {
        didSet { UserDefaults.standard.set(rideAlertMode.rawValue, forKey: Keys.rideAlertMode) }
    }

    @Published var rideAlertSound: RideAlertSound {
        didSet { UserDefaults.standard.set(rideAlertSound.rawValue, forKey: Keys.rideAlertSound) }
    }

    // This remains a local cache so the app is useful offline. When Firebase is
    // configured, FirebaseBackend keeps this array synchronized with Firestore.
    @Published var reports: [SafetyReport] {
        didSet { saveReports() }
    }

    private enum Keys {
        static let hasCompletedBikeSetup = "hasCompletedBikeSetup"
        static let deviceClass = "selectedDeviceClass"
        static let deviceClassSavedAt = "deviceClassSavedAt"
        static let completedLessons = "completedLessonIDs"
        static let certificateDate = "certificateDate"
        static let rideAlertMode = "rideAlertMode"
        static let rideAlertSound = "rideAlertSound"
        static let reports = "safetyReports"
    }

    init() {
        hasCompletedBikeSetup = UserDefaults.standard.bool(forKey: Keys.hasCompletedBikeSetup)

        let savedClass = UserDefaults.standard.string(forKey: Keys.deviceClass)
        selectedDeviceClass = DeviceClass(rawValue: savedClass ?? "") ?? .class2
        deviceClassSavedAt = UserDefaults.standard.object(forKey: Keys.deviceClassSavedAt) as? Date

        let savedLessons = UserDefaults.standard.array(forKey: Keys.completedLessons) as? [Int] ?? []
        completedLessonIDs = Set(savedLessons)
        certificateDate = UserDefaults.standard.object(forKey: Keys.certificateDate) as? Date

        let savedAlertMode = UserDefaults.standard.string(forKey: Keys.rideAlertMode)
        rideAlertMode = RideAlertMode(rawValue: savedAlertMode ?? "") ?? .haptics

        let savedAlertSound = UserDefaults.standard.string(forKey: Keys.rideAlertSound)
        rideAlertSound = RideAlertSound(rawValue: savedAlertSound ?? "") ?? .chime

        if let data = UserDefaults.standard.data(forKey: Keys.reports),
           let decoded = try? JSONDecoder().decode([SafetyReport].self, from: data) {
            reports = decoded.sorted { $0.createdAt > $1.createdAt }
        } else {
            reports = []
        }
    }

    func saveDeviceClass(_ deviceClass: DeviceClass) {
        selectedDeviceClass = deviceClass
        deviceClassSavedAt = Date()
        hasCompletedBikeSetup = true
    }

    func restartBikeSetup() {
        hasCompletedBikeSetup = false
    }

    func markLessonComplete(_ id: Int) {
        completedLessonIDs.insert(id)
    }

    func addReport(_ report: SafetyReport) {
        upsertReport(report)
    }

    func upsertReport(_ report: SafetyReport) {
        if let index = reports.firstIndex(where: { $0.id == report.id }) {
            reports[index] = report
        } else {
            reports.append(report)
        }
        reports.sort { $0.createdAt > $1.createdAt }
    }

    func removeReport(id: UUID) {
        reports.removeAll { $0.id == id }
    }

    func replaceReportsFromCloud(_ cloudReports: [SafetyReport]) {
        // Keep any unsynced local-only reports until FirebaseBackend has a chance
        // to migrate them. Cloud documents win when IDs match.
        let cloudIDs = Set(cloudReports.map(\.id))
        let localOnly = reports.filter { $0.ownerUID == nil && !cloudIDs.contains($0.id) }
        reports = (cloudReports + localOnly).sorted { $0.createdAt > $1.createdAt }
    }

    private func saveReports() {
        guard let data = try? JSONEncoder().encode(reports) else { return }
        UserDefaults.standard.set(data, forKey: Keys.reports)
    }
}
