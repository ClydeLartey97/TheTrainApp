//
//  LiveMapView.swift
//  WayPoint
//
//  Created by Clyde Lartey on 07/04/2026.
//

import MapKit
import SwiftUI

struct LiveMapView: View {
    @Binding var selectedNetwork: RailNetwork
    @Binding var mapRegion: MKCoordinateRegion
    @State private var selectedCounty: CountyRegion

    init(selectedNetwork: Binding<RailNetwork>, mapRegion: Binding<MKCoordinateRegion>) {
        _selectedNetwork = selectedNetwork
        _mapRegion = mapRegion
        _selectedCounty = State(initialValue: selectedNetwork.wrappedValue.counties.first ?? .national)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                mapHeader
                mapCard
                countyFilters
                trainLegend
                trainFeed
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 120)
        }
        .onChange(of: selectedNetwork) { _, newValue in
            let fallback = newValue.counties.first ?? .national
            selectedCounty = fallback
            mapRegion = fallback.region
        }
    }

    private var mapHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Live rail map")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Select a region and the map zooms to it. Each network can plug its own live positions into the same shared map experience.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.78))
        }
    }

    private var mapCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedNetwork.displayName)
                        .font(.headline)
                    Text(selectedCounty.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Label("Live", systemImage: "dot.radiowaves.left.and.right")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.green.opacity(0.18), in: Capsule())
                    .foregroundStyle(Color.green.opacity(0.9))
            }

            Map(coordinateRegion: $mapRegion, annotationItems: selectedNetwork.trains) { train in
                MapAnnotation(coordinate: train.coordinate) {
                    VStack(spacing: 4) {
                        Image(systemName: "train.side.front.car")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(9)
                            .background(train.statusColor, in: Circle())
                            .shadow(color: train.statusColor.opacity(0.35), radius: 8, y: 3)

                        Text(train.code)
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }
            }
            .frame(height: 360)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
        .padding(20)
        .glassCard()
    }

    private var countyFilters: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Region")
                .font(.headline)
                .foregroundStyle(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(selectedNetwork.counties) { county in
                        Button {
                            selectedCounty = county
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                                mapRegion = county.region
                            }
                        } label: {
                            Text(county.displayName)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(county == selectedCounty ? Color.accentColor.opacity(0.24) : Color.white.opacity(0.5))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(county == selectedCounty ? Color.accentColor.opacity(0.4) : Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var trainLegend: some View {
        HStack(spacing: 10) {
            LegendPill(title: "On time", color: .green)
            LegendPill(title: "Minor delay", color: .orange)
            LegendPill(title: "Severe", color: .red)
        }
    }

    private var trainFeed: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tracked services")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(selectedNetwork.trains) { train in
                HStack(spacing: 14) {
                    Circle()
                        .fill(train.statusColor)
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(train.routeName)
                            .font(.subheadline.weight(.semibold))

                        Text(train.statusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(train.code)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.58), in: Capsule())
                }
                .padding(18)
                .glassCard()
            }
        }
    }
}

private struct LegendPill: View {
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.55), in: Capsule())
    }
}

#Preview {
    LiveMapView(
        selectedNetwork: .constant(.ukNationalRail),
        mapRegion: .constant(RailNetwork.ukNationalRail.defaultRegion)
    )
}
