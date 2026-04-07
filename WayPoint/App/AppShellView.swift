//
//  AppShellView.swift
//  WayPoint
//
//  Created by Clyde Lartey on 07/04/2026.
//

import MapKit
import SwiftUI

struct AppShellView: View {
    @State private var selectedTab: AppTab = .times
    @State private var selectedNetwork: RailNetwork = .ukNationalRail
    @State private var departureDate = Date.now
    @State private var mapRegion = RailNetwork.ukNationalRail.defaultRegion

    var body: some View {
        ZStack {
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

            Group {
                switch selectedTab {
                case .times:
                    TrainTimesView(
                        selectedNetwork: $selectedNetwork,
                        departureDate: $departureDate
                    )
                case .map:
                    LiveMapView(
                        selectedNetwork: $selectedNetwork,
                        mapRegion: $mapRegion
                    )
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.88), value: selectedTab)
        }
        .safeAreaInset(edge: .bottom) {
            GlassTabBar(selectedTab: $selectedTab)
                .padding(.horizontal, 24)
                .padding(.bottom, 10)
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
