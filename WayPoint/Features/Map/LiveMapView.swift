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
    @State private var isRegionPickerPresented = false
    @State private var isExpandedMapPresented = false

    init(selectedNetwork: Binding<RailNetwork>, mapRegion: Binding<MKCoordinateRegion>) {
        _selectedNetwork = selectedNetwork
        _mapRegion = mapRegion
        _selectedCounty = State(initialValue: selectedNetwork.wrappedValue.counties.first ?? .national)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                mapHeader
                mapControls
                mapCard
                serviceSummary
                trainFeed
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 120)
        }
        .background { WaypointGradient() }
        .onChange(of: selectedNetwork) { _, newValue in
            if selectedCounty.network != newValue {
                let fallback = newValue.counties.first ?? .national
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    selectedCounty = fallback
                }
                mapRegion = fallback.region
            }
        }
        .sheet(isPresented: $isRegionPickerPresented) {
            RegionPickerSheet(
                selectedRegion: $selectedCounty,
                selectedNetwork: $selectedNetwork,
                mapRegion: $mapRegion
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $isExpandedMapPresented) {
            ExpandedMapView(
                selectedNetwork: $selectedNetwork,
                selectedCounty: $selectedCounty,
                mapRegion: $mapRegion
            )
        }
    }

    private var mapHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Live rail map")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Tap the map to expand it. Choose a region to filter the view. The summary below stays tied to the trains you are looking at.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var mapControls: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Network")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(selectedNetwork.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(selectedCounty.locationLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .glassCard()

            Button {
                isRegionPickerPresented = true
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Region")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(selectedCounty.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Label("Change", systemImage: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.waypointTint)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .glassCard()
            }
            .buttonStyle(.plain)
        }
    }

    private var mapCard: some View {
        Button {
            isExpandedMapPresented = true
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedCounty.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("\(selectedNetwork.displayName) • \(selectedCounty.locationLabel)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Label("Tap to expand", systemImage: "arrow.up.left.and.arrow.down.right")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color.primary.opacity(0.06), in: Capsule())
                        .foregroundStyle(.secondary)
                }

                RailMapCanvas(mapRegion: $mapRegion, trains: selectedNetwork.trains, height: 310)

                HStack(spacing: 10) {
                    MapSummaryPill(title: "Tracked", value: "\(selectedNetwork.trains.count)", color: .waypointTint)
                    MapSummaryPill(title: "On time", value: "\(statusCount(for: .onTime))", color: .statusOnTime)
                    MapSummaryPill(title: "Delayed", value: "\(statusCount(for: .minorDelay) + statusCount(for: .severeDelay))", color: .statusMinorDelay)
                }
            }
            .padding(20)
            .glassCard()
        }
        .buttonStyle(.plain)
    }

    private var serviceSummary: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Service summary")
                .font(.headline)
                .foregroundStyle(.primary)

            Text(summaryLine)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                StatusMetricCard(
                    title: "On time",
                    value: "\(statusCount(for: .onTime))",
                    tint: .statusOnTime
                )
                StatusMetricCard(
                    title: "Minor",
                    value: "\(statusCount(for: .minorDelay))",
                    tint: .statusMinorDelay
                )
                StatusMetricCard(
                    title: "Severe",
                    value: "\(statusCount(for: .severeDelay))",
                    tint: .statusSevereDelay
                )
            }
        }
    }

    private var trainFeed: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Tracked services")
                .font(.headline)
                .foregroundStyle(.primary)

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

                    VStack(alignment: .trailing, spacing: 8) {
                        Text(train.code)
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.primary.opacity(0.06), in: Capsule())

                        Text(train.status.label)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(train.statusColor)
                    }
                }
                .padding(18)
                .glassCard()
            }
        }
    }

    private var summaryLine: String {
        let total = selectedNetwork.trains.count
        let severe = statusCount(for: .severeDelay)
        let delayed = statusCount(for: .minorDelay)
        let onTime = statusCount(for: .onTime)

        if severe > 0 {
            return "\(selectedCounty.displayName) has \(severe) severe disruption\(severe == 1 ? "" : "s"), \(delayed) minor delay\(delayed == 1 ? "" : "s"), and \(onTime) train\(onTime == 1 ? "" : "s") running on time out of \(total) tracked services."
        }

        if delayed > 0 {
            return "\(selectedCounty.displayName) has \(delayed) delayed service\(delayed == 1 ? "" : "s"), with \(onTime) train\(onTime == 1 ? "" : "s") currently on time."
        }

        return "All \(total) tracked services in \(selectedCounty.displayName) are currently on time."
    }

    private func statusCount(for status: TrainStatus) -> Int {
        selectedNetwork.trains.filter { $0.status == status }.count
    }
}

