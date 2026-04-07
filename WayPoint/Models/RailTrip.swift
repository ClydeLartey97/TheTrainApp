//
//  RailTrip.swift
//  WayPoint
//
//  Created by Clyde Lartey on 07/04/2026.
//

import Foundation

struct RailTrip: Identifiable {
    let id = UUID()
    let origin: String
    let destination: String
    let departureTime: String
    let arrivalTime: String
    let duration: String
    let operatorName: String
    let changeSummary: String
    let price: String
}
