import MapKit
import SwiftUI

struct ReportsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var firebaseBackend: FirebaseBackend
    @State private var showNewReport = false
    @State private var displayMode: ReportDisplayMode = .list

    var body: some View {
        Group {
            if appState.reports.isEmpty {
                ContentUnavailableView {
                    Label("No safety reports yet", systemImage: "exclamationmark.bubble")
                } description: {
                    Text(emptyDescription)
                } actions: {
                    Button("Create report") { showNewReport = true }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.erideGreen)
                }
            } else {
                VStack(spacing: 0) {
                    syncBanner

                    Picker("Display", selection: $displayMode) {
                        ForEach(ReportDisplayMode.allCases) { mode in
                            Label(mode.title, systemImage: mode.systemImage).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.vertical, 10)

                    if displayMode == .list {
                        List {
                            Section {
                                Text("Community reports are shared across eRideSafe devices. Firestore keeps a local cache so recent reports remain visible when connectivity drops.")
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                            }

                            Section("Community reports") {
                                ForEach(appState.reports) { report in
                                    NavigationLink {
                                        ReportDetailView(report: report)
                                    } label: {
                                        ReportRow(
                                            report: report,
                                            isYours: firebaseBackend.isOwnedByCurrentUser(report)
                                        )
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    } else {
                        ReportHeatMap(reports: appState.reports)
                    }
                }
            }
        }
        .navigationTitle("Report & Protect")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !appState.reports.isEmpty {
                    ShareLink(item: exportText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                Button {
                    showNewReport = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewReport) {
            NewReportView()
        }
    }

    private var emptyDescription: String {
        if firebaseBackend.isFirebaseConfigured {
            return "Report near-misses, infrastructure gaps, obstructions, speed concerns, or illegal riding. Reports you submit will appear for the eRideSafe community."
        }
        return "Firebase is not configured yet. Reports can still be saved locally until cloud sync is connected."
    }

    private var syncBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: firebaseBackend.syncState.systemImage)
                .foregroundStyle(syncColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(firebaseBackend.syncState.title)
                    .font(.caption.weight(.bold))
                if let lastSyncDate = firebaseBackend.lastSyncDate {
                    Text("Updated \(lastSyncDate.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(Color.secondary)
                }
            }
            Spacer()

            if case .offline = firebaseBackend.syncState {
                Button("Retry") {
                    Task { await firebaseBackend.retry(appState: appState) }
                }
                .font(.caption.weight(.semibold))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 9)
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private var syncColor: Color {
        switch firebaseBackend.syncState {
        case .synced: Color.erideGreen
        case .connecting: Color.blue
        case .notConfigured, .offline: Color.orange
        }
    }

    private var exportText: String {
        let header = "Category,Date,Latitude,Longitude,Notes"
        let rows = appState.reports.map { report in
            let cleanNotes = report.notes.replacingOccurrences(of: "\"", with: "\"\"")
            return "\(report.category.rawValue),\(report.createdAt.ISO8601Format()),\(report.latitude.map { String($0) } ?? ""),\(report.longitude.map { String($0) } ?? ""),\"\(cleanNotes)\""
        }
        return ([header] + rows).joined(separator: "\n")
    }
}

private struct ReportRow: View {
    let report: SafetyReport
    let isYours: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: report.category.systemImage)
                .font(.title3)
                .foregroundStyle(Color.orange)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(report.category.rawValue)
                        .font(.headline)
                    if isYours {
                        Text("YOURS")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(Color.erideGreen)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.erideGreen.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                Text(report.notes.isEmpty ? "No notes" : report.notes)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(report.createdAt.formatted(date: .abbreviated, time: .shortened))
                    if report.hasPhoto {
                        Image(systemName: "photo.fill")
                    }
                    if report.latitude != nil {
                        Image(systemName: "location.fill")
                    }
                }
                .font(.caption2)
                .foregroundStyle(Color.secondary)
            }
        }
    }
}

private enum ReportDisplayMode: String, CaseIterable, Identifiable {
    case list
    case map

    var id: String { rawValue }
    var title: String { self == .list ? "List" : "Map" }
    var systemImage: String { self == .list ? "list.bullet" : "map" }
}

private struct ReportHeatMap: View {
    let reports: [SafetyReport]

    var body: some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 47.6215, longitude: -122.0630),
            span: MKCoordinateSpan(latitudeDelta: 0.10, longitudeDelta: 0.11)
        ))) {
            ForEach(Array(reports.prefix(250))) { report in
                if let latitude = report.latitude, let longitude = report.longitude {
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    MapCircle(center: coordinate, radius: 180)
                        .foregroundStyle(Color.red.opacity(0.12))
                    Annotation(report.category.rawValue, coordinate: coordinate) {
                        Image(systemName: report.category.systemImage)
                            .font(.caption)
                            .foregroundStyle(Color.white)
                            .padding(7)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            Text("Shared reports form a live community hazard-density view.")
                .font(.caption)
                .padding(10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .padding()
        }
    }
}
