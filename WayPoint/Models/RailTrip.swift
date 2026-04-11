//
//  RailTrip.swift
//  WayPoint
//
//  Created by Clyde Lartey on 07/04/2026.
//

import Foundation

struct CallingPoint: Identifiable, Hashable {
    var id: String { "\(crs)-\(scheduledTime)" }
    let stationName: String
    let crs: String
    let scheduledTime: String
    let estimatedTime: String?
    let actualTime: String?

    var displayTime: String {
        if let actual = actualTime, !actual.isEmpty {
            return actual
        }
        if let estimated = estimatedTime, estimated != "On time" && !estimated.isEmpty {
            return estimated
        }
        return scheduledTime
    }

    var isOnTime: Bool {
        estimatedTime == nil || estimatedTime == "On time"
    }
}

struct RailTrip: Identifiable {
    let id = UUID()
    let origin: String
    let destination: String
    let departureTime: String
    let arrivalTime: String
    let duration: String
    let operatorName: String
    let changeSummary: String
    let price: String?
    let platform: String?
    let status: String?
    let serviceId: String?
    let callingPoints: [CallingPoint]
    let isCancelled: Bool
    let cancelReason: String?
    let delayReason: String?

    /// Convenience initializer for sample/static data
    init(
        origin: String,
        destination: String,
        departureTime: String,
        arrivalTime: String,
        duration: String,
        operatorName: String,
        changeSummary: String,
        price: String?,
        platform: String? = nil,
        status: String? = "On time",
        serviceId: String? = nil,
        callingPoints: [CallingPoint] = [],
        isCancelled: Bool = false,
        cancelReason: String? = nil,
        delayReason: String? = nil
    ) {
        self.origin = origin
        self.destination = destination
        self.departureTime = departureTime
        self.arrivalTime = arrivalTime
        self.duration = duration
        self.operatorName = operatorName
        self.changeSummary = changeSummary
        self.price = price
        self.platform = platform
        self.status = status
        self.serviceId = serviceId
        self.callingPoints = callingPoints
        self.isCancelled = isCancelled
        self.cancelReason = cancelReason
        self.delayReason = delayReason
    }
}
