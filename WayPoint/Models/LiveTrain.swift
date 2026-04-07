//
//  LiveTrain.swift
//  WayPoint
//
//  Created by Clyde Lartey on 07/04/2026.
//

import CoreLocation
import SwiftUI

struct LiveTrain: Identifiable {
    let id = UUID()
    let code: String
    let routeName: String
    let statusText: String
    let statusColor: Color
    let coordinate: CLLocationCoordinate2D
}
