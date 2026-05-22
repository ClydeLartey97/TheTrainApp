//
//  DepartureService.swift
//  WayPoint
//
//  Created by Clyde Lartey on 11/04/2026.
//

import Foundation

// MARK: - Huxley2 API Response Models

nonisolated struct Huxley2Response: Decodable {
    let trainServices: [Huxley2Service]?
    let locationName: String?
    let crs: String?
    let generatedAt: String?
    let areServicesAvailable: Bool?
}

nonisolated struct Huxley2Service: Decodable {
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
    let serviceIdPercentEncoded: String?
    let serviceIdUrlSafe: String?
    let serviceID: String?
    let length: Int?
    let previousCallingPoints: [Huxley2CallingPointList]?
    let subsequentCallingPoints: [Huxley2CallingPointList]?
}

nonisolated struct Huxley2Location: Decodable {
    let locationName: String?
    let crs: String?
    let via: String?
}

nonisolated struct Huxley2CallingPointList: Decodable {
    let callingPoint: [Huxley2CallingPoint]?
}

nonisolated struct Huxley2CallingPoint: Decodable, Identifiable {
    var id: String { "\(crs ?? "")-\(st ?? "")" }
    let locationName: String?
    let crs: String?
    let st: String?
    let et: String?
    let at: String?
}

nonisolated struct Huxley2CRSStation: Decodable {
    let stationName: String
    let crsCode: String
}

// MARK: - Service Detail Response

