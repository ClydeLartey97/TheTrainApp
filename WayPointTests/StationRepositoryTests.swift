//
//  StationRepositoryTests.swift
//  WayPointTests
//
//  Created on 07/07/2026.
//

import Testing
@testable import WayPoint

struct StationRepositoryTests {
    let repo = StationRepository.shared

    @Test func searchFindsByNameFragment() {
        let results = repo.search(query: "euston")
        #expect(results.contains { $0.crs == "EUS" })
    }

    @Test func searchFindsByCRSPrefix() {
        let results = repo.search(query: "KGX")
        #expect(results.first?.crs == "KGX")
    }

    @Test func searchIsCaseAndApostropheInsensitive() {
        let results = repo.search(query: "king's cross")
        #expect(results.contains { $0.crs == "KGX" })
    }

    @Test func searchMatchesAliases() {
        #expect(repo.search(query: "new street").contains { $0.crs == "BHM" })
        #expect(repo.search(query: "piccadilly").contains { $0.crs == "MAN" })
        #expect(repo.search(query: "st pancras").contains { $0.crs == "STP" })
    }

    @Test func searchEmptyQueryReturnsNothing() {
        #expect(repo.search(query: "   ").isEmpty)
    }

    @Test func resolveByExactCRS() {
        #expect(repo.resolveStation(query: "eus")?.crs == "EUS")
    }

    @Test func resolveByExactName() {
        #expect(repo.resolveStation(query: "London Euston")?.crs == "EUS")
    }

    @Test func resolveByAlias() {
        #expect(repo.resolveStation(query: "Kings Cross")?.crs == "KGX")
        #expect(repo.resolveStation(query: "King's Cross")?.crs == "KGX")
        #expect(repo.resolveStation(query: "Victoria")?.crs == "VIC")
    }

    @Test func resolveAmbiguousQueryReturnsNil() {
        // "London" matches many stations and is not an alias.
        #expect(repo.resolveStation(query: "London") == nil)
    }

    @Test func exactCRSMatchSortsFirst() {
        // "MAN" is both a CRS and a name fragment of Manchester stations.
        let results = repo.search(query: "MAN")
        #expect(results.first?.crs == "MAN")
    }
}
