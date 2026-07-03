//
//  SavedRoute.swift
//  WayPoint
//
//  Created on 22/05/2026.
//

import Foundation

struct RouteStationSelection: Hashable {
    let origin: Station
    let destination: Station?

    func matches(origin other: Station, destination otherDestination: Station?) -> Bool {
        origin.crs.uppercased() == other.crs.uppercased()
            && destination?.crs.uppercased() == otherDestination?.crs.uppercased()
    }
}

struct SavedRoute: Codable, Identifiable, Hashable {
    let id: String
    var originName: String
    var originCode: String
    var destinationName: String?
    var destinationCode: String?
    var networkID: String
    var nickname: String?
    var createdAt: Date
    var lastUsedAt: Date
    var isFavorite: Bool

    init(
        origin: Station,
        destination: Station?,
        network: RailNetwork,
        nickname: String? = nil,
        isFavorite: Bool = false,
        createdAt: Date = .now,
        lastUsedAt: Date = .now
    ) {
        self.id = Self.routeID(
            networkID: network.rawValue,
            originCode: origin.crs,
            destinationCode: destination?.crs
        )
        self.originName = origin.name
        self.originCode = origin.crs.uppercased()
        self.destinationName = destination?.name
        self.destinationCode = destination?.crs.uppercased()
        self.networkID = network.rawValue
        self.nickname = nickname
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.isFavorite = isFavorite
    }

    var network: RailNetwork? {
        RailNetwork(rawValue: networkID)
    }

    var originStation: Station {
        Station(name: originName, crs: originCode)
    }

    var destinationStation: Station? {
        guard let destinationName, let destinationCode else { return nil }
        return Station(name: destinationName, crs: destinationCode)
    }

    var title: String {
        if let nickname, !nickname.isEmpty {
            return nickname
        }
        guard let destinationName, !destinationName.isEmpty else {
            return "\(originName) departures"
        }
        return "\(originName) to \(destinationName)"
    }

    var stationCodeSummary: String {
        guard let destinationCode, !destinationCode.isEmpty else {
            return "\(originCode) to anywhere"
        }
        return "\(originCode) to \(destinationCode)"
    }

    var canReverse: Bool {
        destinationStation != nil
    }

    func reversedForSearch() -> SavedRoute? {
        guard let destination = destinationStation else { return nil }
        return SavedRoute(
            origin: destination,
            destination: originStation,
            network: network ?? .ukNationalRail,
            nickname: nil,
            isFavorite: false,
            createdAt: .now,
            lastUsedAt: .now
        )
    }

    func lastUsedText(relativeTo date: Date = .now) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUsedAt, relativeTo: date)
    }

    static func routeID(networkID: String, originCode: String, destinationCode: String?) -> String {
        let destination = destinationCode?.uppercased() ?? "ANY"
        return "\(networkID):\(originCode.uppercased()):\(destination)"
    }
}
