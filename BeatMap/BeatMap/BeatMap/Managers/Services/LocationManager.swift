// MARK: - File Header
//
// LocationManager.swift
// BeatMap
//
// Version: 1.1.0 (Enhanced Location Services)
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import Foundation
import CoreLocation
import Combine

/// Manages fetching and monitoring the user's current geographical location.
/// Provides both coordinate data and human-readable location strings for BeatMap journal entries.
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    /// The user's location formatted as a readable string (e.g., "Newcastle upon Tyne, UK")
    @Published var locationString: String = "Finding location..."

    /// The raw CLLocation object containing precise coordinates
    @Published var currentLocation: CLLocation?

    // MARK: - Throttling Properties
    
    private var lastGeocodeTime: Date?
    private let geocodeThrottleInterval: TimeInterval = 2.0 // Don't geocode more than once per 2 seconds
    
    // MARK: - Precise Location Request
    
    private var preciseLocationCompletion: ((CLLocation?, String?) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        print("✅ LocationManager initialized.")
    }

    // MARK: - Public Methods
    
    /// Request a fresh, high-accuracy location update
    /// - Parameter completion: Callback with location and location string when available
    func requestPreciseLocation(completion: @escaping (CLLocation?, String?) -> Void) {
        print("📍 Requesting precise location...")
        
        // Store completion handler
        preciseLocationCompletion = completion
        
        // Request a new location update
        manager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate

    /// Called when new location data is available
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        self.currentLocation = location
        print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")

        // Throttle reverse geocoding to avoid rate limits
        let now = Date.now
        if let lastTime = lastGeocodeTime, now.timeIntervalSince(lastTime) < geocodeThrottleInterval {
            // Skip geocoding if we did it recently
            return
        }
        
        lastGeocodeTime = now
        
        // Reverse geocode to get human-readable location name
        reverseGeocode(location: location)
    }

    /// Called when location fetching fails (e.g., permission denied)
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let errorCode = (error as NSError).code
        
        // Handle specific error codes
        if errorCode == CLError.denied.rawValue {
            locationString = "Location access denied"
            print("❌ Location access denied by user")
        } else if errorCode == CLError.locationUnknown.rawValue {
            locationString = "Location unknown"
            print("⚠️ Location temporarily unavailable")
        } else {
            locationString = "Location unavailable"
            print("❌ Location manager failed with error: \(error.localizedDescription)")
        }
        
        // Call completion handler with nil if precise location was requested
        if let completion = preciseLocationCompletion {
            completion(nil, nil)
            preciseLocationCompletion = nil
        }
    }
    
    // MARK: - Geocoding
    
    private func reverseGeocode(location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.cancelGeocode()
        
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            
            if let placemark = placemarks?.first {
                let locationStr = self.formatLocationString(from: placemark)
                
                DispatchQueue.main.async {
                    self.locationString = locationStr
                    print("🗺️ Reverse geocoded location: \(locationStr)")
                    
                    // Call completion handler if precise location was requested
                    if let completion = self.preciseLocationCompletion {
                        completion(location, locationStr)
                        self.preciseLocationCompletion = nil
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.locationString = "Location not found"
                    print("❌ Reverse geocoding failed: \(error?.localizedDescription ?? "Unknown error")")
                    
                    // Call completion handler with location but no string
                    if let completion = self.preciseLocationCompletion {
                        completion(location, "Unknown Location")
                        self.preciseLocationCompletion = nil
                    }
                }
            }
        }
    }
    
    private func formatLocationString(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        // Add thoroughfare (street name) if available
        if let thoroughfare = placemark.thoroughfare, !thoroughfare.contains("Unnamed") {
            components.append(thoroughfare)
        }
        
        // Add locality (city)
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        // Add country
        if let country = placemark.country {
            components.append(country)
        }
        
        return components.isEmpty ? "Unknown Location" : components.joined(separator: ", ")
    }
}
