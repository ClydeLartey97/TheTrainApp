//
//  MetroSystem.swift
//  WayPoint
//
//  Created by Codex on 22/04/2026.
//

import CoreLocation
import MapKit
import SwiftUI

struct MetroStation: Identifiable, Equatable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let lineIDs: [String]

    static func == (lhs: MetroStation, rhs: MetroStation) -> Bool {
        lhs.id == rhs.id
    }
}

struct MetroLine: Identifiable {
    let id: String
    let name: String
    let color: Color
    let stationNames: [String]
    let coordinates: [CLLocationCoordinate2D]
}

struct MetroNetworkSnapshot {
    let system: MetroSystem
    let stations: [MetroStation]
    let lines: [MetroLine]
    let isOfficial: Bool
    let fetchedAt: Date?
}

struct MetroVehicle: Identifiable {
    let id: String
    let label: String
    let lineID: String
    let status: TrainStatus
    let coordinate: CLLocationCoordinate2D
}

struct MetroRouteStep: Identifiable {
    let id = UUID()
    let lineName: String
    let color: Color
    let fromName: String
    let toName: String
    let stopCount: Int
}

struct MetroRoutePlan {
    let fromName: String
    let toName: String
    let minutes: Int
    let steps: [MetroRouteStep]

    var summary: String {
        "\(minutes) min · \(steps.count == 1 ? "Direct" : "\(steps.count - 1) transfer\(steps.count == 2 ? "" : "s")")"
    }
}

