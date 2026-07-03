//
//  AppShellView.swift
//  WayPoint
//
//  Created by Clyde Lartey on 07/04/2026.
//

import MapKit
import SwiftUI

struct AppShellView: View {
    @State private var selectedNetwork: RailNetwork = .ukNationalRail
    @State private var departureDate = Date.now
    @State private var mapRegion = RailNetwork.ukNationalRail.defaultRegion
    @State private var locationManager = LocationManager()
    @State private var selectedTab = AppShellView.initialTab

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Times", systemImage: "ticket.fill", value: 0) {
                TrainTimesView(
                    selectedNetwork: $selectedNetwork,
                    departureDate: $departureDate
                )
            }

            Tab("Live Map", systemImage: "map.fill", value: 1) {
                LiveMapView(
                    selectedNetwork: $selectedNetwork,
                    mapRegion: $mapRegion
                )
            }

            Tab(selectedNetwork.rapidTransitTabLabel, systemImage: "tram.fill", value: 2) {
                SubwayMapView(selectedNetwork: $selectedNetwork)
            }
        }
        .tint(.waypointTint)
        .onAppear {
            mapRegion = selectedNetwork.defaultRegion
            locationManager.requestOnce()
        }
        .onChange(of: locationManager.detectedNetwork) { _, detected in
            guard let network = detected else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedNetwork = network
            }
        }
        .onChange(of: selectedNetwork) { _, newValue in
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                mapRegion = newValue.defaultRegion
            }
        }
    }

    /// Launch-environment override so automated simulator runs can land on a
    /// specific tab (DEBUG only): WAYPOINT_DEBUG_TAB = times | livemap | metro.
    private static var initialTab: Int {
        #if DEBUG
        switch ProcessInfo.processInfo.environment["WAYPOINT_DEBUG_TAB"] {
        case "livemap": 1
        case "metro": 2
        default: 0
        }
        #else
        0
        #endif
    }
}

#Preview {
    AppShellView()
}
