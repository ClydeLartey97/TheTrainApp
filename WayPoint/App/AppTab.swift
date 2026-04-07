//
//  AppTab.swift
//  WayPoint
//
//  Created by Clyde Lartey on 07/04/2026.
//

import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case times
    case map

    var id: String { rawValue }

    var title: String {
        switch self {
        case .times:
            "Times"
        case .map:
            "Live Map"
        }
    }

    var symbol: String {
        switch self {
        case .times:
            "ticket.fill"
        case .map:
            "map.fill"
        }
    }
}
