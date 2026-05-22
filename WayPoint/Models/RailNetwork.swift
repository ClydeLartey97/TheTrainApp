//
//  RailNetwork.swift
//  WayPoint
//
//  Created by Clyde Lartey on 07/04/2026.
//

import CoreLocation
import MapKit
import SwiftUI

struct RailRegion: Identifiable, Equatable {
    let id: String
    let network: RailNetwork
    let displayName: String
    let locationLabel: String
    let region: MKCoordinateRegion

    static func == (lhs: RailRegion, rhs: RailRegion) -> Bool {
        lhs.id == rhs.id
    }
}

private struct RailNetworkProfile {
    let displayName: String
    let shortLabel: String
    let regionLabel: String
    let locationSummary: String
    let hasLiveDepartures: Bool
    let bookingURL: URL?
    let regions: [RailRegion]
}

enum RailNetwork: String, CaseIterable, Identifiable {
    case ukNationalRail
    case amtrak
    case brightline
    case njTransit
    case longIslandRailRoad
    case metroNorthRailroad
    case mbtaCommuterRail
    case septaRegionalRail
    case marcTrain
    case virginiaRailwayExpress
    case metra
    case caltrain
    case sounder
    case frontRunner
    case triRail
    case sunRail
    case coaster
    case aceRail
    case northstar
    case capitolCorridor
    case eurostar
    case sncfConnect
    case deutscheBahn
    case renfe
    case trenitalia
    case italo
    case sbbCffFfs
    case oebb
    case nsRail
    case sncb
    case dsb
    case sj
    case vy
    case vr
    case irishRail
    case cpPortugal
    case ceskeDrahy
    case pkpIntercity
    case mavStart
    case zssk
    case slovenskeZeleznice
    case hzpp
    case cfrCalatori
    case bdz
    case cfl
    case elron
    case ltgLink
    case ukrzaliznytsia
    case hellenicTrain

    var id: String { rawValue }

    var displayName: String { profile.displayName }
    var shortLabel: String { profile.shortLabel }
    var regionLabel: String { profile.regionLabel }
    var locationSummary: String { profile.locationSummary }
    var hasLiveDepartures: Bool { profile.hasLiveDepartures }
    var bookingURL: URL? { profile.bookingURL }
    var regions: [RailRegion] { profile.regions }

    var defaultRegion: MKCoordinateRegion {
        profile.regions.first?.region ?? Self.defaultWorldRegion
    }

    var rapidTransitTabLabel: String {
        switch self {
        case .ukNationalRail:
            "Underground"
        case .longIslandRailRoad, .metroNorthRailroad, .njTransit:
            "Subway"
        case .deutscheBahn, .oebb:
            "U-Bahn"
        default:
            "Metro"
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
        default:
            []
        }
    }

    var trains: [LiveTrain] {
        switch self {
        case .ukNationalRail:
            [
                LiveTrain(
                    code: "GWR 1",
                    routeName: "Paddington -> Oxford",
                    statusText: "Running on time near Reading",
                    status: .onTime,
                    coordinate: CLLocationCoordinate2D(latitude: 51.4584, longitude: -0.9710)
                ),
                LiveTrain(
                    code: "XC 8",
                    routeName: "Oxford -> Birmingham",
                    statusText: "7 min late approaching Banbury",
                    status: .minorDelay,
                    coordinate: CLLocationCoordinate2D(latitude: 52.0632, longitude: -1.3404)
                ),
                LiveTrain(
                    code: "ELZ 4",
                    routeName: "Liverpool Street -> Shenfield",
                    statusText: "Minor delay eastbound",
                    status: .minorDelay,
                    coordinate: CLLocationCoordinate2D(latitude: 51.5154, longitude: -0.0726)
                ),
            ]
        case .njTransit:
            [
                LiveTrain(
                    code: "NEC 2",
                    routeName: "Trenton -> New York Penn",
                    statusText: "Running on time into Newark",
                    status: .onTime,
                    coordinate: CLLocationCoordinate2D(latitude: 40.7340, longitude: -74.1642)
                ),
                LiveTrain(
                    code: "MNE 5",
                    routeName: "Hoboken -> Dover",
                    statusText: "12 min late westbound",
                    status: .minorDelay,
                    coordinate: CLLocationCoordinate2D(latitude: 40.7360, longitude: -74.0307)
                ),
            ]
        case .longIslandRailRoad:
            [
                LiveTrain(
                    code: "LIRR 7",
                    routeName: "Great Neck -> Grand Central",
                    statusText: "Running on time through Queens",
                    status: .onTime,
                    coordinate: CLLocationCoordinate2D(latitude: 40.7446, longitude: -73.9488)
                ),
                LiveTrain(
                    code: "LIRR 3",
                    routeName: "Penn Station -> Port Washington",
                    statusText: "5 min late leaving Manhattan",
                    status: .minorDelay,
                    coordinate: CLLocationCoordinate2D(latitude: 40.7510, longitude: -73.9935)
                ),
            ]
        default:
            []
        }
    }

