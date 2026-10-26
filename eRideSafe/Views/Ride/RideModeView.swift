import SwiftUI
import UIKit

struct RideModeView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var locationManager: LocationManager

    @State private var helmet = false
    @State private var frontLight = false
    @State private var rearLight = false
    @State private var brakes = false
    @State private var phoneSecured = false
    @State private var isRiding = false
    @State private var lastWarningState = false
    @State private var lastZoneName: String?
    @State private var topSpeedMPH: Double = 0
    @StateObject private var alertService = RideAlertService()
    @StateObject private var motionManager = RideMotionManager()

    private var checklistComplete: Bool {
        helmet && frontLight && rearLight && brakes && phoneSecured
    }

    private var currentZone: RideZone? {
        // Nearby roads and parallel paths can have different access rules.
        guard let accuracy = locationManager.horizontalAccuracy,
              accuracy >= 0, accuracy <= 12 else { return nil }
        return SammamishZones.nearestZone(to: locationManager.coordinate)
    }

    private var speedLimit: Double? {
        currentZone?.speedLimitMPH
    }

    private var speedState: SpeedState {
        guard locationManager.isSpeedAvailable else {
            return .acquiring
        }
        guard let speedLimit else {
            return .unmapped
        }
        if locationManager.speedMPH > speedLimit {
            return .over
        }
        if locationManager.speedMPH >= speedLimit * 0.85 {
            return .approaching
        }
        return .safe
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if isRiding {
                    activeRideView
                } else {
                    preRideView
                }
            }
            .padding()
        }
        .background(Color.erideBackground)
        .navigationTitle("Ride Mode")
        .onChange(of: locationManager.speedMPH) { _, _ in
            guard isRiding, locationManager.isSpeedAvailable else { return }
            topSpeedMPH = max(topSpeedMPH, locationManager.speedMPH)
            triggerWarningIfNeeded()
        }
        .onChange(of: motionManager.significantMotionCount) { oldValue, newValue in
            guard isRiding, newValue > oldValue else { return }
            playAlert(.suddenMotion)
        }
        .onChange(of: currentZone?.name) { _, newName in
            guard isRiding else { return }
            triggerWarningIfNeeded()
            guard newName != lastZoneName else { return }
            lastZoneName = newName
            guard newName != nil else { return }
            playAlert(.zoneChange)
        }
    }

    private var preRideView: some View {
        VStack(spacing: 18) {
            ERideCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pre-ride checklist")
                        .font(.title2.bold())
                    Text("Complete every item before activating live speed and zone alerts.")
                        .foregroundStyle(Color.secondary)
                }
            }

            ERideCard {
                VStack(spacing: 4) {
                    checklistToggle("Helmet on and fastened", systemImage: "figure.safety.jacket", value: $helmet)
                    checklistToggle("Front light working", systemImage: "flashlight.on.fill", value: $frontLight)
                    checklistToggle("Rear reflector or light", systemImage: "light.beacon.max.fill", value: $rearLight)
                    checklistToggle("Brakes tested", systemImage: "hand.raised.fill", value: $brakes)
                    checklistToggle("Phone secured, not hand-held", systemImage: "iphone.gen3", value: $phoneSecured)
                }
            }

            ERideCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Selected ride")
                            .font(.headline)
                        Text(appState.selectedDeviceClass.title)
                            .foregroundStyle(appState.selectedDeviceClass.color)
                    }
                    Spacer()
                    NavigationLink("Change") {
                        DeviceClassifierView()
                    }
                }
            }

            alertSettingsCard

            Button("Start Ride Mode") {
                locationManager.requestPermission()
                locationManager.startRideTracking()
                motionManager.start()
                topSpeedMPH = 0
                lastWarningState = false
                lastZoneName = currentZone?.name
                isRiding = true
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!checklistComplete || appState.selectedDeviceClass == .electricMotorcycle)

            if appState.selectedDeviceClass == .electricMotorcycle {
                Text("Ride Mode is disabled because the saved device is classified as an electric motorcycle. Use the classifier after correcting the device information.")
                    .font(.caption)
                    .foregroundStyle(Color.red)
            }
        }
    }

    private var activeRideView: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text(speedDisplay)
                    .font(.system(size: 92, weight: .bold, design: .rounded))
                    .foregroundStyle(speedState.color)
                    .contentTransition(.numericText())
                Text("MPH")
                    .font(.headline)
                    .foregroundStyle(Color.secondary)
                StatusPill(text: speedState.title, systemImage: speedState.systemImage, color: speedState.color)

                Text(gpsStatusText)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 26))

            ERideCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(currentZone?.name ?? "Road or path not confirmed")
                            .font(.headline)
                        Spacer()
                        if let speedLimit {
                            Text("Limit \(Int(speedLimit)) mph")
                                .font(.subheadline.bold())
                        } else {
                            Text("Follow signs")
                                .font(.subheadline.bold())
                        }
                    }
                    Text(zoneMessage)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
            }

            ERideCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Live ride sensors")
                        .font(.headline)

                    HStack {
                        Label("GPS speed", systemImage: "location.fill")
                        Spacer()
                        Text(locationManager.isSpeedAvailable ? "Active" : "Acquiring")
                            .font(.subheadline.bold())
                            .foregroundStyle(locationManager.isSpeedAvailable ? Color.green : Color.orange)
                    }

                    Divider()

                    HStack {
                        Label(motionManager.motionState.title, systemImage: motionManager.motionState.systemImage)
                            .foregroundStyle(motionStateColor)
                        Spacer()
                        Text(String(format: "%.2f g", motionManager.accelerationG))
                            .font(.subheadline.monospacedDigit().bold())
                    }

                    HStack {
                        Label("Top speed", systemImage: "gauge.with.dots.needle.67percent")
                        Spacer()
                        Text(String(format: "%.1f mph", topSpeedMPH))
                            .font(.subheadline.monospacedDigit().bold())
                    }

                    HStack {
                        Label("Ride alerts", systemImage: appState.rideAlertMode.systemImage)
                        Spacer()
                        Text(appState.rideAlertMode.title)
                            .font(.subheadline.bold())
                    }

                    Text(sensorExplanation)
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }

            if let shareURL = shareLocationURL {
                ShareLink(item: shareURL) {
                    Label("Share My Ride location", systemImage: "location.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Button("Waiting for location…") {}
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(true)
            }

            Button(role: .destructive) {
                isRiding = false
                locationManager.stopUpdating()
                motionManager.stop()
            } label: {
                Label("End Ride", systemImage: "stop.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Text("Keep the phone secured. Rely on your selected haptic or sound warnings and stop safely before interacting with the screen.")
                .font(.caption)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var zoneMessage: String {
        if let currentZone {
            let permission = currentZone.permission(for: appState.selectedDeviceClass).message
            if speedLimit == nil {
                return permission + " Follow the posted speed limit; this road's limit is not mapped."
            }
            return permission
        }
        return "GPS has not confirmed a mapped road or path. Follow posted access and speed signs. Speed-limit alerts resume when a mapped limit is available."
    }

    private var alertSettingsCard: some View {
        ERideCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Ride alerts", systemImage: appState.rideAlertMode.systemImage)
                    .font(.headline)

                Picker("Alert type", selection: $appState.rideAlertMode) {
                    ForEach(RideAlertMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if appState.rideAlertMode.usesSound {
                    Picker("Alert sound", selection: $appState.rideAlertSound) {
                        ForEach(RideAlertSound.allCases) { sound in
                            Text(sound.title).tag(sound)
                        }
                    }
                }

                Text(appState.rideAlertMode.detail)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)

                Button {
                    playAlert(.preview)
                } label: {
                    Label("Preview alert", systemImage: "play.fill")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var speedDisplay: String {
        guard locationManager.isSpeedAvailable else { return "—" }
        return String(format: locationManager.speedMPH < 10 ? "%.1f" : "%.0f", locationManager.speedMPH)
    }

    private var gpsStatusText: String {
        if let error = locationManager.lastError {
            return error
        }
        guard locationManager.isSpeedAvailable else {
            return "Acquiring an accurate outdoor GPS speed…"
        }
        if let accuracy = locationManager.speedAccuracyMPH {
            return String(format: "GPS estimate · accuracy ±%.1f mph", accuracy)
        }
        return "Live GPS speed"
    }

    private var motionStateColor: Color {
        switch motionManager.motionState {
        case .unavailable: Color.secondary
        case .steady, .normal: Color.green
        case .rough: Color.orange
        case .sudden: Color.red
        }
    }

    private var sensorExplanation: String {
        if let error = motionManager.lastError {
            return error + " GPS speed tracking can still work outdoors."
        }
        return "Speed is measured by GPS. The accelerometer measures device movement and flags rough or sudden motion; it cannot determine constant vehicle speed by itself."
    }

    private var shareLocationURL: URL? {
        guard let coordinate = locationManager.coordinate else { return nil }
        return URL(string: "https://maps.apple.com/?ll=\(coordinate.latitude),\(coordinate.longitude)")
    }

    private func checklistToggle(_ title: String, systemImage: String, value: Binding<Bool>) -> some View {
        Toggle(isOn: value) {
            Label(title, systemImage: systemImage)
        }
        .tint(Color.erideGreen)
        .padding(.vertical, 6)
    }

    private func triggerWarningIfNeeded() {
        let isOver = speedState == .over
        if isOver && !lastWarningState {
            playAlert(.speedLimit)
            if UIAccessibility.isVoiceOverRunning {
                UIAccessibility.post(notification: .announcement, argument: "Slow down. You are over the mapped speed limit.")
            }
        }
        lastWarningState = isOver
    }

    private func playAlert(_ event: RideAlertEvent) {
        alertService.play(event, mode: appState.rideAlertMode, sound: appState.rideAlertSound)
    }
}

private enum SpeedState: Equatable {
    case acquiring
    case unmapped
    case safe
    case approaching
    case over

    var title: String {
        switch self {
        case .acquiring: "Acquiring GPS"
        case .unmapped: "Check posted limit"
        case .safe: "Under limit"
        case .approaching: "Approaching limit"
        case .over: "Over limit"
        }
    }

    var systemImage: String {
        switch self {
        case .acquiring: "location.circle.fill"
        case .unmapped: "signpost.right.and.left.fill"
        case .safe: "checkmark.circle.fill"
        case .approaching: "exclamationmark.triangle.fill"
        case .over: "xmark.octagon.fill"
        }
    }

    var color: Color {
        switch self {
        case .acquiring, .unmapped: Color.secondary
        case .safe: Color.green
        case .approaching: Color.yellow
        case .over: Color.red
        }
    }
}
