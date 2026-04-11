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
        }
        .tint(.waypointTint)
        .background {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.11, blue: 0.18),
                    Color(red: 0.10, green: 0.16, blue: 0.28),
                    Color(red: 0.93, green: 0.96, blue: 0.99),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .onAppear {
            mapRegion = selectedNetwork.defaultRegion
        }
        .onChange(of: selectedNetwork) { _, newValue in
            mapRegion = newValue.defaultRegion
        }
    }
}

#Preview {
    AppShellView()
}
