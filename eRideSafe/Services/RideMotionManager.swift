import CoreMotion
import Foundation

enum RideMotionState: Equatable {
    case unavailable
    case steady
    case normal
    case rough
    case sudden

    var title: String {
        switch self {
        case .unavailable: "Motion unavailable"
        case .steady: "Steady motion"
        case .normal: "Normal motion"
        case .rough: "Rough movement"
        case .sudden: "Sudden movement"
        }
    }

    var systemImage: String {
        switch self {
        case .unavailable: "sensor.tag.radiowaves.forward.slash"
        case .steady: "waveform.path"
        case .normal: "waveform.path.ecg"
        case .rough: "exclamationmark.triangle.fill"
        case .sudden: "exclamationmark.octagon.fill"
        }
    }
}

@MainActor
final class RideMotionManager: ObservableObject {
    @Published private(set) var isAvailable: Bool
    @Published private(set) var isActive = false
    @Published private(set) var accelerationG: Double = 0
    @Published private(set) var peakAccelerationG: Double = 0
    @Published private(set) var motionState: RideMotionState = .unavailable
    @Published private(set) var significantMotionCount = 0
    @Published private(set) var lastError: String?

    private let motionManager = CMMotionManager()
    private let motionQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.annirudhTwo.eRideSafe.motion"
        queue.qualityOfService = .userInteractive
        queue.maxConcurrentOperationCount = 1
        return queue
    }()
    private var smoothedAccelerationG: Double = 0
    private var lastSignificantMotionDate = Date.distantPast

    init() {
        isAvailable = motionManager.isDeviceMotionAvailable
    }

    func start() {
        guard !isActive else { return }

        isAvailable = motionManager.isDeviceMotionAvailable
        guard isAvailable else {
            motionState = .unavailable
            lastError = "Accelerometer data is not available on this device."
            return
        }

        accelerationG = 0
        peakAccelerationG = 0
        smoothedAccelerationG = 0
        lastError = nil
        motionManager.deviceMotionUpdateInterval = 1.0 / 25.0
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: motionQueue) { [weak self] motion, error in
            guard let self else { return }
            Task { @MainActor in
                if let error {
                    self.lastError = error.localizedDescription
                    self.isActive = false
                    self.motionState = .unavailable
                    return
                }
                guard let motion else { return }
                self.process(motion.userAcceleration)
            }
        }
        isActive = true
        motionState = .steady
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
        isActive = false
        accelerationG = 0
        peakAccelerationG = 0
        smoothedAccelerationG = 0
        motionState = isAvailable ? .steady : .unavailable
    }

    private func process(_ acceleration: CMAcceleration) {
        let instantaneous = sqrt(
            (acceleration.x * acceleration.x)
                + (acceleration.y * acceleration.y)
                + (acceleration.z * acceleration.z)
        )
        smoothedAccelerationG = (0.22 * instantaneous) + (0.78 * smoothedAccelerationG)
        accelerationG = smoothedAccelerationG
        peakAccelerationG = max(peakAccelerationG, instantaneous)

        if instantaneous >= 0.65 {
            motionState = .sudden
            let now = Date()
            if now.timeIntervalSince(lastSignificantMotionDate) >= 2 {
                significantMotionCount += 1
                lastSignificantMotionDate = now
            }
        } else if smoothedAccelerationG >= 0.25 {
            motionState = .rough
        } else if smoothedAccelerationG >= 0.07 {
            motionState = .normal
        } else {
            motionState = .steady
        }
    }
}
