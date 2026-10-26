import CoreLocation
import Foundation

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var coordinate: CLLocationCoordinate2D?
    @Published private(set) var speedMPH: Double = 0
    @Published private(set) var speedAccuracyMPH: Double?
    @Published private(set) var isSpeedAvailable = false
    @Published private(set) var horizontalAccuracy: CLLocationAccuracy?
    @Published private(set) var lastError: String?

    private let manager = CLLocationManager()
    private var smoothedSpeedMetersPerSecond: CLLocationSpeed?
    private var lastValidSpeedDate: Date?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.distanceFilter = 2
        manager.pausesLocationUpdatesAutomatically = false
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        guard CLLocationManager.locationServicesEnabled() else {
            lastError = "Location Services are disabled."
            return
        }
        manager.startUpdatingLocation()
    }

    func startRideTracking() {
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.activityType = .fitness
        manager.distanceFilter = kCLDistanceFilterNone
        smoothedSpeedMetersPerSecond = nil
        lastValidSpeedDate = nil
        speedMPH = 0
        speedAccuracyMPH = nil
        isSpeedAvailable = false
        startUpdating()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 2
        smoothedSpeedMetersPerSecond = nil
        lastValidSpeedDate = nil
        speedMPH = 0
        speedAccuracyMPH = nil
        isSpeedAvailable = false
    }

    func requestSingleLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        coordinate = location.coordinate
        horizontalAccuracy = location.horizontalAccuracy

        let sampleAge = abs(location.timestamp.timeIntervalSinceNow)
        let hasUsableSpeed = location.speed >= 0
            && sampleAge <= 5
            && location.horizontalAccuracy >= 0
            && location.horizontalAccuracy <= 65
            && (location.speedAccuracy < 0 || location.speedAccuracy <= 3.5)

        if hasUsableSpeed {
            let rawSpeed = location.speed < 0.3 ? 0 : location.speed
            let accuracy = location.speedAccuracy
            let smoothingFactor = accuracy >= 0 && accuracy <= 1.25 ? 0.45 : 0.25
            let smoothedSpeed: CLLocationSpeed

            if let previous = smoothedSpeedMetersPerSecond {
                smoothedSpeed = (smoothingFactor * rawSpeed) + ((1 - smoothingFactor) * previous)
            } else {
                smoothedSpeed = rawSpeed
            }

            smoothedSpeedMetersPerSecond = smoothedSpeed
            lastValidSpeedDate = Date()
            speedMPH = max(0, smoothedSpeed * 2.236_936)
            speedAccuracyMPH = accuracy >= 0 ? accuracy * 2.236_936 : nil
            isSpeedAvailable = true
        } else if let lastValidSpeedDate, Date().timeIntervalSince(lastValidSpeedDate) > 5 {
            speedMPH = 0
            speedAccuracyMPH = nil
            isSpeedAvailable = false
        }
        lastError = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError, clError.code == .locationUnknown { return }
        lastError = error.localizedDescription
    }
}
