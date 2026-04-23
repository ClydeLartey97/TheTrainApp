//
//  LocationManager.swift
//  WayPoint
//
//  Created by Clyde Lartey on 22/04/2026.
//

import CoreLocation
import Observation

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let clManager = CLLocationManager()
    private(set) var detectedNetwork: RailNetwork? = nil
    private(set) var currentCoordinate: CLLocationCoordinate2D?
    private(set) var locationRevision = 0

    override init() {
        super.init()
        clManager.delegate = self
        clManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestOnce() {
        switch clManager.authorizationStatus {
        case .notDetermined:
            clManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            clManager.requestLocation()
        default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
            manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        currentCoordinate = loc.coordinate
        locationRevision += 1
        detectedNetwork = RailNetwork.network(for: loc.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
