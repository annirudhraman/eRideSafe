import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore


@MainActor
final class FirebaseBackend: ObservableObject {

    // MARK: - Sync State

    enum SyncState: Equatable {

        case notConfigured
        case connecting
        case synced
        case offline(String)

        var title: String {

            switch self {

            case .notConfigured:
                return "Firebase not configured"

            case .connecting:
                return "Connecting…"

            case .synced:
                return "Community sync active"

            case .offline:
                return "Cloud sync unavailable"
            }
        }

        var systemImage: String {

            switch self {

            case .notConfigured:
                return "icloud.slash"

            case .connecting:
                return "arrow.triangle.2.circlepath.icloud"

            case .synced:
                return "checkmark.icloud.fill"

            case .offline:
                return "exclamationmark.icloud.fill"
            }
        }
    }


    // MARK: - Published Properties

    @Published private(set) var syncState: SyncState = .connecting

    @Published private(set) var currentUserID: String?

    @Published private(set) var lastSyncDate: Date?


    // MARK: - Firebase

    var isFirebaseConfigured: Bool {
        FirebaseApp.app() != nil
    }


    private var database: Firestore? {

        guard FirebaseApp.app() != nil else {
            return nil
        }

        return Firestore.firestore()
    }


    private var reportListener: ListenerRegistration?

    private var hasStarted = false


    // MARK: - Initialization

    init() {

        if Bundle.main.url(
            forResource: "GoogleService-Info",
            withExtension: "plist"
        ) == nil {

            syncState = .notConfigured

        } else {

            syncState = .connecting

        }
    }


    // MARK: - Start Backend

    func start(appState: AppState) async {

        guard !hasStarted else {
            return
        }

        hasStarted = true


        guard FirebaseApp.app() != nil else {

            syncState = .notConfigured

            print("❌ Firebase has not been initialized.")

            return
        }


        syncState = .connecting


        do {

            // 1. Authenticate rider
            let uid = try await ensureAnonymousUser()

            currentUserID = uid


            // 2. Create/update user document
            try await ensureUserDocument(uid: uid)


            // 3. Move any old locally stored reports
            //    into Firestore.
            try await migrateLocalReportsIfNeeded(
                appState: appState,
                uid: uid
            )


            // 4. Start real-time community report listener
            startReportListener(
                appState: appState
            )


            // 5. Upload rider's app profile
            try await updateUserProfile(
                from: appState
            )


            syncState = .synced

            lastSyncDate = Date()

            print("✅ Firebase backend connected")
            print("Firebase UID:", uid)

        } catch {

            syncState = .offline(
                error.localizedDescription
            )

            print(
                "❌ Firebase startup error:",
                error.localizedDescription
            )
        }
    }


    // MARK: - Retry

    func retry(appState: AppState) async {

        reportListener?.remove()

        reportListener = nil

        hasStarted = false

        await start(
            appState: appState
        )
    }


    // MARK: - User Profile

    func updateUserProfile(
        from appState: AppState
    ) async throws {

        guard
            let database,
            let uid = currentUserID
        else {
            return
        }


        var data: [String: Any] = [

            "uid": uid,

            "deviceClass":
                appState.selectedDeviceClass.rawValue,

            "hasCompletedBikeSetup":
                appState.hasCompletedBikeSetup,

            "completedLessonIDs":
                Array(
                    appState.completedLessonIDs
                ).sorted(),

            "appPlatform":
                "iOS",

            "lastUpdatedAt":
                FieldValue.serverTimestamp()
        ]


        if let savedAt =
            appState.deviceClassSavedAt {

            data["deviceClassSavedAt"] =
                savedAt
        }


        if let certificateDate =
            appState.certificateDate {

            data["certificateDate"] =
                certificateDate

        } else {

            data["certificateDate"] =
                NSNull()
        }


        let document =
            database
                .collection("users")
                .document(uid)


        try await setData(
            data,
            document: document,
            merge: true
        )


        lastSyncDate = Date()
    }


    // MARK: - Submit Safety Report

