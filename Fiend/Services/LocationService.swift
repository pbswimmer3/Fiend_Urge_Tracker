import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()

    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var lastLocation: CLLocation?
    @Published private(set) var isRequesting: Bool = false

    private let manager = CLLocationManager()
    private var oneShotContinuation: CheckedContinuation<CLLocation?, Never>?

    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    /// Grabs one location reading. Returns nil if permission is denied or a reading can't be
    /// obtained within a short window. Non-blocking for the UI (async/await).
    func oneShotLocation(timeout: TimeInterval = 4.0) async -> CLLocation? {
        guard [.authorizedWhenInUse, .authorizedAlways].contains(authorizationStatus) else {
            return nil
        }
        if let fresh = manager.location,
           Date().timeIntervalSince(fresh.timestamp) < 30 {
            return fresh
        }

        isRequesting = true
        let location: CLLocation? = await withCheckedContinuation { continuation in
            self.oneShotContinuation = continuation
            manager.requestLocation()
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                guard let self else { return }
                if let cont = self.oneShotContinuation {
                    self.oneShotContinuation = nil
                    cont.resume(returning: self.manager.location)
                }
            }
        }
        isRequesting = false
        return location
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            self.lastLocation = latest
            if let cont = self.oneShotContinuation {
                self.oneShotContinuation = nil
                cont.resume(returning: latest)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if let cont = self.oneShotContinuation {
                self.oneShotContinuation = nil
                cont.resume(returning: nil)
            }
        }
    }
}
