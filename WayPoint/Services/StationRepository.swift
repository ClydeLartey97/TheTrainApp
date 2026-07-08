//
//  StationRepository.swift
//  WayPoint
//
//  Created by Clyde Lartey on 11/04/2026.
//

import CoreLocation
import Foundation

nonisolated struct Station: Identifiable, Hashable, Codable {
    var id: String { crs }
    let name: String
    let crs: String // Computer Reservation System code
    var latitude: Double?
    var longitude: Double?

    init(name: String, crs: String, latitude: Double? = nil, longitude: Double? = nil) {
        self.name = name
        self.crs = crs
        self.latitude = latitude
        self.longitude = longitude
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct StationRepository {
    static let shared = StationRepository()

    /// The full national corpus, loaded once from the bundled dataset
    /// (2,600+ stations with coordinates). Falls back to a minimal built-in
    /// list if the resource ever fails to decode, so search never goes dark.
    let stations: [Station]

    init(stations: [Station]? = nil) {
        self.stations = stations ?? Self.loadBundledStations() ?? Self.fallbackStations
    }

    /// Common spoken names that differ from the official station name (Phase 6).
    /// Keys are matched with the same normalization as station names, so
    /// apostrophes and spacing don't matter ("King's Cross" == "kings cross").
    static let aliases: [String: String] = [
        "kings cross": "KGX",
        "kings x": "KGX",
        "london kx": "KGX",
        "st pancras": "STP",
        "saint pancras": "STP",
        "new street": "BHM",
        "birmingham new st": "BHM",
        "piccadilly": "MAN",
        "manchester picc": "MAN",
        "lime street": "LIV",
        "temple meads": "BRI",
        "waverley": "EDB",
        "paddington": "PAD",
        "waterloo": "WAT",
        "victoria": "VIC",
        "euston": "EUS",
        "liverpool street": "LST",
        "charing cross": "CHX",
        "marylebone": "MYB",
        "cannon street": "CST",
        "fenchurch street": "FST",
        "blackfriars": "BFR",
        "gatwick": "GTW",
        "heathrow": "HWV",
        "stansted": "SSD",
    ]

    /// Alias entries resolved against the corpus, normalized once.
    private static let normalizedAliases: [(alias: String, crs: String)] = {
        aliases.map { (Self.normalize($0.key), $0.value.uppercased()) }
    }()

    /// The stations most people search for, surfaced first in the map's
    /// zoomed-out view so the country view isn't a wall of 2,600 pins.
    static let majorCRSCodes: Set<String> = [
        "KGX", "EUS", "PAD", "WAT", "VIC", "LST", "STP", "LBG", "CHX", "MYB",
        "BHM", "MAN", "MCV", "LDS", "SHF", "BRI", "EDB", "GLC", "GLQ", "LIV",
        "NCL", "YRK", "NOT", "LEI", "CBG", "NRW", "PBO", "CDF", "SWA", "PLY",
        "EXD", "SOU", "PMH", "BTN", "BMH", "BTH", "RDG", "OXF", "COV", "DBY",
        "PRE", "CAR", "ABD", "DEE", "INV", "STG", "GTW", "SSD", "LTN", "HUL",
        "MBR", "DON", "CRE", "SWI", "IPS", "COL", "WVH", "DHM", "DAR", "LAN",
    ]

    /// Search stations by name fragment, CRS prefix, or alias (case-insensitive)
    func search(query: String) -> [Station] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let lowered = normalized(trimmed)
        let uppercased = trimmed.uppercased()

        let aliasCRSMatches = Set(
            Self.normalizedAliases
                .filter { $0.alias.hasPrefix(lowered) || $0.alias == lowered }
                .map(\.crs)
        )

        return stations.filter { station in
            normalized(station.name).contains(lowered)
                || station.crs.hasPrefix(uppercased)
                || aliasCRSMatches.contains(station.crs)
        }
        .sorted { a, b in
            let aCRS = a.crs == uppercased
            let bCRS = b.crs == uppercased
            if aCRS != bCRS { return aCRS }

            let aStarts = normalized(a.name).hasPrefix(lowered)
            let bStarts = normalized(b.name).hasPrefix(lowered)
            if aStarts != bStarts { return aStarts }
            return a.name < b.name
        }
    }

    func resolveStation(query: String) -> Station? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let station = findStation(crs: trimmed) {
            return station
        }

        if let station = findStation(named: trimmed) {
            return station
        }

        // Exact alias hit ("Kings Cross" → KGX) resolves without ambiguity.
        let lowered = normalized(trimmed)
        if let aliasCRS = Self.normalizedAliases.first(where: { $0.alias == lowered })?.crs,
           let station = findStation(crs: aliasCRS) {
            return station
        }

        let matches = search(query: trimmed)
        return matches.count == 1 ? matches[0] : nil
    }

    /// Look up a station by exact name (case-insensitive)
    func findStation(named name: String) -> Station? {
        let normalizedName = normalized(name)
        return stations.first { normalized($0.name) == normalizedName }
    }

    /// Look up a station by CRS code
    func findStation(crs: String) -> Station? {
        let normalizedCRS = crs.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return stations.first { $0.crs.uppercased() == normalizedCRS }
    }

    /// Stations inside a lat/lon window, majors first, capped for map display.
    func stations(
        latitude: ClosedRange<Double>,
        longitude: ClosedRange<Double>,
        majorsOnly: Bool,
        limit: Int
    ) -> [Station] {
        var visible = stations.filter { station in
            guard let lat = station.latitude, let lon = station.longitude else { return false }
            return latitude.contains(lat) && longitude.contains(lon)
        }
        if majorsOnly {
            visible = visible.filter { Self.majorCRSCodes.contains($0.crs) }
        } else {
            // Majors first so they survive the cap at medium zoom.
            visible.sort { a, b in
                let aMajor = Self.majorCRSCodes.contains(a.crs)
                let bMajor = Self.majorCRSCodes.contains(b.crs)
                if aMajor != bMajor { return aMajor }
                return a.name < b.name
            }
        }
        return Array(visible.prefix(limit))
    }

    private func normalized(_ value: String) -> String {
        Self.normalize(value)
    }

    static func normalize(_ value: String) -> String {
        value
            .lowercased()
            .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
            .filter { $0.isLetter || $0.isNumber }
    }

    // MARK: - Data loading

    private struct BundledStation: Decodable {
        let name: String
        let crs: String
        let lat: Double
        let lon: Double
    }

    private static func loadBundledStations() -> [Station]? {
        guard let url = Bundle.main.url(forResource: "uk-stations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([BundledStation].self, from: data),
              !decoded.isEmpty
        else { return nil }

        return decoded.map {
            Station(name: $0.name, crs: $0.crs.uppercased(), latitude: $0.lat, longitude: $0.lon)
        }
    }

    /// Minimal safety net if the bundled dataset can't be read.
    private static let fallbackStations: [Station] = [
        Station(name: "London Paddington", crs: "PAD", latitude: 51.5154, longitude: -0.1755),
        Station(name: "London Waterloo", crs: "WAT", latitude: 51.5031, longitude: -0.1132),
        Station(name: "London Victoria", crs: "VIC", latitude: 51.4952, longitude: -0.1441),
        Station(name: "London Euston", crs: "EUS", latitude: 51.5282, longitude: -0.1337),
        Station(name: "London Kings Cross", crs: "KGX", latitude: 51.5308, longitude: -0.1238),
        Station(name: "London St Pancras International", crs: "STP", latitude: 51.5310, longitude: -0.1260),
        Station(name: "London Liverpool Street", crs: "LST", latitude: 51.5178, longitude: -0.0817),
        Station(name: "London Bridge", crs: "LBG", latitude: 51.5049, longitude: -0.0863),
        Station(name: "Birmingham New Street", crs: "BHM", latitude: 52.4778, longitude: -1.8985),
        Station(name: "Manchester Piccadilly", crs: "MAN", latitude: 53.4774, longitude: -2.2309),
        Station(name: "Leeds", crs: "LDS", latitude: 53.7951, longitude: -1.5484),
        Station(name: "Bristol Temple Meads", crs: "BRI", latitude: 51.4494, longitude: -2.5813),
        Station(name: "Edinburgh Waverley", crs: "EDB", latitude: 55.9520, longitude: -3.1890),
        Station(name: "Glasgow Central", crs: "GLC", latitude: 55.8592, longitude: -4.2576),
        Station(name: "Liverpool Lime Street", crs: "LIV", latitude: 53.4078, longitude: -2.9779),
        Station(name: "Newcastle", crs: "NCL", latitude: 54.9683, longitude: -1.6178),
        Station(name: "York", crs: "YRK", latitude: 53.9583, longitude: -1.0803),
        Station(name: "Cardiff Central", crs: "CDF", latitude: 51.4761, longitude: -3.1794),
        Station(name: "Reading", crs: "RDG", latitude: 51.4586, longitude: -0.9714),
        Station(name: "Oxford", crs: "OXF", latitude: 51.7534, longitude: -1.2700),
        Station(name: "Gatwick Airport", crs: "GTW", latitude: 51.1564, longitude: -0.1611),
    ]
}