    // MARK: - Location detection

    static func network(for coordinate: CLLocationCoordinate2D) -> RailNetwork {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        if lat >= 49.5 && lat <= 58.7 && lon >= -8.0 && lon <= 2.0 { return .ukNationalRail }
        if lat >= 40.5 && lat <= 41.1 && lon >= -74.0 && lon <= -71.9 { return .longIslandRailRoad }
        if lat >= 40.9 && lat <= 42.0 && lon >= -74.4 && lon <= -72.7 { return .metroNorthRailroad }
        if lat >= 38.9 && lat <= 41.4 && lon >= -75.6 && lon <= -73.9 { return .njTransit }
        if lat >= 24.5 && lat <= 49.4 && lon >= -125.0 && lon <= -66.8 { return .amtrak }
        if lat >= 41.0 && lat <= 51.5 && lon >= -5.5 && lon <= 9.8 { return .sncfConnect }
        if lat >= 47.0 && lat <= 55.2 && lon >= 5.5 && lon <= 15.5 { return .deutscheBahn }
        if lat >= 36.0 && lat <= 43.9 && lon >= -9.5 && lon <= 3.5 { return .renfe }
        if lat >= 36.0 && lat <= 47.2 && lon >= 6.0 && lon <= 18.8 { return .trenitalia }
        return .ukNationalRail
    }

    // MARK: - Profiles

