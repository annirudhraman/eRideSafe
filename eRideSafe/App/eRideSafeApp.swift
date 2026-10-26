import SwiftUI
import FirebaseCore

final class FirebaseAppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {

        // Make sure GoogleService-Info.plist is actually included
        // before attempting to configure Firebase.
        if Bundle.main.url(
            forResource: "GoogleService-Info",
            withExtension: "plist"
        ) != nil {

            FirebaseApp.configure()

            print("✅ Firebase configured successfully")

        } else {

            print("""
            ❌ GoogleService-Info.plist was not found.
            Add it to the eRideSafe Xcode target.
            """)

        }

        return true
    }
}


@main
@MainActor
struct eRideSafeApp: App {

    // Firebase requires an application delegate for SwiftUI.
    @UIApplicationDelegateAdaptor(FirebaseAppDelegate.self)
    private var firebaseDelegate

    @StateObject private var appState = AppState()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var firebaseBackend = FirebaseBackend()

    var body: some Scene {

        WindowGroup {

            Group {

                if appState.hasCompletedBikeSetup {

                    RootTabView()
                        .transition(
                            .opacity.combined(
                                with: .scale(scale: 0.98)
                            )
                        )

                } else {

                    OnboardingClassifierView()
                        .transition(.opacity)

                }
            }
            .environmentObject(appState)
            .environmentObject(locationManager)
            .environmentObject(firebaseBackend)

            .tint(Color.erideGreen)

            .animation(
                .easeInOut(duration: 0.35),
                value: appState.hasCompletedBikeSetup
            )

            // Start Firebase Authentication + Firestore
            // after the app has launched.
            .task {

                await firebaseBackend.start(
                    appState: appState
                )

            }

            // Keep the Firebase user profile synced
            // whenever important local values change.

            .onChange(of: appState.hasCompletedBikeSetup) { _, _ in
                syncProfile()
            }

            .onChange(of: appState.selectedDeviceClass) { _, _ in
                syncProfile()
            }

            .onChange(of: appState.deviceClassSavedAt) { _, _ in
                syncProfile()
            }

            .onChange(of: appState.completedLessonIDs) { _, _ in
                syncProfile()
            }

            .onChange(of: appState.certificateDate) { _, _ in
                syncProfile()
            }
        }
    }


    private func syncProfile() {

        guard firebaseBackend.isFirebaseConfigured else {
            return
        }

        Task {

            do {

                try await firebaseBackend.updateUserProfile(
                    from: appState
                )

            } catch {

                print(
                    "Firebase profile sync failed:",
                    error.localizedDescription
                )

            }
        }
    }
}
