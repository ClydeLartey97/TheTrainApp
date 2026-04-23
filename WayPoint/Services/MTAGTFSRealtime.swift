//
//  MTAGTFSRealtime.swift
//  WayPoint
//
//  Created by Codex on 22/04/2026.
//

import Foundation

struct MTARealtimeEntity {
    let id: String
    let tripUpdate: MTARealtimeTripUpdate?
    let alert: MTARealtimeAlert?
}

struct MTARealtimeTripUpdate {
    let tripID: String
    let routeID: String
    let stopTimeUpdates: [MTARealtimeStopTimeUpdate]
}

struct MTARealtimeStopTimeUpdate {
    let stopID: String
    let arrivalTime: Int?
    let departureTime: Int?

    nonisolated var eventTime: Int? {
        arrivalTime ?? departureTime
    }
}

struct MTARealtimeAlert {
    let affectedRouteIDs: [String]
    let effect: String
    let header: String
    let description: String
}

enum MTARealtimeParser {
    nonisolated static func parse(_ data: Data) throws -> [MTARealtimeEntity] {
        var reader = ProtobufReader(data: data)
        var entities: [MTARealtimeEntity] = []

        while let field = try reader.nextField() {
            switch (field.number, field.wireType) {
            case (2, .lengthDelimited):
                entities.append(try parseEntity(reader.readLengthDelimited()))
            default:
                try reader.skipValue(wireType: field.wireType)
            }
        }

        return entities
    }

    nonisolated private static func parseEntity(_ bytes: [UInt8]) throws -> MTARealtimeEntity {
        var reader = ProtobufReader(bytes: bytes)
        var id = ""
        var tripUpdate: MTARealtimeTripUpdate?
        var alert: MTARealtimeAlert?

        while let field = try reader.nextField() {
            switch (field.number, field.wireType) {
            case (1, .lengthDelimited):
                id = try reader.readString()
            case (3, .lengthDelimited):
                tripUpdate = try parseTripUpdate(reader.readLengthDelimited())
            case (5, .lengthDelimited):
                alert = try parseAlert(reader.readLengthDelimited())
            default:
                try reader.skipValue(wireType: field.wireType)
            }
        }

        return MTARealtimeEntity(id: id, tripUpdate: tripUpdate, alert: alert)
    }

    nonisolated private static func parseTripUpdate(_ bytes: [UInt8]) throws -> MTARealtimeTripUpdate {
        var reader = ProtobufReader(bytes: bytes)
        var tripID = ""
        var routeID = ""
        var stopTimeUpdates: [MTARealtimeStopTimeUpdate] = []

        while let field = try reader.nextField() {
            switch (field.number, field.wireType) {
            case (1, .lengthDelimited):
                let trip = try parseTripDescriptor(reader.readLengthDelimited())
                tripID = trip.tripID
                routeID = trip.routeID
            case (2, .lengthDelimited):
                stopTimeUpdates.append(try parseStopTimeUpdate(reader.readLengthDelimited()))
            default:
                try reader.skipValue(wireType: field.wireType)
            }
        }

        return MTARealtimeTripUpdate(
            tripID: tripID,
            routeID: routeID,
            stopTimeUpdates: stopTimeUpdates
        )
    }

    nonisolated private static func parseTripDescriptor(_ bytes: [UInt8]) throws -> (tripID: String, routeID: String) {
        var reader = ProtobufReader(bytes: bytes)
        var tripID = ""
        var routeID = ""

        while let field = try reader.nextField() {
            switch (field.number, field.wireType) {
            case (1, .lengthDelimited):
                tripID = try reader.readString()
            case (5, .lengthDelimited):
                routeID = try reader.readString()
            default:
                try reader.skipValue(wireType: field.wireType)
            }
        }

        return (tripID, routeID)
    }

    nonisolated private static func parseStopTimeUpdate(_ bytes: [UInt8]) throws -> MTARealtimeStopTimeUpdate {
        var reader = ProtobufReader(bytes: bytes)
        var stopID = ""
        var arrivalTime: Int?
        var departureTime: Int?

        while let field = try reader.nextField() {
            switch (field.number, field.wireType) {
            case (2, .lengthDelimited):
                arrivalTime = try parseStopTimeEvent(reader.readLengthDelimited())
            case (3, .lengthDelimited):
                departureTime = try parseStopTimeEvent(reader.readLengthDelimited())
            case (4, .lengthDelimited):
                stopID = try reader.readString()
            default:
                try reader.skipValue(wireType: field.wireType)
            }
        }

        return MTARealtimeStopTimeUpdate(
            stopID: stopID,
            arrivalTime: arrivalTime,
            departureTime: departureTime
        )
    }

    nonisolated private static func parseStopTimeEvent(_ bytes: [UInt8]) throws -> Int? {
        var reader = ProtobufReader(bytes: bytes)
        var time: Int?

        while let field = try reader.nextField() {
            switch (field.number, field.wireType) {
            case (2, .varint):
                time = Int(try reader.readVarint())
            default:
                try reader.skipValue(wireType: field.wireType)
            }
        }

        return time
    }

