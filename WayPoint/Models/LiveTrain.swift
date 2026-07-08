//
//  LiveTrain.swift
//  WayPoint
//
//  Created by Clyde Lartey on 07/04/2026.
//

import SwiftUI

// Severity used by the live metro status feeds (TfL / MTA).

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

