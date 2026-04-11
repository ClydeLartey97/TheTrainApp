//
//  LiveTrain.swift
//  WayPoint
//
//  Created by Clyde Lartey on 07/04/2026.
//

import CoreLocation
import SwiftUI

enum TrainStatus: String, CaseIterable, Identifiable {
    case onTime
    case minorDelay
    case severeDelay

    var id: String { rawValue }

    var label: String {
        switch self {
        case .onTime:
            "On time"
        case .minorDelay:
            "Minor delay"
        case .severeDelay:
            "Severe delay"
        }
    }

    var color: Color {
        switch self {
        case .onTime:
            .statusOnTime
        case .minorDelay:
            .statusMinorDelay
        case .severeDelay:
            .statusSevereDelay
        }
    }
}

struct LiveTrain: Identifiable {
    let id = UUID()
    let code: String
    let routeName: String
    let statusText: String
    let status: TrainStatus
    let coordinate: CLLocationCoordinate2D

    var statusColor: Color { status.color }
}