    nonisolated private static func parseAlert(_ bytes: [UInt8]) throws -> MTARealtimeAlert {
        var reader = ProtobufReader(bytes: bytes)
        var routeIDs: Set<String> = []
        var effect = "Service Alert"
        var header = ""
        var description = ""

        while let field = try reader.nextField() {
            switch (field.number, field.wireType) {
            case (5, .lengthDelimited):
                if let routeID = try parseEntitySelectorRouteID(reader.readLengthDelimited()) {
                    routeIDs.insert(routeID.uppercased())
                }
            case (7, .varint):
                effect = alertEffectName(Int(try reader.readVarint()))
            case (10, .lengthDelimited):
                header = try parseTranslatedString(reader.readLengthDelimited())
            case (11, .lengthDelimited):
                description = try parseTranslatedString(reader.readLengthDelimited())
            default:
                try reader.skipValue(wireType: field.wireType)
            }
        }

        return MTARealtimeAlert(
            affectedRouteIDs: routeIDs.sorted(),
            effect: effect,
            header: header,
            description: description
        )
    }

    nonisolated private static func parseEntitySelectorRouteID(_ bytes: [UInt8]) throws -> String? {
        var reader = ProtobufReader(bytes: bytes)
        var routeID: String?

        while let field = try reader.nextField() {
            switch (field.number, field.wireType) {
            case (2, .lengthDelimited):
                routeID = try reader.readString()
            default:
                try reader.skipValue(wireType: field.wireType)
            }
        }

        return routeID
    }

    nonisolated private static func parseTranslatedString(_ bytes: [UInt8]) throws -> String {
        var reader = ProtobufReader(bytes: bytes)
        var firstText = ""
        var englishText = ""

        while let field = try reader.nextField() {
            switch (field.number, field.wireType) {
            case (1, .lengthDelimited):
                let translation = try parseTranslation(reader.readLengthDelimited())
                if firstText.isEmpty {
                    firstText = translation.text
                }
                if translation.language.lowercased().hasPrefix("en"), englishText.isEmpty {
                    englishText = translation.text
                }
            default:
                try reader.skipValue(wireType: field.wireType)
            }
        }

        return englishText.isEmpty ? firstText : englishText
    }

    nonisolated private static func parseTranslation(_ bytes: [UInt8]) throws -> (text: String, language: String) {
        var reader = ProtobufReader(bytes: bytes)
        var text = ""
        var language = ""

        while let field = try reader.nextField() {
            switch (field.number, field.wireType) {
            case (1, .lengthDelimited):
                text = try reader.readString()
            case (2, .lengthDelimited):
                language = try reader.readString()
            default:
                try reader.skipValue(wireType: field.wireType)
            }
        }

        return (text, language)
    }

    nonisolated private static func alertEffectName(_ effect: Int) -> String {
        switch effect {
        case 1: "No Service"
        case 2: "Reduced Service"
        case 3: "Significant Delays"
        case 4: "Detour"
        case 5: "Additional Service"
        case 6: "Modified Service"
        case 7: "Service Alert"
        case 8: "Unknown Effect"
        case 9: "Stop Moved"
        case 10: "No Effect"
        case 11: "Accessibility Issue"
        default: "Service Alert"
        }
    }
}

private struct ProtobufReader {
    private var bytes: [UInt8]
    private var offset = 0

    nonisolated init(data: Data) {
        self.bytes = Array(data)
    }

    nonisolated init(bytes: [UInt8]) {
        self.bytes = bytes
    }

    nonisolated mutating func nextField() throws -> ProtobufField? {
        guard offset < bytes.count else { return nil }
        let tag = try readVarint()
        let fieldNumber = Int(tag >> 3)
        guard let wireType = ProtobufWireType(rawValue: Int(tag & 0x7)) else {
            throw ProtobufError.unsupportedWireType(Int(tag & 0x7))
        }
        return ProtobufField(number: fieldNumber, wireType: wireType)
    }

    nonisolated mutating func readVarint() throws -> UInt64 {
        var value: UInt64 = 0
        var shift: UInt64 = 0

        while offset < bytes.count {
            let byte = bytes[offset]
            offset += 1
            value |= UInt64(byte & 0x7f) << shift
            if byte & 0x80 == 0 {
                return value
            }
            shift += 7
            if shift >= 64 {
                throw ProtobufError.malformedVarint
            }
        }

        throw ProtobufError.truncated
    }

    nonisolated mutating func readLengthDelimited() throws -> [UInt8] {
        let length = Int(try readVarint())
        let end = offset + length
        guard length >= 0, end <= bytes.count else {
            throw ProtobufError.truncated
        }

        let payload = Array(bytes[offset..<end])
        offset = end
        return payload
    }

    nonisolated mutating func readString() throws -> String {
        let payload = try readLengthDelimited()
        return String(bytes: payload, encoding: .utf8) ?? ""
    }

    nonisolated mutating func skipValue(wireType: ProtobufWireType) throws {
        switch wireType {
        case .varint:
            _ = try readVarint()
        case .fixed64:
            try skipBytes(8)
        case .lengthDelimited:
            _ = try readLengthDelimited()
        case .fixed32:
            try skipBytes(4)
        }
    }

    nonisolated private mutating func skipBytes(_ count: Int) throws {
        let end = offset + count
        guard count >= 0, end <= bytes.count else {
            throw ProtobufError.truncated
        }
        offset = end
    }
}

private struct ProtobufField {
    let number: Int
    let wireType: ProtobufWireType
}

private enum ProtobufWireType: Int {
    case varint = 0
    case fixed64 = 1
    case lengthDelimited = 2
    case fixed32 = 5
}

private enum ProtobufError: Error {
    case malformedVarint
    case truncated
    case unsupportedWireType(Int)
}
