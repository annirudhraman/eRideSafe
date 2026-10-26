import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            AppNavigationRoot {
                HomeView()
            }
            .tabItem { Label("Home", systemImage: "house.fill") }

            AppNavigationRoot {
                SafetyMapView()
            }
            .tabItem { Label("Map", systemImage: "map.fill") }

            AppNavigationRoot {
                SchoolView()
            }
            .tabItem { Label("School", systemImage: "graduationcap.fill") }

            AppNavigationRoot {
                ReportsView()
            }
            .tabItem { Label("Report", systemImage: "exclamationmark.bubble.fill") }

            AppNavigationRoot {
                RideModeView()
            }
            .tabItem { Label("Ride", systemImage: "speedometer") }
        }
        .tint(Color.erideGreen)
        .toolbarBackground(Color.erideSurface, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

private struct AppNavigationRoot<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            content
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .accessibilityLabel("Settings")
                        }
                    }
                }
        }
        .toolbarBackground(Color.erideNavy, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

private struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var firebaseBackend: FirebaseBackend
    @State private var showRestartConfirmation = false

    var body: some View {
        List {
            Section {
                ERideCard(tint: appState.selectedDeviceClass.color) {
                    HStack(spacing: 15) {
                        Image(systemName: appState.selectedDeviceClass.systemImage)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(appState.selectedDeviceClass.color)
                            .frame(width: 58, height: 58)
                            .background(appState.selectedDeviceClass.color.opacity(0.13))
                            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your saved ride")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.secondary)
                            Text(appState.selectedDeviceClass.title)
                                .font(.title2.bold())
                            Text(appState.selectedDeviceClass.summary)
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                                .lineLimit(3)
                        }
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section("Bike classification") {
                NavigationLink {
                    DeviceClassifierView()
                } label: {
                    Label("Retake device class quiz", systemImage: "checklist")
                }

                if let savedAt = appState.deviceClassSavedAt {
                    LabeledContent("Last saved") {
                        Text(savedAt, format: .dateTime.month(.abbreviated).day().year())
                    }
                }

                ForEach(appState.selectedDeviceClass.requirements, id: \.self) { requirement in
                    Label(requirement, systemImage: "checkmark.shield.fill")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
            }

            Section("Your app data") {
                LabeledContent(
                    "Lessons completed",
                    value: "\(CourseContent.completedLessonCount(in: appState.completedLessonIDs)) of \(CourseContent.lessons.count)"
                )
                LabeledContent("Certification", value: appState.certificateDate == nil ? "Not earned" : "Earned")
                LabeledContent("Safety reports", value: "\(appState.reports.count)")
            }

            Section("Cloud sync") {
                Label(firebaseBackend.syncState.title, systemImage: firebaseBackend.syncState.systemImage)
                    .foregroundStyle(firebaseBackend.isFirebaseConfigured ? Color.erideGreen : Color.orange)

                if let uid = firebaseBackend.currentUserID {
                    LabeledContent("Account", value: "Anonymous Firebase user")
                    LabeledContent("User ID", value: String(uid.prefix(8)) + "…")
                }

                if let lastSyncDate = firebaseBackend.lastSyncDate {
                    LabeledContent("Last sync") {
                        Text(lastSyncDate, format: .dateTime.hour().minute())
                    }
                }

                Text("Your bike class and course progress are stored in your private Firebase user profile. Safety reports are shared with authenticated eRideSafe users so the community map stays in sync across devices.")
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)

                if !firebaseBackend.isFirebaseConfigured {
                    Text("Add GoogleService-Info.plist to the app target to enable Firebase.")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.orange)
                }
            }

            Section("About eRideSafe") {
                Label("Sammamish ride legality map", systemImage: "map.fill")
                Label("eRide School and certification", systemImage: "graduationcap.fill")
                Label("Community hazard reporting", systemImage: "exclamationmark.bubble.fill")
                Label("Live Ride Mode safety companion", systemImage: "speedometer")

                Text("Always follow posted signs and official local guidance. Map information can change and is not a substitute for legal advice.")
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
            }

            Section {
                Button(role: .destructive) {
                    showRestartConfirmation = true
                } label: {
                    Label("Run first-time bike setup again", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.erideBackground)
        .navigationTitle("Settings")
        .alert("Restart bike setup?", isPresented: $showRestartConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Restart", role: .destructive) {
                appState.restartBikeSetup()
            }
        } message: {
            Text("The classification quiz will appear again. Your course progress and reports will stay saved.")
        }
    }
}
