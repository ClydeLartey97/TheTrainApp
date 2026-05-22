//
//  CountyRegion.swift
//  WayPoint
//
//  Created by Clyde Lartey on 07/04/2026.
//

import MapKit

enum CountyRegion: String, CaseIterable, Identifiable {
    case national
    case oxfordshire
    case greaterLondon
    case berkshire
    case newJersey
    case newark
    case hoboken
    case greatNeck
    case queens
    case manhattan

    var id: String { rawValue }

    var network: RailNetwork {
        switch self {
        case .national, .oxfordshire, .greaterLondon, .berkshire:
            .ukNationalRail
        case .newJersey, .newark, .hoboken:
            .njTransit
        case .greatNeck, .queens, .manhattan:
            .longIslandRailRoad
        }
    }

    var displayName: String {
        switch self {
        case .national:
            "National"
        case .oxfordshire:
            "Oxfordshire"
        case .greaterLondon:
            "Greater London"
        case .berkshire:
            "Berkshire"
        case .newJersey:
            "New Jersey"
        case .newark:
            "Newark"
        case .hoboken:
            "Hoboken"
        case .greatNeck:
            "Great Neck"
        case .queens:
            "Queens"
        case .manhattan:
            "Manhattan"
        }
    }

    var locationLabel: String {
        switch self {
        case .national, .oxfordshire, .greaterLondon, .berkshire:
            "United Kingdom"
        case .newJersey, .newark, .hoboken, .greatNeck, .queens, .manhattan:
            "United States"
        }
    }

    var region: MKCoordinateRegion {
        switch self {
        case .national:
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 52.3555, longitude: -1.1743),
                span: MKCoordinateSpan(latitudeDelta: 6.8, longitudeDelta: 8.6)
            )
        case .oxfordshire:
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 51.7520, longitude: -1.2577),
                span: MKCoordinateSpan(latitudeDelta: 0.8, longitudeDelta: 0.8)
            )
        case .greaterLondon:
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 51.5072, longitude: -0.1276),
                span: MKCoordinateSpan(latitudeDelta: 0.55, longitudeDelta: 0.55)
            )
        case .berkshire:
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 51.4543, longitude: -0.9781),
                span: MKCoordinateSpan(latitudeDelta: 0.55, longitudeDelta: 0.55)
            )
        case .newJersey:
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.0583, longitude: -74.4057),
                span: MKCoordinateSpan(latitudeDelta: 2.1, longitudeDelta: 2.0)
            )
        case .newark:
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.7357, longitude: -74.1724),
                span: MKCoordinateSpan(latitudeDelta: 0.28, longitudeDelta: 0.28)
            )
        case .hoboken:
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.7433, longitude: -74.0324),
                span: MKCoordinateSpan(latitudeDelta: 0.22, longitudeDelta: 0.22)
            )
        case .greatNeck:
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.8007, longitude: -73.7285),
                span: MKCoordinateSpan(latitudeDelta: 0.22, longitudeDelta: 0.22)
            )
        case .queens:
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.7282, longitude: -73.7949),
                span: MKCoordinateSpan(latitudeDelta: 0.45, longitudeDelta: 0.45)
            )
        case .manhattan:
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 40.7831, longitude: -73.9712),
                span: MKCoordinateSpan(latitudeDelta: 0.32, longitudeDelta: 0.32)
            )
        }
    }
}
