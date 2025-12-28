//
//  LocationManager.swift
//  Wiki Near Me
//
//  Created on December 27, 2025.
//

import Foundation
import CoreLocation
import SwiftUI
import Observation

/// Manages location permissions and one-time location fetching
@MainActor
@Observable
class LocationManager: NSObject {
    var currentLocation: CLLocationCoordinate2D?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isUsingDemoLocation = false
    var locationError: String?
    
    private let locationManager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?
    
    // Demo location: New York City (Times Square)
    static let demoLocation = CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855)
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorizationStatus = locationManager.authorizationStatus
    }
    
    /// Request location permission if needed
    func requestPermissionIfNeeded() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // Use demo location
            currentLocation = Self.demoLocation
            isUsingDemoLocation = true
        case .authorizedWhenInUse, .authorizedAlways:
            // Already authorized
            break
        @unknown default:
            break
        }
    }
    
    /// Fetch location once (one-time fix)
    func fetchLocation() async -> CLLocationCoordinate2D? {
        locationError = nil
        
        // Check authorization
        switch authorizationStatus {
        case .denied, .restricted:
            isUsingDemoLocation = true
            currentLocation = Self.demoLocation
            return Self.demoLocation
            
        case .notDetermined:
            requestPermissionIfNeeded()
            // Wait a bit for user to respond
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
            // Check again after permission request
            if authorizationStatus == .denied || authorizationStatus == .restricted {
                isUsingDemoLocation = true
                currentLocation = Self.demoLocation
                return Self.demoLocation
            }
            
        case .authorizedWhenInUse, .authorizedAlways:
            break
            
        @unknown default:
            break
        }
        
        // Request one-time location
        return await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }
    }
    
    /// Reset to use current location (stop using demo)
    func useCurrentLocation() {
        isUsingDemoLocation = false
        locationError = nil
        Task {
            _ = await fetchLocation()
        }
    }
    
    /// Open Settings app for location permissions
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            
            // If denied/restricted, switch to demo mode
            if authorizationStatus == .denied || authorizationStatus == .restricted {
                isUsingDemoLocation = true
                currentLocation = Self.demoLocation
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else {
                locationContinuation?.resume(returning: nil)
                locationContinuation = nil
                return
            }
            
            currentLocation = location.coordinate
            isUsingDemoLocation = false
            locationContinuation?.resume(returning: location.coordinate)
            locationContinuation = nil
            
            // Stop updating after one fix
            manager.stopUpdatingLocation()
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            locationError = error.localizedDescription
            
            // Fall back to demo location on error
            currentLocation = Self.demoLocation
            isUsingDemoLocation = true
            
            locationContinuation?.resume(returning: Self.demoLocation)
            locationContinuation = nil
            
            manager.stopUpdatingLocation()
        }
    }
}