enum MetroSystem: String, CaseIterable, Identifiable {
    case londonUnderground
    case nycSubway
    case lirr
    case metroNorth
    case parisMetro
    case berlinUBahn
    case madridMetro
    case barcelonaMetro
    case milanMetro
    case romeMetro
    case amsterdamMetro
    case brusselsMetro
    case viennaUBahn
    case pragueMetro
    case copenhagenMetro
    case stockholmMetro
    case osloMetro
    case helsinkiMetro
    case athensMetro
    case lisbonMetro
    case washingtonMetro
    case chicagoL
    case bostonSubway
    case bart
    case laMetro
    case philadelphiaMetro
    case marta
    case miamiMetrorail
    case seattleLink

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .londonUnderground: "London Underground"
        case .nycSubway: "New York Subway"
        case .lirr: "Long Island Rail Road"
        case .metroNorth: "Metro-North Railroad"
        case .parisMetro: "Paris Metro"
        case .berlinUBahn: "Berlin U-Bahn"
        case .madridMetro: "Metro de Madrid"
        case .barcelonaMetro: "Barcelona Metro"
        case .milanMetro: "Milan Metro"
        case .romeMetro: "Rome Metro"
        case .amsterdamMetro: "Amsterdam Metro"
        case .brusselsMetro: "Brussels Metro"
        case .viennaUBahn: "Vienna U-Bahn"
        case .pragueMetro: "Prague Metro"
        case .copenhagenMetro: "Copenhagen Metro"
        case .stockholmMetro: "Stockholm Metro"
        case .osloMetro: "Oslo Metro"
        case .helsinkiMetro: "Helsinki Metro"
        case .athensMetro: "Athens Metro"
        case .lisbonMetro: "Lisbon Metro"
        case .washingtonMetro: "Washington Metro"
        case .chicagoL: "Chicago L"
        case .bostonSubway: "Boston Subway"
        case .bart: "BART"
        case .laMetro: "LA Metro"
        case .philadelphiaMetro: "Philadelphia Metro"
        case .marta: "MARTA"
        case .miamiMetrorail: "Miami Metrorail"
        case .seattleLink: "Seattle Link"
        }
    }

    var localModeName: String {
        switch self {
        case .londonUnderground:
            "Underground"
        case .nycSubway, .bostonSubway:
            "Subway"
        case .lirr, .metroNorth:
            "Commuter Rail"
        case .berlinUBahn, .viennaUBahn:
            "U-Bahn"
        case .chicagoL:
            "L"
        default:
            "Metro"
        }
    }

    var cityName: String {
        switch self {
        case .londonUnderground: "London"
        case .nycSubway: "New York"
        case .lirr: "Long Island, NY"
        case .metroNorth: "New York & Connecticut"
        case .parisMetro: "Paris"
        case .berlinUBahn: "Berlin"
        case .madridMetro: "Madrid"
        case .barcelonaMetro: "Barcelona"
        case .milanMetro: "Milan"
        case .romeMetro: "Rome"
        case .amsterdamMetro: "Amsterdam"
        case .brusselsMetro: "Brussels"
        case .viennaUBahn: "Vienna"
        case .pragueMetro: "Prague"
        case .copenhagenMetro: "Copenhagen"
        case .stockholmMetro: "Stockholm"
        case .osloMetro: "Oslo"
        case .helsinkiMetro: "Helsinki"
        case .athensMetro: "Athens"
        case .lisbonMetro: "Lisbon"
        case .washingtonMetro: "Washington, DC"
        case .chicagoL: "Chicago"
        case .bostonSubway: "Boston"
        case .bart: "San Francisco Bay Area"
        case .laMetro: "Los Angeles"
        case .philadelphiaMetro: "Philadelphia"
        case .marta: "Atlanta"
        case .miamiMetrorail: "Miami"
        case .seattleLink: "Seattle"
        }
    }

    var isMapReady: Bool {
        self == .londonUnderground || self == .nycSubway
    }

    var isRoutePlannerReady: Bool {
        isMapReady
    }

    var isLiveAPIReady: Bool {
        self == .londonUnderground || self == .nycSubway || self == .lirr || self == .metroNorth
    }

    var defaultRegion: MKCoordinateRegion {
        switch self {
        case .londonUnderground:
            region(51.5072, -0.1276, 0.36, 0.42)
        case .nycSubway:
            region(40.7359, -73.9911, 0.38, 0.36)
        case .lirr:
            region(40.7282, -73.4800, 0.55, 1.10)
        case .metroNorth:
            region(41.1200, -73.8000, 0.75, 1.20)
        case .parisMetro:
            region(48.8566, 2.3522, 0.32, 0.36)
        case .berlinUBahn:
            region(52.5200, 13.4050, 0.38, 0.44)
        case .madridMetro:
            region(40.4168, -3.7038, 0.35, 0.42)
        case .barcelonaMetro:
            region(41.3874, 2.1686, 0.28, 0.34)
        case .milanMetro:
            region(45.4642, 9.1900, 0.34, 0.38)
        case .romeMetro:
            region(41.9028, 12.4964, 0.35, 0.42)
        case .amsterdamMetro:
            region(52.3676, 4.9041, 0.30, 0.34)
        case .brusselsMetro:
            region(50.8503, 4.3517, 0.30, 0.34)
        case .viennaUBahn:
            region(48.2082, 16.3738, 0.34, 0.42)
        case .pragueMetro:
            region(50.0755, 14.4378, 0.34, 0.42)
        case .copenhagenMetro:
            region(55.6761, 12.5683, 0.32, 0.38)
        case .stockholmMetro:
            region(59.3293, 18.0686, 0.42, 0.50)
        case .osloMetro:
            region(59.9139, 10.7522, 0.42, 0.50)
        case .helsinkiMetro:
            region(60.1699, 24.9384, 0.35, 0.46)
        case .athensMetro:
            region(37.9838, 23.7275, 0.38, 0.46)
        case .lisbonMetro:
            region(38.7223, -9.1393, 0.30, 0.38)
        case .washingtonMetro:
            region(38.9072, -77.0369, 0.44, 0.50)
        case .chicagoL:
            region(41.8781, -87.6298, 0.46, 0.42)
        case .bostonSubway:
            region(42.3601, -71.0589, 0.34, 0.38)
        case .bart:
            region(37.7749, -122.4194, 0.75, 0.85)
        case .laMetro:
            region(34.0522, -118.2437, 0.65, 0.75)
        case .philadelphiaMetro:
            region(39.9526, -75.1652, 0.34, 0.38)
        case .marta:
            region(33.7490, -84.3880, 0.45, 0.50)
        case .miamiMetrorail:
            region(25.7617, -80.1918, 0.38, 0.44)
        case .seattleLink:
            region(47.6062, -122.3321, 0.48, 0.42)
        }
    }

    var bookingURL: URL? {
        switch self {
        case .londonUnderground:
            URL(string: "https://tfl.gov.uk/plan-a-journey/")
        case .nycSubway:
            URL(string: "https://new.mta.info/")
        case .lirr:
            URL(string: "https://www.mta.info/lirr")
        case .metroNorth:
            URL(string: "https://www.mta.info/mnr")
        case .parisMetro:
            URL(string: "https://www.ratp.fr/en/itineraires")
        case .berlinUBahn:
            URL(string: "https://www.bvg.de/en/connections/connection-search")
        case .madridMetro:
            URL(string: "https://www.metromadrid.es/en")
        case .barcelonaMetro:
            URL(string: "https://www.tmb.cat/en/barcelona")
        case .milanMetro:
            URL(string: "https://www.atm.it/en/")
        case .romeMetro:
            URL(string: "https://www.atac.roma.it/en")
        case .amsterdamMetro:
            URL(string: "https://www.gvb.nl/en")
        case .brusselsMetro:
            URL(string: "https://www.stib-mivb.be/index.htm?l=en")
        case .viennaUBahn:
            URL(string: "https://www.wienerlinien.at/web/wl-en")
        case .pragueMetro:
            URL(string: "https://www.dpp.cz/en")
        case .copenhagenMetro:
            URL(string: "https://intl.m.dk/")
        case .stockholmMetro:
            URL(string: "https://sl.se/en/in-english")
        case .osloMetro:
            URL(string: "https://ruter.no/en/")
        case .helsinkiMetro:
            URL(string: "https://www.hsl.fi/en")
        case .athensMetro:
            URL(string: "https://www.stasy.gr/en/")
        case .lisbonMetro:
            URL(string: "https://www.metrolisboa.pt/en/")
        case .washingtonMetro:
            URL(string: "https://www.wmata.com/")
        case .chicagoL:
            URL(string: "https://www.transitchicago.com/")
        case .bostonSubway:
            URL(string: "https://www.mbta.com/")
        case .bart:
            URL(string: "https://www.bart.gov/")
        case .laMetro:
            URL(string: "https://www.metro.net/")
        case .philadelphiaMetro:
            URL(string: "https://www.septa.org/")
        case .marta:
            URL(string: "https://www.itsmarta.com/")
        case .miamiMetrorail:
            URL(string: "https://www.miamidade.gov/global/transportation/metrorail.page")
        case .seattleLink:
            URL(string: "https://www.soundtransit.org/")
        }
    }

    var stations: [MetroStation] {
        switch self {
        case .londonUnderground:
            londonStations
        case .nycSubway:
            nycStations
        default:
            []
        }
    }

    var lines: [MetroLine] {
        switch self {
        case .londonUnderground:
            londonLines
        case .nycSubway:
            nycLines
        default:
            []
        }
    }

    var vehicles: [MetroVehicle] {
        []
    }

    static func preferred(for network: RailNetwork) -> MetroSystem {
        switch network {
        case .ukNationalRail, .eurostar:
            .londonUnderground
        case .longIslandRailRoad:
            .lirr
        case .metroNorthRailroad:
            .metroNorth
        case .njTransit:
            .nycSubway
        case .sncfConnect:
            .parisMetro
        case .deutscheBahn:
            .berlinUBahn
        case .renfe:
            .madridMetro
        case .trenitalia, .italo:
            .romeMetro
        case .nsRail:
            .amsterdamMetro
        case .sncb:
            .brusselsMetro
        case .oebb:
            .viennaUBahn
        case .ceskeDrahy:
            .pragueMetro
        case .dsb:
            .copenhagenMetro
        case .sj:
            .stockholmMetro
        case .vy:
            .osloMetro
        case .vr:
            .helsinkiMetro
        case .cpPortugal:
            .lisbonMetro
        case .amtrak, .marcTrain, .virginiaRailwayExpress:
            .washingtonMetro
        case .metra:
            .chicagoL
        case .mbtaCommuterRail:
            .bostonSubway
        case .caltrain, .capitolCorridor, .aceRail:
            .bart
        case .septaRegionalRail:
            .philadelphiaMetro
        case .brightline, .triRail:
            .miamiMetrorail
        case .sounder:
            .seattleLink
        default:
            .londonUnderground
        }
    }

    func station(for id: String?) -> MetroStation? {
        guard let id else { return nil }
        return stations.first { $0.id == id }
    }

    func fastestRoute(from start: MetroStation, to end: MetroStation) -> MetroRoutePlan? {
        guard isRoutePlannerReady, start != end else { return nil }
        return MetroRoutePlanner.fastestRoute(lines: lines, from: start, to: end)
    }

    private var londonStations: [MetroStation] {
        [
            station("notting-hill-gate", "Notting Hill Gate", 51.5094, -0.1967, ["central"]),
            station("bond-street", "Bond Street", 51.5142, -0.1494, ["central", "jubilee"]),
            station("oxford-circus", "Oxford Circus", 51.5152, -0.1419, ["central", "victoria"]),
            station("tottenham-court-road", "Tottenham Court Road", 51.5165, -0.1302, ["central"]),
            station("holborn", "Holborn", 51.5174, -0.1200, ["central"]),
            station("liverpool-street", "Liverpool Street", 51.5178, -0.0823, ["central"]),
            station("stratford", "Stratford", 51.5416, -0.0038, ["central", "jubilee"]),
            station("kings-cross", "King's Cross St Pancras", 51.5308, -0.1238, ["victoria"]),
            station("warren-street", "Warren Street", 51.5247, -0.1384, ["victoria"]),
            station("victoria", "Victoria", 51.4965, -0.1447, ["victoria"]),
            station("stockwell", "Stockwell", 51.4723, -0.1227, ["victoria"]),
            station("brixton", "Brixton", 51.4627, -0.1145, ["victoria"]),
            station("baker-street", "Baker Street", 51.5226, -0.1571, ["jubilee"]),
            station("westminster", "Westminster", 51.5010, -0.1246, ["jubilee"]),
            station("london-bridge", "London Bridge", 51.5055, -0.0865, ["jubilee"]),
            station("canary-wharf", "Canary Wharf", 51.5036, -0.0195, ["jubilee"]),
        ]
    }

    private var londonLines: [MetroLine] {
        [
            MetroLine(
                id: "central",
                name: "Central line",
                color: Color(red: 0.86, green: 0.10, blue: 0.16),
                stationNames: ["Notting Hill Gate", "Bond Street", "Oxford Circus", "Tottenham Court Road", "Holborn", "Liverpool Street", "Stratford"],
                coordinates: coordinates(["notting-hill-gate", "bond-street", "oxford-circus", "tottenham-court-road", "holborn", "liverpool-street", "stratford"])
            ),
            MetroLine(
                id: "victoria",
                name: "Victoria line",
                color: Color(red: 0.05, green: 0.46, blue: 0.80),
                stationNames: ["King's Cross St Pancras", "Warren Street", "Oxford Circus", "Victoria", "Stockwell", "Brixton"],
                coordinates: coordinates(["kings-cross", "warren-street", "oxford-circus", "victoria", "stockwell", "brixton"])
            ),
            MetroLine(
                id: "jubilee",
                name: "Jubilee line",
                color: Color(red: 0.50, green: 0.56, blue: 0.60),
                stationNames: ["Baker Street", "Bond Street", "Westminster", "London Bridge", "Canary Wharf", "Stratford"],
                coordinates: coordinates(["baker-street", "bond-street", "westminster", "london-bridge", "canary-wharf", "stratford"])
            ),
        ]
    }

    private var nycStations: [MetroStation] {
        [
            station("times-square", "Times Sq-42 St", 40.7553, -73.9875, ["123", "ace"]),
            station("penn-station", "34 St-Penn Station", 40.7506, -73.9935, ["123", "ace"]),
            station("fourteenth-st", "14 St", 40.7378, -74.0003, ["123"]),
            station("chambers-st", "Chambers St", 40.7155, -74.0093, ["123"]),
            station("south-ferry", "South Ferry", 40.7021, -74.0137, ["123"]),
            station("grand-central", "Grand Central-42 St", 40.7527, -73.9772, ["456"]),
            station("union-square", "14 St-Union Sq", 40.7357, -73.9906, ["456"]),
            station("brooklyn-bridge", "Brooklyn Bridge-City Hall", 40.7131, -74.0041, ["456"]),
            station("atlantic-av", "Atlantic Av-Barclays Ctr", 40.6844, -73.9777, ["456"]),
            station("columbus-circle", "59 St-Columbus Circle", 40.7682, -73.9819, ["ace"]),
            station("port-authority", "42 St-Port Authority", 40.7573, -73.9897, ["ace"]),
            station("west-fourth", "W 4 St-Wash Sq", 40.7323, -74.0007, ["ace"]),
            station("jay-st", "Jay St-MetroTech", 40.6923, -73.9873, ["ace"]),
        ]
    }

    private var nycLines: [MetroLine] {
        [
            MetroLine(
                id: "123",
                name: "1/2/3",
                color: Color(red: 0.86, green: 0.08, blue: 0.16),
                stationNames: ["Times Sq-42 St", "34 St-Penn Station", "14 St", "Chambers St", "South Ferry"],
                coordinates: coordinates(["times-square", "penn-station", "fourteenth-st", "chambers-st", "south-ferry"])
            ),
            MetroLine(
                id: "456",
                name: "4/5/6",
                color: Color(red: 0.03, green: 0.58, blue: 0.27),
                stationNames: ["Grand Central-42 St", "14 St-Union Sq", "Brooklyn Bridge-City Hall", "Atlantic Av-Barclays Ctr"],
                coordinates: coordinates(["grand-central", "union-square", "brooklyn-bridge", "atlantic-av"])
            ),
            MetroLine(
                id: "ace",
                name: "A/C/E",
                color: Color(red: 0.00, green: 0.32, blue: 0.72),
                stationNames: ["59 St-Columbus Circle", "42 St-Port Authority", "Times Sq-42 St", "34 St-Penn Station", "W 4 St-Wash Sq", "Jay St-MetroTech"],
                coordinates: coordinates(["columbus-circle", "port-authority", "times-square", "penn-station", "west-fourth", "jay-st"])
            ),
        ]
    }

    private func coordinates(_ ids: [String]) -> [CLLocationCoordinate2D] {
        ids.compactMap { id in stations.first { $0.id == id }?.coordinate }
    }

    private func station(_ id: String, _ name: String, _ latitude: Double, _ longitude: Double, _ lineIDs: [String]) -> MetroStation {
        MetroStation(
            id: id,
            name: name,
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            lineIDs: lineIDs
        )
    }

    private func region(_ latitude: Double, _ longitude: Double, _ latDelta: Double, _ lonDelta: Double) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }
}

