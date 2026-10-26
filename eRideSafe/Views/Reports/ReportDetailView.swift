import MapKit
import SwiftUI
import UIKit

struct ReportDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var firebaseBackend: FirebaseBackend

    let report: SafetyReport

    @State private var remotePhotoData: Data?
    @State private var isLoadingPhoto = false
    @State private var isDeleting = false
    @State private var errorMessage: String?
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    Label(report.category.rawValue, systemImage: report.category.systemImage)
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.orange)
                    Spacer()
                    if firebaseBackend.isOwnedByCurrentUser(report) {
                        Text("YOUR REPORT")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.erideGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.erideGreen.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                LabeledContent("Submitted", value: report.createdAt.formatted(date: .long, time: .shortened))

                if let deviceClassRawValue = report.deviceClassRawValue,
                   let deviceClass = DeviceClass(rawValue: deviceClassRawValue) {
                    LabeledContent("Rider device", value: deviceClass.title)
                }

                if !report.notes.isEmpty {
                    ERideCard {
                        Text(report.notes)
                    }
                }

                if let latitude = report.latitude, let longitude = report.longitude {
                    Map(initialPosition: .region(MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))) {
                        Marker("Report", coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                    }
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }

                photoSection
            }
            .padding()
        }
        .background(Color.erideBackground)
        .navigationTitle("Report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if firebaseBackend.isOwnedByCurrentUser(report) {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        if isDeleting {
                            ProgressView()
                        } else {
                            Image(systemName: "trash")
                        }
                    }
                    .disabled(isDeleting)
                }
            }
        }
        .task {
            await loadPhotoIfNeeded()
        }
        .alert("Delete this report?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task { await deleteReport() }
            }
        } message: {
            Text("It will be removed from the shared community map for everyone.")
        }
        .alert("Firebase error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }

    @ViewBuilder
    private var photoSection: some View {
        if let data = report.photoData ?? remotePhotoData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 18))
        } else if report.hasPhoto {
            HStack(spacing: 10) {
                if isLoadingPhoto {
                    ProgressView()
                } else {
                    Image(systemName: "photo")
                }
                Text(isLoadingPhoto ? "Loading report photo…" : "Photo unavailable")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
        }
    }

    @MainActor
    private func loadPhotoIfNeeded() async {
        guard report.photoData == nil, report.hasPhoto, !isLoadingPhoto else { return }
        isLoadingPhoto = true
        defer { isLoadingPhoto = false }

        do {
            remotePhotoData = try await firebaseBackend.fetchPhotoData(for: report)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func deleteReport() async {
        guard !isDeleting else { return }
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await firebaseBackend.deleteReport(report)
            appState.removeReport(id: report.id)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
