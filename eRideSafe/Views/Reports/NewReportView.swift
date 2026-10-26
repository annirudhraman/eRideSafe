import PhotosUI
import SwiftUI
import UIKit

struct NewReportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var firebaseBackend: FirebaseBackend

    @State private var category: ReportCategory = .nearMiss
    @State private var notes = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showLocalFallbackNotice = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Report type", selection: $category) {
                        ForEach(ReportCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.systemImage)
                                .tag(category)
                        }
                    }
                }

                Section("Details") {
                    TextField("Describe what happened or what needs improvement", text: $notes, axis: .vertical)
                        .lineLimit(4...8)

                    HStack {
                        Label(locationText, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                        Spacer()
                        Button("Refresh") { locationManager.requestSingleLocation() }
                    }

                    Text("Your report location is shared on the community safety map so other riders can see the unsafe area.")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }

                Section("Optional photo") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(photoData == nil ? "Choose photo" : "Change photo", systemImage: "photo")
                    }

                    if let photoData, let image = UIImage(data: photoData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                        Text("Photos are compressed before upload so community reports stay lightweight.")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                }

                Section {
                    HStack(spacing: 8) {
                        Image(systemName: firebaseBackend.syncState.systemImage)
                        Text(firebaseBackend.syncState.title)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(firebaseBackend.isFirebaseConfigured ? Color.erideGreen : Color.orange)

                    Text("Do not submit a report while moving. Stop in a safe place first.")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }
            .navigationTitle("New Safety Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await saveReport() }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Submit")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving || locationManager.coordinate == nil)
                }
            }
            .task(id: selectedPhoto) {
                guard let selectedPhoto else { return }
                if let originalData = try? await selectedPhoto.loadTransferable(type: Data.self),
                   let originalImage = UIImage(data: originalData) {
                    photoData = compressedPhotoData(from: originalImage)
                }
            }
            .onAppear {
                locationManager.requestPermission()
                locationManager.requestSingleLocation()
            }
            .alert("Could not submit report", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "Unknown error")
            }
            .alert("Saved on this device", isPresented: $showLocalFallbackNotice) {
                Button("OK") { dismiss() }
            } message: {
                Text("Firebase is not configured yet, so this report was saved locally. Add GoogleService-Info.plist and enable Firebase to share reports with the community.")
            }
        }
    }

    private var locationText: String {
        guard let coordinate = locationManager.coordinate else { return "Waiting for location" }
        return String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude)
    }

    private func compressedPhotoData(from image: UIImage) -> Data? {
        // Firestore byte values must remain below the document-size limit. We keep
        // image documents comfortably below that ceiling so they remain reliable.
        let maximumBytes = 700_000
        var workingImage = image
        var maximumDimension: CGFloat = 1_200

        for _ in 0..<4 {
            let largestSide = max(workingImage.size.width, workingImage.size.height)
            let scale = min(1, maximumDimension / largestSide)
            let newSize = CGSize(width: workingImage.size.width * scale, height: workingImage.size.height * scale)

            if scale < 1 {
                let sourceImage = workingImage
                let renderer = UIGraphicsImageRenderer(size: newSize)
                workingImage = renderer.image { _ in
                    sourceImage.draw(in: CGRect(origin: .zero, size: newSize))
                }
            }

            var quality: CGFloat = 0.76
            while quality >= 0.36 {
                if let data = workingImage.jpegData(compressionQuality: quality), data.count <= maximumBytes {
                    return data
                }
                quality -= 0.08
            }

            maximumDimension *= 0.78
        }

        return workingImage.jpegData(compressionQuality: 0.32)
    }

    @MainActor
    private func saveReport() async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        let coordinate = locationManager.coordinate
        let report = SafetyReport(
            category: category,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            latitude: coordinate?.latitude,
            longitude: coordinate?.longitude,
            photoData: photoData
        )

        guard firebaseBackend.isFirebaseConfigured else {
            appState.addReport(report)
            showLocalFallbackNotice = true
            return
        }

        do {
            let uploaded = try await firebaseBackend.submitReport(report, deviceClass: appState.selectedDeviceClass)
            appState.upsertReport(uploaded)
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
    }
}
