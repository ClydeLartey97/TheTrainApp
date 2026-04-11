//
//  RailNetwork.swift
//  WayPoint
//
//  Created by Clyde Lartey on 07/04/2026.
//

import MapKit
import SwiftUI

enum RailNetwork: String, CaseIterable, Identifiable {
    case ukNationalRail
    case njTransit
    case longIslandRailRoad

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ukNationalRail:
            "UK Rail"
        case .njTransit:
            "NJ TRANSIT"
        case .longIslandRailRoad:
            "LIRR"
        }
    }

    var shortLabel: String {
        switch self {
        case .ukNationalRail:
            "UK Rail"
        case .njTransit:
            "NJ Transit"
        case .longIslandRailRoad:
            "LIRR"
        }
    }

    var regionLabel: String {
        switch self {
        case .ukNationalRail:
            "Oxford and national"
        case .njTransit:
            "New Jersey"
        case .longIslandRailRoad:
            "Great Neck and NYC"
        }
    }

    var locationSummary: String {
        switch self {
        case .ukNationalRail:
            "Auto-selected because your current location is in the United Kingdom."
        case .njTransit:
            "Example regional mode for future location-aware switching in New Jersey."
        case .longIslandRailRoad:
            "Example regional mode for future location-aware switching around Long Island."
        }
    }

    var defaultRegion: MKCoordinateRegion {
        switch self {
        case .ukNationalRail:
            CountyRegion.oxfordshire.region
        case .njTransit:
            CountyRegion.newJersey.region
        case .longIslandRailRoad:
            CountyRegion.greatNeck.region
        }
    }

    var counties: [CountyRegion] {
        switch self {
        case .ukNationalRail:
            [.national, .oxfordshire, .greaterLondon, .berkshire]
        case .njTransit:
            [.newJersey, .newark, .hoboken]
        case .longIslandRailRoad:
            [.greatNeck, .queens, .manhattan]
        }
    }

    var sampleTrips: [RailTrip] {
        switch self {
        case .ukNationalRail:
            [
                RailTrip(
                    origin: "London Paddington",
                    destination: "Oxford",
                    departureTime: "16:04",
                    arrivalTime: "16:56",
                    duration: "52 min",
                    operatorName: "Great Western Railway",
                    changeSummary: "Direct",
                    price: "£23.80",
                    status: "On time"
                ),
                RailTrip(
                    origin: "Reading",
                    destination: "Oxford",
                    departureTime: "16:12",
                    arrivalTime: "16:38",
                    duration: "26 min",
                    operatorName: "Great Western Railway",
                    changeSummary: "Direct",
                    price: "£14.10",
                    status: "On time"
                ),
                RailTrip(
                    origin: "Oxford",
                    destination: "Birmingham New Street",
                    departureTime: "16:30",
                    arrivalTime: "17:38",
                    duration: "1 hr 8 min",
                    operatorName: "CrossCountry",
                    changeSummary: "Direct",
                    price: "£28.20",
                    status: "On time"
                ),
            ]
        case .njTransit:
            [
                RailTrip(
                    origin: "Newark Penn",
                    destination: "New York Penn",
                    departureTime: "17:08",
                    arrivalTime: "17:30",
                    duration: "22 min",
                    operatorName: "NJ TRANSIT",
                    changeSummary: "Direct",
                    price: "$5.25",
                    status: "On time"
                ),
            ]
        case .longIslandRailRoad:
            [
                RailTrip(
                    origin: "Great Neck",
                    destination: "Grand Central Madison",
                    departureTime: "17:14",
                    arrivalTime: "17:48",
                    duration: "34 min",
                    operatorName: "Long Island Rail Road",
                    changeSummary: "Direct",
                    price: "$9.75",
                    status: "On time"
                ),
            ]
        }
    }

    var trains: [LiveTrain] {
        switch self {
        case .ukNationalRail:
            [
                LiveTrain(
                    code: "GWR 1",
                    routeName: "Paddington → Oxford",
                    statusText: "Running on time near Reading",
                    status: .onTime,
                    coordinate: CLLocationCoordinate2D(latitude: 51.4584, longitude: -0.9710)
                ),
                LiveTrain(
                    code: "XC 8",
                    routeName: "Oxford → Birmingham",
                    statusText: "7 min late approaching Banbury",
                    status: .minorDelay,
                    coordinate: CLLocationCoordinate2D(latitude: 52.0632, longitude: -1.3404)
                ),
                LiveTrain(
                    code: "ELZ 4",
                    routeName: "Liverpool Street → Shenfield",
                    statusText: "Minor delay eastbound",
                    status: .minorDelay,
                    coordinate: CLLocationCoordinate2D(latitude: 51.5154, longitude: -0.0726)
                ),
            ]
        case .njTransit:
            [
                LiveTrain(
                    code: "NEC 2",
                    routeName: "Trenton → New York Penn",
                    statusText: "Running on time into Newark",
                    status: .onTime,
                    coordinate: CLLocationCoordinate2D(latitude: 40.7340, longitude: -74.1642)
                ),
                LiveTrain(
                    code: "MNE 5",
                    routeName: "Hoboken → Dover",
                    statusText: "12 min late westbound",
                    status: .severeDelay,
                    coordinate: CLLocationCoordinate2D(latitude: 40.7360, longitude: -74.0307)
                ),
            ]
        case .longIslandRailRoad:
            [
                LiveTrain(
                    code: "LIRR 7",
                    routeName: "Great Neck → Grand Central",
                    statusText: "Running on time through Queens",
                    status: .onTime,
                    coordinate: CLLocationCoordinate2D(latitude: 40.7446, longitude: -73.9488)
                ),
                LiveTrain(
                    code: "LIRR 3",
                    routeName: "Penn Station → Port Washington",
                    statusText: "5 min late leaving Manhattan",
                    status: .minorDelay,
                    coordinate: CLLocationCoordinate2D(latitude: 40.7510, longitude: -73.9935)
                ),
            ]
        }
    }
}
