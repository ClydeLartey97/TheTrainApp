//
//  StationRepository.swift
//  WayPoint
//
//  Created by Clyde Lartey on 11/04/2026.
//

import Foundation

struct Station: Identifiable, Hashable {
    var id: String { crs }
    let name: String
    let crs: String // Computer Reservation System code
}

struct StationRepository {
    static let shared = StationRepository()

    let stations: [Station] = [
        // London Terminals
        Station(name: "London Paddington", crs: "PAD"),
        Station(name: "London Waterloo", crs: "WAT"),
        Station(name: "London Victoria", crs: "VIC"),
        Station(name: "London Euston", crs: "EUS"),
        Station(name: "London Kings Cross", crs: "KGX"),
        Station(name: "London St Pancras International", crs: "STP"),
        Station(name: "London Liverpool Street", crs: "LST"),
        Station(name: "London Bridge", crs: "LBG"),
        Station(name: "London Charing Cross", crs: "CHX"),
        Station(name: "London Marylebone", crs: "MYB"),
        Station(name: "London Cannon Street", crs: "CST"),
        Station(name: "London Fenchurch Street", crs: "FST"),
        Station(name: "London Blackfriars", crs: "BFR"),

        // Major Cities
        Station(name: "Oxford", crs: "OXF"),
        Station(name: "Reading", crs: "RDG"),
        Station(name: "Birmingham New Street", crs: "BHM"),
        Station(name: "Birmingham Moor Street", crs: "BMO"),
        Station(name: "Manchester Piccadilly", crs: "MAN"),
        Station(name: "Manchester Victoria", crs: "MCV"),
        Station(name: "Manchester Oxford Road", crs: "MCO"),
        Station(name: "Leeds", crs: "LDS"),
        Station(name: "Sheffield", crs: "SHF"),
        Station(name: "Bristol Temple Meads", crs: "BRI"),
        Station(name: "Bristol Parkway", crs: "BPW"),
        Station(name: "Edinburgh Waverley", crs: "EDB"),
        Station(name: "Glasgow Central", crs: "GLC"),
        Station(name: "Glasgow Queen Street", crs: "GLQ"),
        Station(name: "Liverpool Lime Street", crs: "LIV"),
        Station(name: "Newcastle", crs: "NCL"),
        Station(name: "York", crs: "YRK"),
        Station(name: "Nottingham", crs: "NOT"),
        Station(name: "Leicester", crs: "LEI"),
        Station(name: "Cambridge", crs: "CBG"),
        Station(name: "Norwich", crs: "NRW"),
        Station(name: "Ipswich", crs: "IPS"),
        Station(name: "Peterborough", crs: "PBO"),
        Station(name: "Cardiff Central", crs: "CDF"),
        Station(name: "Swansea", crs: "SWA"),
        Station(name: "Newport", crs: "NWP"),
        Station(name: "Plymouth", crs: "PLY"),
        Station(name: "Exeter St Davids", crs: "EXD"),
        Station(name: "Southampton Central", crs: "SOU"),
        Station(name: "Portsmouth Harbour", crs: "PMH"),
        Station(name: "Brighton", crs: "BTN"),
        Station(name: "Bournemouth", crs: "BMH"),
        Station(name: "Bath Spa", crs: "BTH"),
        Station(name: "Swindon", crs: "SWI"),
        Station(name: "Coventry", crs: "COV"),
        Station(name: "Wolverhampton", crs: "WVH"),
        Station(name: "Derby", crs: "DBY"),
        Station(name: "Stoke-on-Trent", crs: "SOT"),
        Station(name: "Preston", crs: "PRE"),
        Station(name: "Lancaster", crs: "LAN"),
        Station(name: "Carlisle", crs: "CAR"),
        Station(name: "Aberdeen", crs: "ABD"),
        Station(name: "Dundee", crs: "DEE"),
        Station(name: "Inverness", crs: "INV"),
        Station(name: "Perth", crs: "PTH"),
        Station(name: "Stirling", crs: "STG"),

        // Commuter / Regional
        Station(name: "Guildford", crs: "GLD"),
        Station(name: "Woking", crs: "WOK"),
        Station(name: "Basingstoke", crs: "BSK"),
        Station(name: "Winchester", crs: "WIN"),
        Station(name: "Salisbury", crs: "SAL"),
        Station(name: "Cheltenham Spa", crs: "CNM"),
        Station(name: "Gloucester", crs: "GCR"),
        Station(name: "Worcester Shrub Hill", crs: "WOS"),
        Station(name: "Hereford", crs: "HFD"),
        Station(name: "Banbury", crs: "BAN"),
        Station(name: "Didcot Parkway", crs: "DID"),
        Station(name: "Slough", crs: "SLO"),
        Station(name: "Maidenhead", crs: "MAI"),
        Station(name: "Twyford", crs: "TWY"),
        Station(name: "Ealing Broadway", crs: "EAL"),
        Station(name: "Shenfield", crs: "SNF"),
        Station(name: "Stratford", crs: "SRA"),
        Station(name: "Clapham Junction", crs: "CLJ"),
        Station(name: "East Croydon", crs: "ECR"),
        Station(name: "Gatwick Airport", crs: "GTW"),
        Station(name: "Luton Airport Parkway", crs: "LTN"),
        Station(name: "Stansted Airport", crs: "SSD"),
        Station(name: "Heathrow Terminal 5", crs: "HWV"),
        Station(name: "Milton Keynes Central", crs: "MKC"),
        Station(name: "Watford Junction", crs: "WFJ"),
        Station(name: "St Albans City", crs: "SAC"),
        Station(name: "Stevenage", crs: "SVG"),
        Station(name: "Hitchin", crs: "HIT"),
        Station(name: "Colchester", crs: "COL"),
        Station(name: "Chelmsford", crs: "CHM"),
        Station(name: "Southend Victoria", crs: "SOV"),
        Station(name: "Canterbury West", crs: "CBW"),
        Station(name: "Dover Priory", crs: "DVP"),
        Station(name: "Ashford International", crs: "AFK"),
        Station(name: "Hastings", crs: "HGS"),
        Station(name: "Eastbourne", crs: "EBN"),
        Station(name: "Lewes", crs: "LWS"),
        Station(name: "Tunbridge Wells", crs: "TBW"),
        Station(name: "Sevenoaks", crs: "SEV"),
        Station(name: "Tonbridge", crs: "TON"),
        Station(name: "Maidstone East", crs: "MDE"),
        Station(name: "Crewe", crs: "CRE"),
        Station(name: "Chester", crs: "CTR"),
        Station(name: "Warrington Bank Quay", crs: "WBQ"),
        Station(name: "Wigan North Western", crs: "WGN"),
        Station(name: "Bolton", crs: "BON"),
        Station(name: "Blackpool North", crs: "BPN"),
        Station(name: "Huddersfield", crs: "HUD"),
        Station(name: "Bradford Interchange", crs: "BDI"),
        Station(name: "Halifax", crs: "HFX"),
        Station(name: "Wakefield Westgate", crs: "WKF"),
        Station(name: "Doncaster", crs: "DON"),
        Station(name: "Darlington", crs: "DAR"),
        Station(name: "Durham", crs: "DHM"),
        Station(name: "Sunderland", crs: "SUN"),
        Station(name: "Middlesbrough", crs: "MBR"),
        Station(name: "Hull", crs: "HUL"),
        Station(name: "Scarborough", crs: "SCA"),
        Station(name: "Harrogate", crs: "HGT"),
        Station(name: "Lincoln", crs: "LCN"),
        Station(name: "Grimsby Town", crs: "GMB"),
        Station(name: "Shrewsbury", crs: "SHR"),
        Station(name: "Telford Central", crs: "TFC"),
        Station(name: "Stafford", crs: "STA"),
        Station(name: "Tamworth", crs: "TAM"),
        Station(name: "Nuneaton", crs: "NUN"),
        Station(name: "Rugby", crs: "RUG"),
        Station(name: "Northampton", crs: "NMP"),
        Station(name: "Kettering", crs: "KET"),
        Station(name: "Wellingborough", crs: "WEL"),
        Station(name: "Bedford", crs: "BDM"),
        Station(name: "Luton", crs: "LUT"),
        Station(name: "Letchworth Garden City", crs: "LET"),
        Station(name: "Royston", crs: "RYS"),
        Station(name: "Ely", crs: "ELY"),
        Station(name: "Kings Lynn", crs: "KLN"),
        Station(name: "Taunton", crs: "TAU"),
        Station(name: "Weston-super-Mare", crs: "WSM"),
        Station(name: "Chippenham", crs: "CPM"),
        Station(name: "Trowbridge", crs: "TRO"),
        Station(name: "Westbury", crs: "WSB"),
        Station(name: "Frome", crs: "FRO"),
        Station(name: "Yeovil Junction", crs: "YVJ"),
        Station(name: "Dorchester South", crs: "DCH"),
        Station(name: "Weymouth", crs: "WEY"),
        Station(name: "Poole", crs: "POO"),
        Station(name: "Wareham", crs: "WRM"),
        Station(name: "Fareham", crs: "FRM"),
        Station(name: "Havant", crs: "HAV"),
        Station(name: "Chichester", crs: "CCH"),
        Station(name: "Worthing", crs: "WRH"),
        Station(name: "Horsham", crs: "HRH"),
        Station(name: "Crawley", crs: "CRW"),
        Station(name: "Redhill", crs: "RDH"),
        Station(name: "Dorking", crs: "DKG"),
        Station(name: "Epsom", crs: "EPS"),
        Station(name: "Surbiton", crs: "SUR"),
        Station(name: "Kingston", crs: "KNG"),
        Station(name: "Richmond", crs: "RMD"),
        Station(name: "Twickenham", crs: "TWI"),
        Station(name: "Staines", crs: "SNE"),
        Station(name: "Windsor & Eton Central", crs: "WNC"),
        Station(name: "Henley-on-Thames", crs: "HOT"),
        Station(name: "Marlow", crs: "MLW"),
        Station(name: "High Wycombe", crs: "HWY"),
        Station(name: "Aylesbury", crs: "AYS"),
        Station(name: "Bicester North", crs: "BCS"),
        Station(name: "Leamington Spa", crs: "LMS"),
        Station(name: "Stratford-upon-Avon", crs: "SAV"),
        Station(name: "Great Malvern", crs: "GMV"),
        Station(name: "Kidderminster", crs: "KID"),
        Station(name: "Birmingham International", crs: "BHI"),
        Station(name: "Solihull", crs: "SOL"),
    ]

    /// Search stations by name prefix (case-insensitive)
    func search(query: String) -> [Station] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let lowered = normalized(trimmed)
        let uppercased = trimmed.uppercased()

        return stations.filter { station in
            normalized(station.name).contains(lowered) || station.crs.hasPrefix(uppercased)
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

    private func normalized(_ value: String) -> String {
        value
            .lowercased()
            .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
            .filter { $0.isLetter || $0.isNumber }
    }
}