    func submitReport(
        _ report: SafetyReport,
        deviceClass: DeviceClass
    ) async throws -> SafetyReport {

        guard
            let database,
            let uid = currentUserID
        else {

            throw BackendError.notConnected
        }


        let reportID =
            report.id.uuidString


        // Keep images comfortably below Firestore's
        // document size ceiling.
        let photoForUpload =
            report.photoData.flatMap { data in

                data.count <= 700_000
                    ? data
                    : nil
            }


        var photoUploaded = false


        // MARK: Upload photo

        if let photoData =
            photoForUpload {

            let photoDocument =
                database
                    .collection("reportPhotos")
                    .document(reportID)


            let photoPayload:
                [String: Any] = [

                    "userId":
                        uid,

                    "bytes":
                        photoData,

                    "contentType":
                        "image/jpeg",

                    "createdAt":
                        report.createdAt
                ]


            try await setData(
                photoPayload,
                document: photoDocument,
                merge: false
            )


            photoUploaded = true
        }


        // MARK: Report metadata

        var payload:
            [String: Any] = [

                "category":
                    report.category.rawValue,

                "notes":
                    report.notes,

                "createdAt":
                    report.createdAt,

                "serverCreatedAt":
                    FieldValue.serverTimestamp(),

                "userId":
                    uid,

                "deviceClass":
                    deviceClass.rawValue,

                "hasPhoto":
                    photoUploaded,

                "appPlatform":
                    "iOS"
            ]


        if let latitude =
            report.latitude {

            payload["latitude"] =
                latitude

        } else {

            payload["latitude"] =
                NSNull()
        }


        if let longitude =
            report.longitude {

            payload["longitude"] =
                longitude

        } else {

            payload["longitude"] =
                NSNull()
        }


        let reportDocument =
            database
                .collection("reports")
                .document(reportID)


        do {

            try await setData(
                payload,
                document: reportDocument,
                merge: false
            )

        } catch {

            // Remove orphaned photo if report upload fails.
            if photoUploaded {

                let photoDocument =
                    database
                        .collection("reportPhotos")
                        .document(reportID)

                try? await deleteDocument(
                    photoDocument
                )
            }

            throw error
        }


        lastSyncDate = Date()

        syncState = .synced


        return SafetyReport(

            id:
                report.id,

            category:
                report.category,

            notes:
                report.notes,

            latitude:
                report.latitude,

            longitude:
                report.longitude,

            createdAt:
                report.createdAt,

            photoData:
                photoUploaded
                    ? photoForUpload
                    : nil,

            photoAvailable:
                photoUploaded,

            ownerUID:
                uid,

            deviceClassRawValue:
                deviceClass.rawValue
        )
    }


    // MARK: - Report Photos

    func fetchPhotoData(
        for report: SafetyReport
    ) async throws -> Data? {

        guard
            report.hasPhoto,
            let database
        else {

            return report.photoData
        }


        // Already cached.
        if let photoData =
            report.photoData {

            return photoData
        }


        let document =
            database
                .collection("reportPhotos")
                .document(
                    report.id.uuidString
                )


        let snapshot =
            try await getDocument(
                document
            )


        return snapshot.data()?["bytes"]
            as? Data
    }


    // MARK: - Delete Report

    func deleteReport(
        _ report: SafetyReport
    ) async throws {

        guard
            let database,
            let uid = currentUserID
        else {

            throw BackendError.notConnected
        }


        guard report.ownerUID == uid else {

            throw BackendError.notOwner
        }


        let reportDocument =
            database
                .collection("reports")
                .document(
                    report.id.uuidString
                )


        try await deleteDocument(
            reportDocument
        )


        if report.hasPhoto {

            let photoDocument =
                database
                    .collection("reportPhotos")
                    .document(
                        report.id.uuidString
                    )


            try? await deleteDocument(
                photoDocument
            )
        }


        lastSyncDate = Date()
    }


    // MARK: - Ownership

    func isOwnedByCurrentUser(
        _ report: SafetyReport
    ) -> Bool {

        guard
            let uid = currentUserID
        else {
            return false
        }


        return report.ownerUID == uid
    }


    // MARK: - Authentication

    private func ensureAnonymousUser()
        async throws -> String {

        // Firebase persists the authenticated
        // anonymous account between launches.
        if let existingUser =
            Auth.auth().currentUser {

            return existingUser.uid
        }


        return try await
            withCheckedThrowingContinuation {
                continuation in

                Auth.auth()
                    .signInAnonymously {
                        result,
                        error in

                        if let error {

                            continuation.resume(
                                throwing: error
                            )

                            return
                        }


                        guard
                            let user =
                                result?.user
                        else {

                            continuation.resume(
                                throwing:
                                    BackendError
                                        .authenticationFailed
                            )

                            return
                        }


                        continuation.resume(
                            returning:
                                user.uid
                        )
                    }
            }
    }


    // MARK: - User Firestore Document

    private func ensureUserDocument(
        uid: String
    ) async throws {

        guard let database else {
            return
        }


        let document =
            database
                .collection("users")
                .document(uid)


        let snapshot =
            try await getDocument(
                document
            )


        if snapshot.exists {

            try await setData(
                [

                    "lastSeenAt":
                        FieldValue
                            .serverTimestamp(),

                    "appPlatform":
                        "iOS"

                ],

                document:
                    document,

                merge:
                    true
            )

        } else {

            try await setData(
                [

                    "uid":
                        uid,

                    "createdAt":
                        FieldValue
                            .serverTimestamp(),

                    "lastSeenAt":
                        FieldValue
                            .serverTimestamp(),

                    "appPlatform":
                        "iOS",

                    "accountType":
                        "anonymous"

                ],

                document:
                    document,

                merge:
                    false
            )
        }
    }


    // MARK: - Local Report Migration

    private func migrateLocalReportsIfNeeded(
        appState: AppState,
        uid: String
    ) async throws {

        let localReports =
            appState.reports.filter {
                $0.ownerUID == nil
            }


        guard
            !localReports.isEmpty
        else {
            return
        }


        for report in localReports {

            let uploaded =
                try await submitReport(
                    report,
                    deviceClass:
                        appState
                            .selectedDeviceClass
                )


            appState.upsertReport(
                uploaded
            )
        }
    }