    private var profile: RailNetworkProfile {
        switch self {
        case .ukNationalRail:
            return market("UK Rail", short: "UK Rail", region: "United Kingdom", live: true, booking: "https://www.nationalrail.co.uk/", latitude: 52.3555, longitude: -1.1743, latDelta: 6.8, lonDelta: 8.6)
        case .amtrak:
            return market("Amtrak", short: "Amtrak", region: "United States", booking: "https://www.amtrak.com/home.html", latitude: 39.8283, longitude: -98.5795, latDelta: 24.0, lonDelta: 58.0)
        case .brightline:
            return market("Brightline", short: "Brightline", region: "Florida", booking: "https://www.gobrightline.com/", latitude: 27.6648, longitude: -81.5158, latDelta: 6.2, lonDelta: 5.6)
        case .njTransit:
            return market("NJ TRANSIT", short: "NJ Transit", region: "New Jersey", booking: "https://www.njtransit.com/tickets", latitude: 40.0583, longitude: -74.4057, latDelta: 2.1, lonDelta: 2.0)
        case .longIslandRailRoad:
            return market("Long Island Rail Road", short: "LIRR", region: "Long Island & NYC", booking: "https://new.mta.info/traintime", latitude: 40.7891, longitude: -73.1350, latDelta: 1.0, lonDelta: 2.7)
        case .metroNorthRailroad:
            return market("Metro-North Railroad", short: "Metro-North", region: "New York & Connecticut", booking: "https://new.mta.info/traintime", latitude: 41.2043, longitude: -73.7271, latDelta: 1.9, lonDelta: 2.1)
        case .mbtaCommuterRail:
            return market("MBTA Commuter Rail", short: "MBTA Rail", region: "Massachusetts", booking: "https://www.mbta.com/fares/commuter-rail-fares", latitude: 42.3601, longitude: -71.0589, latDelta: 1.5, lonDelta: 1.8)
        case .septaRegionalRail:
            return market("SEPTA Regional Rail", short: "SEPTA Rail", region: "Philadelphia", booking: "https://www.septa.org/fares/", latitude: 39.9526, longitude: -75.1652, latDelta: 1.4, lonDelta: 1.6)
        case .marcTrain:
            return market("MARC Train", short: "MARC", region: "Maryland & DC", booking: "https://www.mta.maryland.gov/marc-fares", latitude: 39.0458, longitude: -76.6413, latDelta: 2.0, lonDelta: 2.4)
        case .virginiaRailwayExpress:
            return market("Virginia Railway Express", short: "VRE", region: "Virginia & DC", booking: "https://www.vre.org/service/fares/", latitude: 38.7509, longitude: -77.4753, latDelta: 1.3, lonDelta: 1.5)
        case .metra:
            return market("Metra", short: "Metra", region: "Chicago", booking: "https://metra.com/tickets", latitude: 41.8781, longitude: -87.6298, latDelta: 1.7, lonDelta: 1.8)
        case .caltrain:
            return market("Caltrain", short: "Caltrain", region: "Bay Area", booking: "https://www.caltrain.com/fares", latitude: 37.4419, longitude: -122.1430, latDelta: 1.4, lonDelta: 1.1)
        case .sounder:
            return market("Sounder", short: "Sounder", region: "Seattle", booking: "https://www.soundtransit.org/ride-with-us/how-to-pay", latitude: 47.6062, longitude: -122.3321, latDelta: 1.6, lonDelta: 1.4)
        case .frontRunner:
            return market("FrontRunner", short: "FrontRunner", region: "Utah", booking: "https://www.rideuta.com/Fares-And-Passes", latitude: 40.7608, longitude: -111.8910, latDelta: 2.0, lonDelta: 1.5)
        case .triRail:
            return market("Tri-Rail", short: "Tri-Rail", region: "South Florida", booking: "https://www.tri-rail.com/pages/view/fares", latitude: 26.3683, longitude: -80.1289, latDelta: 1.5, lonDelta: 1.0)
        case .sunRail:
            return market("SunRail", short: "SunRail", region: "Central Florida", booking: "https://sunrail.com/tickets/", latitude: 28.5383, longitude: -81.3792, latDelta: 1.2, lonDelta: 1.0)
        case .coaster:
            return market("COASTER", short: "COASTER", region: "San Diego", booking: "https://gonctd.com/fares/", latitude: 32.7157, longitude: -117.1611, latDelta: 0.9, lonDelta: 0.8)
        case .aceRail:
            return market("ACE Rail", short: "ACE", region: "Northern California", booking: "https://acerail.com/fares/", latitude: 37.9577, longitude: -121.2908, latDelta: 1.8, lonDelta: 1.9)
        case .northstar:
            return market("Northstar", short: "Northstar", region: "Minnesota", booking: "https://www.metrotransit.org/fares", latitude: 45.1999, longitude: -93.3870, latDelta: 1.5, lonDelta: 1.3)
        case .capitolCorridor:
            return market("Capitol Corridor", short: "Capitol Corridor", region: "Northern California", booking: "https://www.capitolcorridor.org/", latitude: 37.8044, longitude: -122.2712, latDelta: 1.8, lonDelta: 2.2)
        case .eurostar:
            return market("Eurostar", short: "Eurostar", region: "Western Europe", booking: "https://www.eurostar.com/", latitude: 50.1109, longitude: 2.3522, latDelta: 7.0, lonDelta: 8.0)
        case .sncfConnect:
            return market("SNCF Connect", short: "SNCF", region: "France", booking: "https://www.sncf-connect.com/en-en/", latitude: 46.2276, longitude: 2.2137, latDelta: 6.6, lonDelta: 7.8)
        case .deutscheBahn:
            return market("Deutsche Bahn", short: "DB", region: "Germany", booking: "https://int.bahn.de/en", latitude: 51.1657, longitude: 10.4515, latDelta: 6.4, lonDelta: 7.8)
        case .renfe:
            return market("Renfe", short: "Renfe", region: "Spain", booking: "https://www.renfe.com/es/en", latitude: 40.4637, longitude: -3.7492, latDelta: 6.5, lonDelta: 7.6)
        case .trenitalia:
            return market("Trenitalia", short: "Trenitalia", region: "Italy", booking: "https://www.trenitalia.com/en.html", latitude: 42.8719, longitude: 12.5674, latDelta: 7.6, lonDelta: 7.4)
        case .italo:
            return market("Italo", short: "Italo", region: "Italy", booking: "https://www.italotreno.com/en", latitude: 42.8719, longitude: 12.5674, latDelta: 7.6, lonDelta: 7.4)
        case .sbbCffFfs:
            return market("SBB CFF FFS", short: "SBB", region: "Switzerland", booking: "https://www.sbb.ch/en", latitude: 46.8182, longitude: 8.2275, latDelta: 3.0, lonDelta: 4.2)
        case .oebb:
            return market("ÖBB", short: "ÖBB", region: "Austria", booking: "https://www.oebb.at/en/", latitude: 47.5162, longitude: 14.5501, latDelta: 3.2, lonDelta: 5.2)
        case .nsRail:
            return market("NS", short: "NS", region: "Netherlands", booking: "https://www.ns.nl/en", latitude: 52.1326, longitude: 5.2913, latDelta: 2.6, lonDelta: 3.2)
        case .sncb:
            return market("SNCB", short: "SNCB", region: "Belgium", booking: "https://www.belgiantrain.be/en", latitude: 50.5039, longitude: 4.4699, latDelta: 2.4, lonDelta: 2.9)
        case .dsb:
            return market("DSB", short: "DSB", region: "Denmark", booking: "https://www.dsb.dk/en/", latitude: 56.2639, longitude: 9.5018, latDelta: 3.5, lonDelta: 5.0)
        case .sj:
            return market("SJ", short: "SJ", region: "Sweden", booking: "https://www.sj.se/en", latitude: 60.1282, longitude: 18.6435, latDelta: 8.0, lonDelta: 8.0)
        case .vy:
            return market("Vy", short: "Vy", region: "Norway", booking: "https://www.vy.no/en", latitude: 60.4720, longitude: 8.4689, latDelta: 8.0, lonDelta: 8.2)
        case .vr:
            return market("VR", short: "VR", region: "Finland", booking: "https://www.vr.fi/en", latitude: 61.9241, longitude: 25.7482, latDelta: 8.0, lonDelta: 8.0)
        case .irishRail:
            return market("Iarnród Éireann", short: "Irish Rail", region: "Ireland", booking: "https://www.irishrail.ie/en-ie/", latitude: 53.1424, longitude: -7.6921, latDelta: 4.2, lonDelta: 4.8)
        case .cpPortugal:
            return market("Comboios de Portugal", short: "CP", region: "Portugal", booking: "https://www.cp.pt/passageiros/en", latitude: 39.3999, longitude: -8.2245, latDelta: 4.7, lonDelta: 3.3)
        case .ceskeDrahy:
            return market("České dráhy", short: "ČD", region: "Czechia", booking: "https://www.cd.cz/en/", latitude: 49.8175, longitude: 15.4730, latDelta: 2.6, lonDelta: 4.0)
        case .pkpIntercity:
            return market("PKP Intercity", short: "PKP", region: "Poland", booking: "https://www.intercity.pl/en/", latitude: 51.9194, longitude: 19.1451, latDelta: 5.2, lonDelta: 6.0)
        case .mavStart:
            return market("MÁV", short: "MÁV", region: "Hungary", booking: "https://jegy.mav.hu/?lang=en", latitude: 47.1625, longitude: 19.5033, latDelta: 2.8, lonDelta: 4.4)
        case .zssk:
            return market("ZSSK", short: "ZSSK", region: "Slovakia", booking: "https://www.zssk.sk/en/", latitude: 48.6690, longitude: 19.6990, latDelta: 2.2, lonDelta: 4.1)
        case .slovenskeZeleznice:
            return market("Slovenske železnice", short: "SŽ", region: "Slovenia", booking: "https://potniski.sz.si/en/", latitude: 46.1512, longitude: 14.9955, latDelta: 1.6, lonDelta: 2.6)
        case .hzpp:
            return market("HŽPP", short: "HŽPP", region: "Croatia", booking: "https://www.hzpp.hr/en", latitude: 45.1000, longitude: 15.2000, latDelta: 3.6, lonDelta: 4.2)
        case .cfrCalatori:
            return market("CFR Călători", short: "CFR", region: "Romania", booking: "https://www.cfrcalatori.ro/en/", latitude: 45.9432, longitude: 24.9668, latDelta: 4.4, lonDelta: 6.0)
        case .bdz:
            return market("BDZ", short: "BDZ", region: "Bulgaria", booking: "https://www.bdz.bg/en", latitude: 42.7339, longitude: 25.4858, latDelta: 3.2, lonDelta: 4.6)
        case .cfl:
            return market("CFL", short: "CFL", region: "Luxembourg", booking: "https://www.cfl.lu/en-gb", latitude: 49.8153, longitude: 6.1296, latDelta: 0.9, lonDelta: 1.0)
        case .elron:
            return market("Elron", short: "Elron", region: "Estonia", booking: "https://elron.ee/en", latitude: 58.5953, longitude: 25.0136, latDelta: 3.0, lonDelta: 4.2)
        case .ltgLink:
            return market("LTG Link", short: "LTG", region: "Lithuania", booking: "https://ltglink.lt/en", latitude: 55.1694, longitude: 23.8813, latDelta: 3.0, lonDelta: 4.2)
        case .ukrzaliznytsia:
            return market("Ukrzaliznytsia", short: "UZ", region: "Ukraine", booking: "https://www.uz.gov.ua/en/", latitude: 48.3794, longitude: 31.1656, latDelta: 7.0, lonDelta: 10.0)
        case .hellenicTrain:
            return market("Hellenic Train", short: "Hellenic", region: "Greece", booking: "https://www.hellenictrain.gr/en", latitude: 39.0742, longitude: 21.8243, latDelta: 4.8, lonDelta: 5.2)
        }
    }

    private func market(
        _ displayName: String,
        short: String,
        region: String,
        live: Bool = false,
        booking: String,
        latitude: Double,
        longitude: Double,
        latDelta: Double,
        lonDelta: Double
    ) -> RailNetworkProfile {
        let bookingURL = URL(string: booking)
        let summary = live
            ? "\(region) · Live departures via official rail data"
            : "\(region) · Live rail search coming soon · Official tickets link ready"
        let railRegion = RailRegion(
            id: "\(rawValue).primary",
            network: self,
            displayName: region,
            locationLabel: region,
            region: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
            )
        )
        return RailNetworkProfile(
            displayName: displayName,
            shortLabel: short,
            regionLabel: region,
            locationSummary: summary,
            hasLiveDepartures: live,
            bookingURL: bookingURL,
            regions: [railRegion]
        )
    }

    private static var defaultWorldRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 45.0, longitude: 0.0),
            span: MKCoordinateSpan(latitudeDelta: 35.0, longitudeDelta: 70.0)
        )
    }
}
