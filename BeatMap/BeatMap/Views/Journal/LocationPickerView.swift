// MARK: - File Header
//
// LocationPickerView.swift
// BeatMap
//
// Version: 1.0.0
// Created: November 2025
//
// Property of A. Wheildon
// All rights reserved.
//
// MARK: - End File Header

import SwiftUI
import MapKit

/// Interactive map view for selecting a precise location for journal entries.
/// Users can pan, tap, or drop a pin to choose where they listened to music.
struct LocationPickerView: View {
    
    // MARK: - Environment & Bindings
    
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var selectedLocationString: String?
    
    // MARK: - State
    
    @State private var cameraPosition: MapCameraPosition
    @State private var currentCenterCoordinate: CLLocationCoordinate2D
    @State private var currentCenterLocationString: String = "Loading..."
    @State private var isGeocoding = false
    
    // MARK: - Initialization
    
    init(selectedCoordinate: Binding<CLLocationCoordinate2D?>, selectedLocationString: Binding<String?>) {
        self._selectedCoordinate = selectedCoordinate
        self._selectedLocationString = selectedLocationString
        
        // Initialize with provided coordinate or default to London
        let initialCoordinate = selectedCoordinate.wrappedValue ?? CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
        
        _currentCenterCoordinate = State(initialValue: initialCoordinate)
        _cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: initialCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }

    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Interactive map
                MapReader { reader in
                    Map(position: $cameraPosition)
                        .mapStyle(.standard(elevation: .realistic))
                        .onMapCameraChange(frequency: .onEnd) { context in
                            currentCenterCoordinate = context.region.center
                            reverseGeocodeCoordinate(context.region.center)
                        }
                        .onTapGesture { screenPoint in
                            if let coord = reader.convert(screenPoint, from: .local) {
                                currentCenterCoordinate = coord
                                withAnimation {
                                    cameraPosition = .region(MKCoordinateRegion(
                                        center: coord,
                                        span: cameraPosition.region?.span ?? MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                    ))
                                }
                                reverseGeocodeCoordinate(coord)
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                
                // Center marker (pin)
                Text("📍")
                    .font(.system(size: 40))
                    .shadow(radius: 4)
                    .offset(y: -20)
                    .allowsHitTesting(false)
                
                // Location confirmation box
                VStack {
                    Spacer()
                    
                    VStack(spacing: 15) {
                        // Display geocoded location name
                        Text(currentCenterLocationString)
                            .font(.headline)
                            .lineLimit(1)
                        
                        // Confirm button
                        Button("Confirm Location") {
                            selectedCoordinate = currentCenterCoordinate
                            selectedLocationString = currentCenterLocationString
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(themeManager.currentTheme.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .disabled(isGeocoding)
                    }
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(15)
                }
            }
            .padding()
            .navigationTitle("Select Location")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                reverseGeocodeCoordinate(currentCenterCoordinate)
            }
            .background(themeManager.currentTheme.primaryBackgroundColor.ignoresSafeArea())
        }
        .frame(minWidth: 500, idealWidth: 700, maxWidth: .infinity, minHeight: 600, idealHeight: 800, maxHeight: .infinity)
        .accentColor(themeManager.currentTheme.accentColor)
    }
    
    // MARK: - Helper Functions
    
    /// Performs reverse geocoding to convert coordinates to a readable location name
    private func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D) {
        isGeocoding = true
        currentCenterLocationString = "Loading..."
        
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.cancelGeocode()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            // Verify we're still at the same coordinate (within tolerance)
            let tolerance = 0.00001
            guard abs(coordinate.latitude - self.currentCenterCoordinate.latitude) < tolerance,
                  abs(coordinate.longitude - self.currentCenterCoordinate.longitude) < tolerance else {
                return
            }
            
            if let placemark = placemarks?.first {
                var nameParts: [String] = []
                
                // Include point of interest name if available and meaningful
                if let poi = placemark.name, !poi.contains("Unnamed Road") {
                    nameParts.append(poi)
                }
                if let city = placemark.locality {
                    nameParts.append(city)
                }
                if let country = placemark.country {
                    nameParts.append(country)
                }

                let name = nameParts.joined(separator: ", ")
                currentCenterLocationString = name.isEmpty ? "Unknown Location" : name
                print("📍 Geocoded: \(currentCenterLocationString)")
            } else {
                currentCenterLocationString = "Location not found"
                print("❓ Geocoding failed")
            }
            
            isGeocoding = false
        }
    }
}

#Preview {
    PreviewContainer {
        @State var previewCoord: CLLocationCoordinate2D? = CLLocationCoordinate2D(latitude: 54.9783, longitude: -1.6178)
        @State var previewString: String? = "Newcastle upon Tyne, UK"
        
        LocationPickerView(selectedCoordinate: $previewCoord, selectedLocationString: $previewString)
    }
}
