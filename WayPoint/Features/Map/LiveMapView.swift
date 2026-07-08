//
//  LiveMapView.swift
//  WayPoint
//
//  Created by Clyde Lartey on 07/04/2026.
//

import MapKit
import SwiftUI

/// Interactive national station map: every UK station is a real pin backed by
/// the bundled corpus, and tapping one opens its live departure board.
struct LiveMapView: View {
    @Binding var selectedNetwork: RailNetwork
    @Binding var mapRegion: MKCoordinateRegion

    @State private var position: MapCameraPosition
    @State private var visibleRegion: MKCoordinateRegion
    @State private var selectedStation: Station?
    @State private var isRegionPickerPresented = false

    private let repo = StationRepository.shared

    /// Above this latitude span only major stations are pinned; the cap keeps
    /// dense city views responsive.
    private static let majorsOnlySpan = 2.4
    private static let annotationCap = 90

    init(selectedNetwork: Binding<RailNetwork>, mapRegion: Binding<MKCoordinateRegion>) {
        _selectedNetwork = selectedNetwork
        _mapRegion = mapRegion
        _position = State(initialValue: .region(mapRegion.wrappedValue))
        _visibleRegion = State(initialValue: mapRegion.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            Map(position: $position) {
                ForEach(visibleStations) { station in
                    Annotation(
                        annotationTitle(for: station),
                        coordinate: station.coordinate ?? .init(),
                        anchor: .bottom
                    ) {
                        Button {
                            selectedStation = station
                        } label: {
                            stationPin(for: station)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(station.name) station")
                        .accessibilityIdentifier("station-pin-\(station.crs)")
                    }
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .onMapCameraChange(frequency: .onEnd) { context in
                visibleRegion = context.region
                mapRegion = context.region
            }
            .ignoresSafeArea(edges: .bottom)
            .overlay(alignment: .top) { mapHeader }
            .overlay(alignment: .bottom) {
                if !selectedNetwork.hasLiveDepartures {
                    comingSoonOverlay
                }
            }
            .navigationTitle("Stations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isRegionPickerPresented = true
                    } label: {
                        Label("Region", systemImage: "globe.europe.africa.fill")
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
            .sheet(item: $selectedStation) { station in
                StationBoardSheet(station: station)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isRegionPickerPresented) {
                RegionPickerSheet(
                    selectedNetwork: $selectedNetwork,
                    onSelect: { region in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            position = .region(region)
                        }
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .onChange(of: selectedNetwork) { _, newValue in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    position = .region(newValue.defaultRegion)
                }
            }
        }
    }

    // MARK: - Stations for the current viewport

    private var visibleStations: [Station] {
        guard selectedNetwork.hasLiveDepartures else { return [] }

        let latSpan = visibleRegion.span.latitudeDelta
        let lonSpan = visibleRegion.span.longitudeDelta
        let center = visibleRegion.center
        // Slight over-fetch beyond the edges so pins don't pop in late while panning.
        let latPad = latSpan * 0.6
        let lonPad = lonSpan * 0.6

        return repo.stations(
            latitude: (center.latitude - latPad)...(center.latitude + latPad),
            longitude: (center.longitude - lonPad)...(center.longitude + lonPad),
            majorsOnly: latSpan > Self.majorsOnlySpan,
            limit: Self.annotationCap
        )
    }

    private func annotationTitle(for station: Station) -> String {
        // Labels clutter the country view; show them once zoomed in.
        visibleRegion.span.latitudeDelta < 0.6 ? station.name : ""
    }

    private func stationPin(for station: Station) -> some View {
        let isMajor = StationRepository.majorCRSCodes.contains(station.crs)
        return Image(systemName: "train.side.front.car")
            .font(.system(size: isMajor ? 12 : 9, weight: .bold))
            .foregroundStyle(.white)
            .padding(isMajor ? 8 : 6)
            .background(isMajor ? Color.waypointTint : Color.waypointTeal, in: Circle())
            .shadow(color: Color.black.opacity(0.25), radius: 3, y: 2)
    }

    // MARK: - Overlays

    private var mapHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.tap.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.waypointTint)
            Text(selectedNetwork.hasLiveDepartures
                ? "Tap any station for its live departure board."
                : "\(selectedNetwork.displayName) market map")
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.top, 8)
    }

    private var comingSoonOverlay: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("\(selectedNetwork.displayName) stations coming soon", systemImage: "clock")
                .font(.subheadline.weight(.semibold))
            Text("Station pins and live boards are connected market by market. UK Rail is fully live today — switch back any time from the Times tab.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

// MARK: - Region Picker Sheet

private struct RegionPickerSheet: View {
    @Binding var selectedNetwork: RailNetwork
    let onSelect: (MKCoordinateRegion) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(RailNetwork.allCases) { network in
                    Section(network.displayName) {
                        ForEach(network.regions) { region in
                            Button {
                                selectedNetwork = network
                                onSelect(region.region)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(region.displayName)
                                            .foregroundStyle(.primary)
                                        Text(region.locationLabel)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if network == selectedNetwork {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.waypointTint)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Jump to market")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    LiveMapView(
        selectedNetwork: .constant(.ukNationalRail),
        mapRegion: .constant(RailNetwork.ukNationalRail.defaultRegion)
    )
    .environment(JourneyTracker())
}