    // MARK: - Real-Time Firestore Listener

    private func startReportListener(
        appState: AppState
    ) {

        guard let database else {
            return
        }


        reportListener?.remove()


        reportListener =
            database
                .collection("reports")
                .order(
                    by: "createdAt",
                    descending: true
                )
                .limit(to: 250)
                .addSnapshotListener {
                    [weak self, weak appState]
                    snapshot,
                    error in

                    Task { @MainActor in

                        guard
                            let self,
                            let appState
                        else {
                            return
                        }


                        if let error {

                            self.syncState =
                                .offline(
                                    error
                                        .localizedDescription
                                )

                            print(
                                "Firestore listener error:",
                                error.localizedDescription
                            )

                            return
                        }


                        guard
                            let documents =
                                snapshot?.documents
                        else {
                            return
                        }


                        let reports =
                            documents.compactMap {
                                Self.report(
                                    from: $0
                                )
                            }


                        appState
                            .replaceReportsFromCloud(
                                reports
                            )


                        self.syncState =
                            .synced


                        self.lastSyncDate =
                            Date()
                    }
                }
    }


    // MARK: - Firestore → SafetyReport

    private static func report(
        from document:
            QueryDocumentSnapshot
    ) -> SafetyReport? {

        let data =
            document.data()


        guard

            let id =
                UUID(
                    uuidString:
                        document.documentID
                ),

            let categoryRaw =
                data["category"]
                    as? String,

            let category =
                ReportCategory(
                    rawValue:
                        categoryRaw
                ),

            let notes =
                data["notes"]
                    as? String

        else {

            return nil
        }


        let createdAt: Date


        if let timestamp =
            data["createdAt"]
                as? Timestamp {

            createdAt =
                timestamp.dateValue()

        } else if let date =
            data["createdAt"]
                as? Date {

            createdAt =
                date

        } else {

            createdAt =
                Date()
        }


        return SafetyReport(

            id:
                id,

            category:
                category,

            notes:
                notes,

            latitude:
                optionalDouble(
                    data["latitude"]
                ),

            longitude:
                optionalDouble(
                    data["longitude"]
                ),

            createdAt:
                createdAt,

            photoData:
                nil,

            photoAvailable:
                data["hasPhoto"]
                    as? Bool
                    ?? false,

            ownerUID:
                data["userId"]
                    as? String,

            deviceClassRawValue:
                data["deviceClass"]
                    as? String
        )
    }


    private static func optionalDouble(
        _ value: Any?
    ) -> Double? {

        guard
            let value,
            !(value is NSNull)
        else {

            return nil
        }


        if let double =
            value as? Double {

            return double
        }


        if let number =
            value as? NSNumber {

            return number
                .doubleValue
        }


        return nil
    }


    // MARK: - Firebase Completion Handler Bridges

    private func getDocument(
        _ document: DocumentReference
    ) async throws -> DocumentSnapshot {

        try await
            withCheckedThrowingContinuation {
                continuation in

                document
                    .getDocument {
                        snapshot,
                        error in

                        if let error {

                            continuation.resume(
                                throwing: error
                            )

                            return
                        }


                        guard
                            let snapshot
                        else {

                            continuation.resume(
                                throwing:
                                    BackendError
                                        .missingSnapshot
                            )

                            return
                        }


                        continuation.resume(
                            returning:
                                snapshot
                        )
                    }
            }
    }


    private func setData(
        _ data: [String: Any],
        document: DocumentReference,
        merge: Bool
    ) async throws {

        try await
            withCheckedThrowingContinuation {
                (continuation:
                    CheckedContinuation<
                        Void,
                        Error
                    >)
                in

                document.setData(
                    data,
                    merge: merge
                ) {
                    error in

                    if let error {

                        continuation.resume(
                            throwing: error
                        )

                    } else {

                        continuation.resume(
                            returning: ()
                        )
                    }
                }
            }
    }


    private func deleteDocument(
        _ document:
            DocumentReference
    ) async throws {

        try await
            withCheckedThrowingContinuation {
                (continuation:
                    CheckedContinuation<
                        Void,
                        Error
                    >)
                in

                document.delete {
                    error in

                    if let error {

                        continuation.resume(
                            throwing: error
                        )

                    } else {

                        continuation.resume(
                            returning: ()
                        )
                    }
                }
            }
    }
}


// MARK: - Backend Errors

enum BackendError:
    LocalizedError {

    case notConnected

    case authenticationFailed

    case missingSnapshot

    case notOwner


    var errorDescription:
        String? {

        switch self {

        case .notConnected:

            return """
            Firebase has not finished connecting yet.
            """


        case .authenticationFailed:

            return """
            Firebase could not create an anonymous user.
            """


        case .missingSnapshot:

            return """
            Firebase returned an empty response.
            """


        case .notOwner:

            return """
            Only the rider who submitted this report can delete it.
            """
        }
    }
}
