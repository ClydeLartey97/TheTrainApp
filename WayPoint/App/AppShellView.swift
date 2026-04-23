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

    var body: some View {
        TabView {
            Tab("Times", systemImage: "ticket.fill") {
                TrainTimesView(
                    selectedNetwork: $selectedNetwork,
                    departureDate: $departureDate
                )
            }

            Tab("Live Map", systemImage: "map.fill") {
                LiveMapView(
                    selectedNetwork: $selectedNetwork,
                    mapRegion: $mapRegion
                )
            }

            Tab(selectedNetwork.rapidTransitTabLabel, systemImage: "tram.fill") {
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
}

#Preview {
    AppShellView()
}