enum MetroRoutePlanner {
    static func fastestRoute(lines: [MetroLine], from start: MetroStation, to end: MetroStation) -> MetroRoutePlan? {
        guard start != end else { return nil }
        guard let edges = shortestEdges(lines: lines, from: start.name, to: end.name), !edges.isEmpty else { return nil }

        var steps: [MetroRouteStep] = []
        for edge in edges {
            if let last = steps.last, last.lineName == edge.line.name {
                steps.removeLast()
                steps.append(
                    MetroRouteStep(
                        lineName: last.lineName,
                        color: last.color,
                        fromName: last.fromName,
                        toName: edge.to,
                        stopCount: last.stopCount + 1
                    )
                )
            } else {
                steps.append(
                    MetroRouteStep(
                        lineName: edge.line.name,
                        color: edge.line.color,
                        fromName: edge.from,
                        toName: edge.to,
                        stopCount: 1
                    )
                )
            }
        }

        let transferCount = max(0, steps.count - 1)
        return MetroRoutePlan(
            fromName: start.name,
            toName: end.name,
            minutes: edges.count * 3 + transferCount * 4,
            steps: steps
        )
    }

    private static func shortestEdges(lines: [MetroLine], from start: String, to end: String) -> [(from: String, to: String, line: MetroLine)]? {
        var queue = [start]
        var visited: Set<String> = [start]
        var previous: [String: (station: String, line: MetroLine)] = [:]

        while !queue.isEmpty {
            let current = queue.removeFirst()
            if current == end { break }

            for line in lines where line.stationNames.contains(current) {
                guard let index = line.stationNames.firstIndex(of: current) else { continue }
                let neighbors = [
                    index > line.stationNames.startIndex ? line.stationNames[line.stationNames.index(before: index)] : nil,
                    index < line.stationNames.index(before: line.stationNames.endIndex) ? line.stationNames[line.stationNames.index(after: index)] : nil,
                ].compactMap { $0 }

                for neighbor in neighbors where !visited.contains(neighbor) {
                    visited.insert(neighbor)
                    previous[neighbor] = (current, line)
                    queue.append(neighbor)
                }
            }
        }

        guard visited.contains(end) else { return nil }
        var cursor = end
        var path: [(from: String, to: String, line: MetroLine)] = []

        while cursor != start {
            guard let prev = previous[cursor] else { return nil }
            path.append((from: prev.station, to: cursor, line: prev.line))
            cursor = prev.station
        }

        return path.reversed()
    }
}