// MARK: - Map Canvas (non-interactive preview)

private struct RailMapCanvas: View {
    @Binding var mapRegion: MKCoordinateRegion
    let trains: [LiveTrain]
    let height: CGFloat

    var body: some View {
        Map(coordinateRegion: $mapRegion, annotationItems: trains) { train in
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
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .allowsHitTesting(false)
    }
}

// MARK: - Summary Pills

private struct MapSummaryPill: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.caption.weight(.semibold))

            Text(value)
                .font(.caption.weight(.bold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.06), in: Capsule())
        .foregroundStyle(.primary)
    }
}

// MARK: - Status Metric Card

private struct StatusMetricCard: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(tint.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(tint.opacity(0.34), lineWidth: 1)
        )
    }
}

// MARK: - Region Picker Sheet

private struct RegionPickerSheet: View {
    @Binding var selectedRegion: CountyRegion
    @Binding var selectedNetwork: RailNetwork
    @Binding var mapRegion: MKCoordinateRegion
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(RailNetwork.allCases) { network in
                    Section(network.displayName) {
                        ForEach(network.counties) { region in
                            Button {
                                selectedRegion = region
                                selectedNetwork = region.network
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    mapRegion = region.region
                                }
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

                                    if region == selectedRegion {
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
            .navigationTitle("Select Region")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Expanded Map (Full Screen)

private struct ExpandedMapView: View {
    @Binding var selectedNetwork: RailNetwork
    @Binding var selectedCounty: CountyRegion
    @Binding var mapRegion: MKCoordinateRegion
    @State private var isRegionPickerPresented = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Map fills the top
                Map(coordinateRegion: $mapRegion, annotationItems: selectedNetwork.trains) { train in
                    MapAnnotation(coordinate: train.coordinate) {
                        VStack(spacing: 4) {
                            Image(systemName: "train.side.front.car")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(train.statusColor, in: Circle())
                                .shadow(color: train.statusColor.opacity(0.35), radius: 10, y: 4)

                            Text(train.code)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: Capsule())
                        }
                    }
                }
                .clipShape(
                    UnevenRoundedRectangle(
                        bottomLeadingRadius: 28,
                        bottomTrailingRadius: 28,
                        style: .continuous
                    )
                )

                // Info panel below the map
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Region header + picker
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedCounty.displayName)
                                    .font(.title3.weight(.bold))
                                Text("\(selectedNetwork.displayName) • \(selectedCounty.locationLabel)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Button {
                                isRegionPickerPresented = true
                            } label: {
                                Label("Region", systemImage: "list.bullet")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color.primary.opacity(0.06), in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }

                        // Stats row
                        HStack(spacing: 10) {
                            MapSummaryPill(title: "Tracked", value: "\(selectedNetwork.trains.count)", color: .waypointTint)
                            MapSummaryPill(title: "On time", value: "\(onTimeCount)", color: .statusOnTime)
                            MapSummaryPill(title: "Delayed", value: "\(delayedCount)", color: .statusMinorDelay)
                        }

                        Divider()

                        // Train list
                        ForEach(selectedNetwork.trains) { train in
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(train.statusColor)
                                    .frame(width: 10, height: 10)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(train.routeName)
                                        .font(.subheadline.weight(.semibold))
                                    Text(train.statusText)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text(train.code)
                                    .font(.caption.weight(.bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.primary.opacity(0.06), in: Capsule())

                                Text(train.status.label)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(train.statusColor)
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .onAppear {
                mapRegion = selectedCounty.region
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                }
            }
            .sheet(isPresented: $isRegionPickerPresented) {
                RegionPickerSheet(
                    selectedRegion: $selectedCounty,
                    selectedNetwork: $selectedNetwork,
                    mapRegion: $mapRegion
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var onTimeCount: Int {
        selectedNetwork.trains.filter { $0.status == .onTime }.count
    }

    private var delayedCount: Int {
        selectedNetwork.trains.filter { $0.status == .minorDelay || $0.status == .severeDelay }.count
    }
}

#Preview {
    LiveMapView(
        selectedNetwork: .constant(.ukNationalRail),
        mapRegion: .constant(RailNetwork.ukNationalRail.defaultRegion)
    )
}
