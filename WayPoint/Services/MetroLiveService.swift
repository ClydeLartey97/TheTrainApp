//
//  MetroLiveService.swift
//  WayPoint
//
//  Created by Codex on 22/04/2026.
//

import Foundation

struct MetroLineLiveStatus: Identifiable {
    let id: String
    let lineID: String
    let lineName: String
    let statusText: String
    let reason: String?
    let status: TrainStatus

    var displayReason: String {
        guard let reason, !reason.isEmpty else { return statusText }
        return reason
    }
}

struct MetroArrivalPrediction: Identifiable {
    let id: String
    let lineName: String
    let stationName: String
    let destinationName: String
    let platformName: String?
    let timeToStation: Int

    var minutesAway: Int {
        max(0, Int(ceil(Double(timeToStation) / 60.0)))
    }
}

enum MetroLiveError: LocalizedError {
    case unsupportedProvider
    case invalidURL
    case invalidResponse
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .unsupportedProvider:
            "Official live data is not wired for this metro system yet."
        case .invalidURL:
            "Could not build the live data request."
        case .invalidResponse:
            "The live data provider returned an unreadable response."
        case .httpError(let code):
            "The live data provider returned HTTP \(code)."
        }
    }
}

actor MetroLiveService {
    static let shared = MetroLiveService()
    private static let tflTubeLineIDs = [
        "bakerloo",
        "central",
        "circle",
        "district",
        "hammersmith-city",
        "jubilee",
        "metropolitan",
        "northern",
        "piccadilly",
        "victoria",
        "waterloo-city",
    ]
    private static let mtaSubwayBaseURL = "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds"
    private static let mtaAlertsFeedPath = "camsys%2Fall-alerts"
    private static let lirrFeedPath = "lirr%2Fgtfs-lirr"
    private static let metroNorthFeedPath = "mnr%2Fgtfs-mnr"
    private static let mtaSubwayFeeds = [
        "nyct%2Fgtfs",
        "nyct%2Fgtfs-ace",
        "nyct%2Fgtfs-bdfm",
        "nyct%2Fgtfs-g",
        "nyct%2Fgtfs-jz",
        "nyct%2Fgtfs-nqrw",
        "nyct%2Fgtfs-l",
        "nyct%2Fgtfs-si",
    ]
    private static let mtaSubwayRouteIDs = [
        "1", "2", "3", "4", "5", "6", "7",
        "A", "C", "E", "B", "D", "F", "M",
        "G", "J", "Z", "N", "Q", "R", "W",
        "L", "S",
    ]
    private static let mtaCacheInterval: TimeInterval = 30

    private let session: URLSession
    private var mtaFeedCache: [String: (fetchedAt: Date, entities: [MTARealtimeEntity])] = [:]

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchLineStatuses(for system: MetroSystem) async throws -> [MetroLineLiveStatus] {
        switch system {
        case .londonUnderground:
            try await fetchTfLLineStatuses()
        case .nycSubway:
            try await fetchMTASubwayStatuses()
        case .lirr:
            try await fetchMTACommuterRailStatuses(feedPath: Self.lirrFeedPath, prefix: "lirr")
        case .metroNorth:
            try await fetchMTACommuterRailStatuses(feedPath: Self.metroNorthFeedPath, prefix: "mnr")
        default:
            throw MetroLiveError.unsupportedProvider
        }
    }

    func fetchArrivals(for system: MetroSystem) async throws -> [MetroArrivalPrediction] {
        switch system {
        case .londonUnderground:
            try await fetchTfLArrivals(for: Self.tflTubeLineIDs)
        case .nycSubway:
            try await fetchMTASubwayArrivals()
        case .lirr:
            try await fetchMTACommuterRailArrivals(feedPath: Self.lirrFeedPath, lineName: "LIRR")
        case .metroNorth:
            try await fetchMTACommuterRailArrivals(feedPath: Self.metroNorthFeedPath, lineName: "Metro-North")
        default:
            throw MetroLiveError.unsupportedProvider
        }
    }

    private func fetchTfLLineStatuses() async throws -> [MetroLineLiveStatus] {
        let url = try tflURL(path: "/Line/Mode/tube/Status")
        let lines: [TfLLineStatusResponse] = try await fetchJSON(url: url)

        return lines.map { line in
            let primaryStatus = line.lineStatuses.first
            let statusText = primaryStatus?.statusSeverityDescription ?? "Unknown"
            return MetroLineLiveStatus(
                id: line.id,
                lineID: line.id,
                lineName: line.name,
                statusText: statusText,
                reason: primaryStatus?.reason,
                status: trainStatus(for: statusText)
            )
        }
        .sorted { $0.lineName < $1.lineName }
    }

    private func fetchTfLArrivals(for lineIDs: [String]) async throws -> [MetroArrivalPrediction] {
        guard !lineIDs.isEmpty else { return [] }
        let joinedIDs = lineIDs.joined(separator: ",")
        let url = try tflURL(path: "/Line/\(joinedIDs)/Arrivals")
        let predictions: [TfLArrivalPrediction] = try await fetchJSON(url: url)

        return predictions
            .filter { $0.timeToStation >= 0 }
            .sorted { $0.timeToStation < $1.timeToStation }
            .prefix(12)
            .map { prediction in
                MetroArrivalPrediction(
                    id: prediction.id,
                    lineName: prediction.lineName,
                    stationName: prediction.stationName,
                    destinationName: prediction.destinationName,
                    platformName: prediction.platformName,
                    timeToStation: prediction.timeToStation
                )
            }
    }

    private func fetchMTASubwayStatuses() async throws -> [MetroLineLiveStatus] {
        let routeIDs = Self.mtaSubwayRouteIDs
        var statusByRoute = Dictionary(
            uniqueKeysWithValues: routeIDs.map { routeID in
                (
                    routeID,
                    MetroLineLiveStatus(
                        id: "mta-\(routeID)",
                        lineID: routeID,
                        lineName: "\(routeID) train",
                        statusText: "Good Service",
                        reason: nil,
                        status: .onTime
                    )
                )
            }
        )

        let entities = try await fetchMTAFeed(path: Self.mtaAlertsFeedPath)
        for alert in entities.compactMap(\.alert) {
            let reason = alert.header.isEmpty ? alert.description : alert.header
            for routeID in alert.affectedRouteIDs where statusByRoute[routeID] != nil {
                statusByRoute[routeID] = MetroLineLiveStatus(
                    id: "mta-\(routeID)",
                    lineID: routeID,
                    lineName: "\(routeID) train",
                    statusText: alert.effect,
                    reason: reason,
                    status: trainStatus(for: alert.effect)
                )
            }
        }

        return routeIDs.compactMap { statusByRoute[$0] }
    }

    private func fetchMTASubwayArrivals() async throws -> [MetroArrivalPrediction] {
        let now = Int(Date().timeIntervalSince1970)
        let routeIDs = Set(Self.mtaSubwayRouteIDs)
        var predictions: [MetroArrivalPrediction] = []

        for feedPath in Self.mtaSubwayFeeds {
            let entities = try await fetchMTAFeed(path: feedPath)
            for tripUpdate in entities.compactMap(\.tripUpdate) {
                let routeID = tripUpdate.routeID.uppercased()
                guard routeIDs.contains(routeID) else { continue }

                let destination = tripUpdate.stopTimeUpdates.last
                    .map { "to \(stationName(forMTAStopID: $0.stopID))" } ?? "train"

                for update in tripUpdate.stopTimeUpdates {
                    guard let eventTime = update.eventTime, eventTime >= now else { continue }
                    let secondsUntilArrival = eventTime - now
                    guard secondsUntilArrival <= 60 * 60 * 2 else { continue }

                    predictions.append(
                        MetroArrivalPrediction(
                            id: "\(feedPath):\(tripUpdate.tripID):\(update.stopID):\(eventTime)",
                            lineName: routeID,
                            stationName: stationName(forMTAStopID: update.stopID),
                            destinationName: "\(routeID) \(destination)",
                            platformName: update.stopID,
                            timeToStation: secondsUntilArrival
                        )
                    )
                }
            }
        }

        return Array(predictions.sorted { $0.timeToStation < $1.timeToStation }.prefix(12))
    }

    private func fetchMTACommuterRailStatuses(feedPath: String, prefix: String) async throws -> [MetroLineLiveStatus] {
        let entities = try await fetchMTAFeed(path: Self.mtaAlertsFeedPath)
        var alertsByRoute: [String: MTARealtimeAlert] = [:]
        for alert in entities.compactMap(\.alert) {
            for routeID in alert.affectedRouteIDs {
                alertsByRoute[routeID] = alert
            }
        }

        let entities2 = try await fetchMTAFeed(path: feedPath)
        var routeIDs: Set<String> = []
        for entity in entities2 {
            if let tripUpdate = entity.tripUpdate {
                routeIDs.insert(tripUpdate.routeID)
            }
        }
        if routeIDs.isEmpty { routeIDs = ["Main"] }

        return routeIDs.sorted().map { routeID in
            if let alert = alertsByRoute[routeID] {
                let reason = alert.header.isEmpty ? alert.description : alert.header
                return MetroLineLiveStatus(
                    id: "\(prefix)-\(routeID)",
                    lineID: routeID,
                    lineName: routeID,
                    statusText: alert.effect,
                    reason: reason,
                    status: trainStatus(for: alert.effect)
                )
            }
            return MetroLineLiveStatus(
                id: "\(prefix)-\(routeID)",
                lineID: routeID,
                lineName: routeID,
                statusText: "Good Service",
                reason: nil,
                status: .onTime
            )
        }
    }

    private func fetchMTACommuterRailArrivals(feedPath: String, lineName: String) async throws -> [MetroArrivalPrediction] {
        let now = Int(Date().timeIntervalSince1970)
        let entities = try await fetchMTAFeed(path: feedPath)
        var predictions: [MetroArrivalPrediction] = []

        for entity in entities {
            guard let tripUpdate = entity.tripUpdate else { continue }
            let destination = tripUpdate.stopTimeUpdates.last
                .map { "to Stop \($0.stopID)" } ?? lineName

            for update in tripUpdate.stopTimeUpdates {
                guard let eventTime = update.eventTime, eventTime >= now else { continue }
                let secondsUntilArrival = eventTime - now
                guard secondsUntilArrival <= 60 * 60 * 3 else { continue }

                predictions.append(
                    MetroArrivalPrediction(
                        id: "\(feedPath):\(tripUpdate.tripID):\(update.stopID):\(eventTime)",
                        lineName: lineName,
                        stationName: "Stop \(update.stopID)",
                        destinationName: destination,
                        platformName: update.stopID,
                        timeToStation: secondsUntilArrival
                    )
                )
            }
        }

        return Array(predictions.sorted { $0.timeToStation < $1.timeToStation }.prefix(12))
    }

    private func fetchMTAFeed(path: String) async throws -> [MTARealtimeEntity] {
        let now = Date()
        if let cached = mtaFeedCache[path], now.timeIntervalSince(cached.fetchedAt) < Self.mtaCacheInterval {
            return cached.entities
        }

        guard let url = URL(string: "\(Self.mtaSubwayBaseURL)/\(path)") else {
            throw MetroLiveError.invalidURL
        }

        var request = URLRequest(url: url)
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "MTA_API_KEY") as? String, !apiKey.isEmpty {
            request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MetroLiveError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw MetroLiveError.httpError(httpResponse.statusCode)
        }

        let entities = try MTARealtimeParser.parse(data)
        mtaFeedCache[path] = (now, entities)
        return entities
    }

    private func stationName(forMTAStopID stopID: String) -> String {
        let trimmedStopID = stopID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedStopID.isEmpty else { return "Unknown stop" }

        let directionSuffixes = CharacterSet(charactersIn: "NS")
        let baseID = trimmedStopID.trimmingCharacters(in: directionSuffixes)
        if baseID != trimmedStopID {
            return "Stop \(baseID)"
        }
        return "Stop \(trimmedStopID)"
    }

    private func fetchJSON<T: Decodable>(url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MetroLiveError.invalidResponse
        }
        guard httpResponse.statusCode == 200 else {
            throw MetroLiveError.httpError(httpResponse.statusCode)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func tflURL(path: String) throws -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.tfl.gov.uk"
        components.path = path

        var queryItems: [URLQueryItem] = []
        if let appID = Bundle.main.object(forInfoDictionaryKey: "TFL_APP_ID") as? String, !appID.isEmpty {
            queryItems.append(URLQueryItem(name: "app_id", value: appID))
        }
        if let appKey = Bundle.main.object(forInfoDictionaryKey: "TFL_APP_KEY") as? String, !appKey.isEmpty {
            queryItems.append(URLQueryItem(name: "app_key", value: appKey))
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw MetroLiveError.invalidURL
        }
        return url
    }

    private func trainStatus(for statusText: String) -> TrainStatus {
        let lowered = statusText.lowercased()
        if lowered.contains("good service") || lowered.contains("part closure") || lowered.contains("no effect") {
            return .onTime
        }
        if lowered.contains("severe") || lowered.contains("suspended") || lowered.contains("closed") || lowered.contains("no service") {
            return .severeDelay
        }
        return .minorDelay
    }
}

private struct TfLLineStatusResponse: Decodable {
    let id: String
    let name: String
    let lineStatuses: [TfLLineStatus]
}

private struct TfLLineStatus: Decodable {
    let statusSeverityDescription: String
    let reason: String?
}

private struct TfLArrivalPrediction: Decodable {
    let id: String
    let lineName: String
    let stationName: String
    let destinationName: String
    let platformName: String?
    let timeToStation: Int
}
