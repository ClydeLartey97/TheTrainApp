//
//  DepartureService.swift
//  WayPoint
//
//  Created by Clyde Lartey on 11/04/2026.
//

import Foundation

// MARK: - Huxley2 API Response Models

struct Huxley2Response: Decodable {
    let trainServices: [Huxley2Service]?
    let locationName: String?
    let crs: String?
    let generatedAt: String?
    let areServicesAvailable: Bool?
}

struct Huxley2Service: Decodable {
    let origin: [Huxley2Location]?
    let destination: [Huxley2Location]?
    let std: String? // scheduled time of departure
    let etd: String? // estimated time of departure ("On time", "Delayed", "Cancelled", or time)
    let sta: String? // scheduled time of arrival
    let eta: String? // estimated time of arrival
    let platform: String?
    let `operator`: String?
    let operatorCode: String?
    let isCancelled: Bool?
    let cancelReason: String?
    let delayReason: String?
    let serviceIdPercentEncoded: String?
    let length: Int?

    // Service details (when fetched individually)
    let previousCallingPoints: [Huxley2CallingPointList]?
    let subsequentCallingPoints: [Huxley2CallingPointList]?
}

struct Huxley2Location: Decodable {
    let locationName: String?
    let crs: String?
    let via: String?
}

struct Huxley2CallingPointList: Decodable {
    let callingPoint: [Huxley2CallingPoint]?
}

struct Huxley2CallingPoint: Decodable, Identifiable {
    var id: String { "\(crs ?? "")-\(st ?? "")" }
    let locationName: String?
    let crs: String?
    let st: String? // scheduled time
    let et: String? // estimated time
    let at: String? // actual time
}

// MARK: - Service Detail Response

struct Huxley2ServiceDetail: Decodable {
    let origin: [Huxley2Location]?
    let destination: [Huxley2Location]?
    let std: String?
    let etd: String?
    let sta: String?
    let eta: String?
    let platform: String?
    let `operator`: String?
    let operatorCode: String?
    let isCancelled: Bool?
    let cancelReason: String?
    let delayReason: String?
    let previousCallingPoints: [Huxley2CallingPointList]?
    let subsequentCallingPoints: [Huxley2CallingPointList]?
}

// MARK: - Departure Service

actor DepartureService {
    static let shared = DepartureService()

    private let baseURL = "https://huxley2.azurewebsites.net"
    private let session: URLSession

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    /// Fetch departures from a station, optionally filtered to a destination and time.
    /// `date` defaults to now; future dates produce a positive `timeOffset` (minutes ahead).
    func fetchDepartures(from originCRS: String, to destinationCRS: String? = nil, date: Date = .now) async throws -> [RailTrip] {
        var urlString = "\(baseURL)/departures/\(originCRS)"
        if let dest = destinationCRS {
            urlString += "/to/\(dest)"
        }
        let offsetMinutes = max(0, Int(date.timeIntervalSinceNow / 60))
        urlString += "?expand=true&timeOffset=\(offsetMinutes)"

        guard let url = URL(string: urlString) else {
            throw DepartureError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DepartureError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw DepartureError.httpError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let huxleyResponse = try decoder.decode(Huxley2Response.self, from: data)

        guard let services = huxleyResponse.trainServices, !services.isEmpty else {
            return []
        }

        return services.compactMap { service in
            mapServiceToTrip(service: service, fromStation: huxleyResponse.locationName ?? originCRS)
        }
    }

    /// Fetch service details (calling points) for a specific service
    func fetchServiceDetail(serviceId: String) async throws -> Huxley2ServiceDetail {
        let urlString = "\(baseURL)/service/\(serviceId)"

        guard let url = URL(string: urlString) else {
            throw DepartureError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DepartureError.invalidResponse
        }

        return try JSONDecoder().decode(Huxley2ServiceDetail.self, from: data)
    }

    private func mapServiceToTrip(service: Huxley2Service, fromStation: String) -> RailTrip? {
        let origin = service.origin?.first?.locationName ?? fromStation
        let destination = service.destination?.first?.locationName ?? "Unknown"
        let departureTime = service.std ?? "--:--"
        let etd = service.etd ?? ""

        // Calculate estimated arrival from subsequent calling points
        let arrivalTime: String
        if let callingPoints = service.subsequentCallingPoints?.first?.callingPoint,
           let lastStop = callingPoints.last {
            arrivalTime = lastStop.st ?? "--:--"
        } else {
            arrivalTime = "--:--"
        }

        // Calculate duration from departure and arrival times
        let duration = calculateDuration(from: departureTime, to: arrivalTime)

        let operatorName = service.operator ?? "Unknown"
        let platform = service.platform

        // Determine status
        let status: String
        if service.isCancelled == true {
            status = "Cancelled"
        } else if etd == "On time" {
            status = "On time"
        } else if etd == "Delayed" {
            status = "Delayed"
        } else if etd != departureTime && !etd.isEmpty {
            status = "Exp. \(etd)"
        } else {
            status = "On time"
        }

        // Build calling points list
        let callingPoints: [CallingPoint] = service.subsequentCallingPoints?.first?.callingPoint?.compactMap { cp in
            guard let name = cp.locationName, let time = cp.st else { return nil }
            return CallingPoint(
                stationName: name,
                crs: cp.crs ?? "",
                scheduledTime: time,
                estimatedTime: cp.et,
                actualTime: cp.at
            )
        } ?? []

        return RailTrip(
            origin: origin,
            destination: destination,
            departureTime: departureTime,
            arrivalTime: arrivalTime,
            duration: duration,
            operatorName: operatorName,
            changeSummary: "Direct",
            price: nil,
            platform: platform,
            status: status,
            serviceId: service.serviceIdPercentEncoded,
            callingPoints: callingPoints,
            isCancelled: service.isCancelled ?? false,
            cancelReason: service.cancelReason,
            delayReason: service.delayReason
        )
    }

    private func calculateDuration(from departure: String, to arrival: String) -> String {
        let parts1 = departure.split(separator: ":")
        let parts2 = arrival.split(separator: ":")

        guard parts1.count == 2, parts2.count == 2,
              let h1 = Int(parts1[0]), let m1 = Int(parts1[1]),
              let h2 = Int(parts2[0]), let m2 = Int(parts2[1]) else {
            return ""
        }

        var totalMinutes = (h2 * 60 + m2) - (h1 * 60 + m1)
        if totalMinutes < 0 { totalMinutes += 24 * 60 }

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        }
        return "\(minutes) min"
    }
}

enum DepartureError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case noServices

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid station code"
        case .invalidResponse:
            "Could not reach the departure service"
        case .httpError(let code):
            "Server error (\(code))"
        case .noServices:
            "No departures found"
        }
    }
}
