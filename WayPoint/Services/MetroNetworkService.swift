//
//  MetroNetworkService.swift
//  WayPoint
//
//  Created by Codex on 22/04/2026.
//

import CoreLocation
import Foundation
import SwiftUI

actor MetroNetworkService {
    static let shared = MetroNetworkService()

    private let session: URLSession
    private var cache: [MetroSystem: MetroNetworkSnapshot] = [:]

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchNetwork(for system: MetroSystem) async throws -> MetroNetworkSnapshot {
        if let cached = cache[system] {
            return cached
        }

        let snapshot: MetroNetworkSnapshot
        switch system {
        case .londonUnderground:
            snapshot = try await fetchTfLTubeNetwork()
        default:
            let (stations, lines) = await MainActor.run { (system.stations, system.lines) }
            snapshot = MetroNetworkSnapshot(
                system: system,
                stations: stations,
                lines: lines,
                isOfficial: false,
                fetchedAt: nil
            )
        }

        cache[system] = snapshot
        return snapshot
    }

    private func fetchTfLTubeNetwork() async throws -> MetroNetworkSnapshot {
        let lineIDs = [
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

        var stationBuilders: [String: StationBuilder] = [:]
        var lines: [MetroLine] = []

        for lineID in lineIDs {
            let response: TfLRouteSequenceResponse = try await fetchJSON(
                url: tflURL(path: "/Line/\(lineID)/Route/Sequence/all")
            )
            let lineName = normalizedLineName(response.lineName)
            let color = tubeColor(for: response.lineID)

            for (index, sequence) in response.stopPointSequences.enumerated() {
                let stops = sequence.stopPoint.filter { $0.lat != 0 && $0.lon != 0 }
                guard stops.count > 1 else { continue }

                let stationNames = stops.map { normalizedStationName($0.name) }
                let coordinates = stops.map { CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon) }

                lines.append(
                    MetroLine(
                        id: "\(response.lineID)-\(sequence.direction ?? "route")-\(sequence.branchID ?? index)-\(index)",
                        name: lineName,
                        color: color,
                        stationNames: stationNames,
                        coordinates: coordinates
                    )
                )

                for stop in stops {
                    let stationName = normalizedStationName(stop.name)
                    let existing = stationBuilders[stop.id]
                    stationBuilders[stop.id] = StationBuilder(
                        id: stop.id,
                        name: stationName,
                        coordinate: CLLocationCoordinate2D(latitude: stop.lat, longitude: stop.lon),
                        lineIDs: Array(Set((existing?.lineIDs ?? []) + [response.lineID])).sorted()
                    )
                }
            }
        }

        let stations = stationBuilders.values
            .map { builder in
                MetroStation(
                    id: builder.id,
                    name: builder.name,
                    coordinate: builder.coordinate,
                    lineIDs: builder.lineIDs
                )
            }
            .sorted { $0.name < $1.name }

        return MetroNetworkSnapshot(
            system: .londonUnderground,
            stations: stations,
            lines: lines,
            isOfficial: true,
            fetchedAt: .now
        )
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
        if let appKey = Bundle.main.object(forInfoDictionaryKey: "TFL_APP_KEY") as? String, !appKey.isEmpty {
            queryItems.append(URLQueryItem(name: "app_key", value: appKey))
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw MetroLiveError.invalidURL
        }
        return url
    }

    private func normalizedStationName(_ name: String) -> String {
        name
            .replacingOccurrences(of: " Underground Station", with: "")
            .replacingOccurrences(of: " Underground", with: "")
            .replacingOccurrences(of: " Rail Station", with: "")
            .replacingOccurrences(of: " DLR Station", with: "")
    }

    private func normalizedLineName(_ name: String) -> String {
        name.lowercased().contains("line") ? name : "\(name) line"
    }

    private func tubeColor(for lineID: String) -> Color {
        switch lineID {
        case "bakerloo":
            Color(red: 0.70, green: 0.39, blue: 0.18)
        case "central":
            Color(red: 0.86, green: 0.10, blue: 0.16)
        case "circle":
            Color(red: 1.0, green: 0.83, blue: 0.12)
        case "district":
            Color(red: 0.00, green: 0.45, blue: 0.22)
        case "hammersmith-city":
            Color(red: 0.92, green: 0.52, blue: 0.66)
        case "jubilee":
            Color(red: 0.50, green: 0.56, blue: 0.60)
        case "metropolitan":
            Color(red: 0.56, green: 0.00, blue: 0.32)
        case "northern":
            Color.black
        case "piccadilly":
            Color(red: 0.00, green: 0.10, blue: 0.66)
        case "victoria":
            Color(red: 0.05, green: 0.46, blue: 0.80)
        case "waterloo-city":
            Color(red: 0.48, green: 0.82, blue: 0.78)
        default:
            Color(red: 0.27, green: 0.51, blue: 0.94)
        }
    }
}

nonisolated private struct StationBuilder {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let lineIDs: [String]
}

nonisolated private struct TfLRouteSequenceResponse: Decodable {
    let lineID: String
    let lineName: String
    let stopPointSequences: [TfLStopPointSequence]

    enum CodingKeys: String, CodingKey {
        case lineID = "lineId"
        case lineName
        case stopPointSequences
    }
}

nonisolated private struct TfLStopPointSequence: Decodable {
    let branchID: Int?
    let direction: String?
    let stopPoint: [TfLRouteStop]

    enum CodingKeys: String, CodingKey {
        case branchID = "branchId"
        case direction
        case stopPoint
    }
}

nonisolated private struct TfLRouteStop: Decodable {
    let id: String
    let name: String
    let lat: Double
    let lon: Double
}
