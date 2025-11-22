// MARK: - File Header
//
// LocationManager.swift
// BeatMap
//
// Version: 1.0.0
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocation?
    @Published var locationName: String = "Unknown Location"
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isMonitoring = false
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    // Debouncing
    private var locationUpdateCancellable: AnyCancellable?
    private let locationSubject = PassthroughSubject<CLLocation, Never>()
    private var lastProcessedLocation: CLLocation?
    private let minimumDistance: CLLocationDistance = 10.0 // meters
    private let minimumTimeInterval: TimeInterval = 2.0 // seconds
    
    // Geocoding cache
    private var geocodingCache: [String: String] = [:]
    private var pendingGeocoding = false
    
    override init() {
        super.init()
        print("✅ LocationManager initialized.")
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Only notify when moved 10+ meters
        
        authorizationStatus = locationManager.authorizationStatus
        
        // Set up debouncing for location updates
        locationUpdateCancellable = locationSubject
            .throttle(for: .seconds(minimumTimeInterval), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] location in
                self?.processLocation(location)
            }
        
        // Don't start monitoring immediately - wait for explicit request
        print("📍 LocationManager ready (not monitoring yet)")
    }
    
    // MARK: - Public Methods
    
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        print("📍 Starting location monitoring...")
        locationManager.startUpdatingLocation()
        isMonitoring = true
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        print("📍 Stopping location monitoring...")
        locationManager.stopUpdatingLocation()
        isMonitoring = false
    }
    
    func requestPreciseLocation() async -> CLLocation? {
        print("📍 Requesting precise location...")
        startMonitoring()
        
        // Wait up to 3 seconds for a good location
        return await withCheckedContinuation { continuation in
            var hasReturned = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                if !hasReturned {
                    hasReturned = true
                    print("✅ Precise location obtained: \(self?.currentLocation?.coordinate.latitude ?? 0), \(self?.currentLocation?.coordinate.longitude ?? 0)")
                    continuation.resume(returning: self?.currentLocation)
                }
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Check if we should process this update
        if let lastLocation = lastProcessedLocation {
            let distance = location.distance(from: lastLocation)
            let timeInterval = location.timestamp.timeIntervalSince(lastLocation.timestamp)
            
            // Skip if moved < 10m AND < 2 seconds passed
            if distance < minimumDistance && timeInterval < minimumTimeInterval {
                return
            }
        }
        
        // Send to debounced processor
        locationSubject.send(location)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        print("🔐 Location authorization changed: \(authorizationStatus.rawValue)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location manager failed with error: \(error.localizedDescription)")
    }
    
    // MARK: - Private Methods
    
    private func processLocation(_ location: CLLocation) {
        lastProcessedLocation = location
        currentLocation = location
        print("📍 Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        // Reverse geocode with caching
        reverseGeocodeLocation(location)
    }
    
    private func reverseGeocodeLocation(_ location: CLLocation) {
        // Create cache key (rounded to ~100m precision)
        let cacheKey = "\(Int(location.coordinate.latitude * 1000)),\(Int(location.coordinate.longitude * 1000))"
        
        // Check cache first
        if let cached = geocodingCache[cacheKey] {
            print("🗺️ Using cached location: \(cached)")
            self.locationName = cached
            return
        }
        
        // Prevent multiple simultaneous geocoding requests
        guard !pendingGeocoding else {
            print("⏳ Geocoding already in progress, skipping...")
            return
        }
        
        pendingGeocoding = true
        
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            self.pendingGeocoding = false
            
            if let error = error {
                print("❌ Reverse geocoding failed: \(error.localizedDescription)")
                return
            }
            
            if let placemark = placemarks?.first {
                let components = [
                    placemark.locality,
                    placemark.country
                ].compactMap { $0 }
                
                let name = components.joined(separator: ", ")
                self.locationName = name
                
                // Store in cache
                self.geocodingCache[cacheKey] = name
                print("🗺️ Reverse geocoded location: \(name)")
            }
        }
    }
}