nonisolated struct Huxley2ServiceDetail: Decodable {
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

    func fetchDepartures(from originCRS: String, to destinationCRS: String? = nil, date: Date = .now) async throws -> [RailTrip] {
        let url = try departureURL(from: originCRS, to: destinationCRS, date: date)

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DepartureError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw departureError(for: httpResponse.statusCode, data: data)
        }

        let huxleyResponse = try JSONDecoder().decode(Huxley2Response.self, from: data)

        guard let services = huxleyResponse.trainServices, !services.isEmpty else {
            return []
        }

        let stationName = huxleyResponse.locationName ?? originCRS
        return services.compactMap { service in
            mapServiceToTrip(service: service, fromStation: stationName, fromCRS: originCRS, destinationCRS: destinationCRS)
        }
    }

    func searchStations(query: String) async throws -> [Station] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= 2 else { return [] }

        let url = try crsURL(query: trimmedQuery)
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DepartureError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw DepartureError.httpError(httpResponse.statusCode)
        }

        return try JSONDecoder()
            .decode([Huxley2CRSStation].self, from: data)
            .map { Station(name: $0.stationName, crs: $0.crsCode) }
    }

    func fetchServiceDetail(serviceId: String) async throws -> Huxley2ServiceDetail {
        let url = try serviceURL(serviceId: serviceId)

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DepartureError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw departureError(for: httpResponse.statusCode, data: data)
        }

        return try JSONDecoder().decode(Huxley2ServiceDetail.self, from: data)
    }

    private func departureURL(from originCRS: String, to destinationCRS: String?, date: Date) throws -> URL {
        let origin = originCRS.uppercased()
        let destination = destinationCRS?.uppercased()
        let path = destination.map { "/departures/\(origin)/to/\($0)" } ?? "/departures/\(origin)"
        return try huxleyURL(path: path, queryItems: boardQueryItems(for: date))
    }

    private func serviceURL(serviceId: String) throws -> URL {
        try huxleyURL(percentEncodedPath: "/service/\(serviceId)", queryItems: [])
    }

    private func crsURL(query: String) throws -> URL {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/")
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: allowed) ?? query
        return try huxleyURL(percentEncodedPath: "/crs/\(encodedQuery)", queryItems: [])
    }

    private func boardQueryItems(for date: Date) -> [URLQueryItem] {
        [
            URLQueryItem(name: "expand", value: "true"),
            URLQueryItem(name: "timeOffset", value: "\(timeOffsetMinutes(for: date))"),
            URLQueryItem(name: "timeWindow", value: "120"),
        ]
    }

    private func huxleyURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
        try huxleyURL(percentEncodedPath: path, queryItems: queryItems)
    }

    private func huxleyURL(percentEncodedPath: String, queryItems: [URLQueryItem]) throws -> URL {
        guard var components = URLComponents(string: baseURL) else {
            throw DepartureError.invalidURL
        }
        components.percentEncodedPath = percentEncodedPath
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw DepartureError.invalidURL
        }
        return url
    }

    private func timeOffsetMinutes(for date: Date) -> Int {
        let minutes = Int(date.timeIntervalSinceNow / 60)
        return min(119, max(-120, minutes))
    }

    private func departureError(for statusCode: Int, data: Data) -> DepartureError {
        let body = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if statusCode == 401 || statusCode == 403 {
            return .httpError(statusCode)
        }
        if statusCode == 500 && body?.isEmpty != false {
            return .providerUnavailable
        }
        return .httpError(statusCode)
    }

    private func mapServiceToTrip(service: Huxley2Service, fromStation: String, fromCRS: String, destinationCRS: String?) -> RailTrip? {
        let origin = service.origin?.first?.locationName ?? fromStation
        let departureTime = service.std ?? "--:--"
        let etd = service.etd ?? ""
        let targetCRS = destinationCRS?.uppercased()
        let rawSubsequent = service.subsequentCallingPoints?.first?.callingPoint ?? []
        let targetCallingPoint = targetCRS.flatMap { crs in
            rawSubsequent.first { $0.crs?.uppercased() == crs }
        }
        let destination = targetCallingPoint?.locationName ?? service.destination?.first?.locationName ?? "Unknown"

        let arrivalTime: String
        if let targetCallingPoint {
            arrivalTime = targetCallingPoint.st ?? service.sta ?? "--:--"
        } else if let lastStop = rawSubsequent.last {
            arrivalTime = lastStop.st ?? service.sta ?? "--:--"
        } else {
            arrivalTime = service.sta ?? "--:--"
        }

        let duration = calculateDuration(from: departureTime, to: arrivalTime)
        let operatorName = service.operator ?? "Unknown"

        let status: String
        if service.isCancelled == true {
            status = "Cancelled"
        } else if etd == "On time" {
            status = "On time"
        } else if etd == "Delayed" {
            status = "Delayed"
        } else if !etd.isEmpty && etd != departureTime {
            status = "Exp. \(etd)"
        } else {
            status = "On time"
        }

        // Build calling points starting with origin as first stop
        var callingPoints: [CallingPoint] = [
            CallingPoint(
                stationName: origin,
                crs: fromCRS,
                scheduledTime: departureTime,
                estimatedTime: service.isCancelled == true ? "Cancelled" : (etd.isEmpty ? "On time" : etd),
                actualTime: nil
            )
        ]

        let subsequentSource: [Huxley2CallingPoint]
        if let targetCRS,
           let targetIndex = rawSubsequent.firstIndex(where: { $0.crs?.uppercased() == targetCRS }) {
            subsequentSource = Array(rawSubsequent.prefix(through: targetIndex))
        } else {
            subsequentSource = rawSubsequent
        }

        let subsequent: [CallingPoint] = subsequentSource.compactMap { cp in
            guard let name = cp.locationName, let time = cp.st else { return nil }
            return CallingPoint(
                stationName: name,
                crs: cp.crs ?? "",
                scheduledTime: time,
                estimatedTime: cp.et,
                actualTime: cp.at
            )
        }

        callingPoints.append(contentsOf: subsequent)

        return RailTrip(
            origin: origin,
            destination: destination,
            departureTime: departureTime,
            arrivalTime: arrivalTime,
            duration: duration,
            operatorName: operatorName,
            changeSummary: "Direct",
            price: nil,
            platform: service.platform,
            status: status,
            serviceId: service.serviceIdUrlSafe ?? service.serviceIdPercentEncoded ?? service.serviceID,
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

        if hours > 0 { return "\(hours) hr \(minutes) min" }
        return "\(minutes) min"
    }
}

enum DepartureError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case providerUnavailable
    case noServices

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid station code"
        case .invalidResponse: "Could not reach the departure service"
        case .httpError(let code): "Server error (\(code))"
        case .providerUnavailable: "The departure service is temporarily unavailable. Please try again."
        case .noServices: "No departures found"
        }
    }
}
