//
//  WaypointTheme.swift
//  WayPoint
//
//  Created by Codex on 10/04/2026.
//

import SwiftUI

struct WaypointGradient: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        LinearGradient(
            colors: colorScheme == .dark ? [
                Color(red: 0.05, green: 0.09, blue: 0.16),
                Color(red: 0.08, green: 0.13, blue: 0.24),
                Color(red: 0.10, green: 0.18, blue: 0.34),
            ] : [
                Color(red: 0.96, green: 0.97, blue: 1.0),
                Color(red: 0.83, green: 0.88, blue: 0.98),
                Color(red: 0.65, green: 0.74, blue: 0.96),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

extension Color {
    static let waypointTint = Color(red: 0.17, green: 0.47, blue: 0.95)
    static let waypointTeal = Color(red: 0.08, green: 0.72, blue: 0.85)

    static let statusOnTime = Color(red: 0.20, green: 0.73, blue: 0.36)
    static let statusMinorDelay = Color(red: 0.95, green: 0.60, blue: 0.17)
    static let statusSevereDelay = Color(red: 0.86, green: 0.24, blue: 0.22)
}

// MARK: - Trip Status

enum TripStatus {
    case onTime
    case minorDelay
    case expectedDelay(String)
    case cancelled
    case unknown

    init(_ raw: String?) {
        switch raw {
        case "On time": self = .onTime
        case "Cancelled": self = .cancelled
        case "Delayed": self = .minorDelay
        case let s? where s.hasPrefix("Exp."): self = .expectedDelay(s)
        default: self = .unknown
        }
    }

    var color: Color {
        switch self {
        case .onTime: .statusOnTime
        case .cancelled: .statusSevereDelay
        case .minorDelay, .expectedDelay: .statusMinorDelay
        case .unknown: .secondary
        }
    }
}

extension RailTrip {
    var tripStatus: TripStatus { TripStatus(status) }
}
