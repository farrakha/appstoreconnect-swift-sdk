//
//  BetaGroupRelationship.swift
//  AppStoreConnect-Swift-SDK
//
//  Created by Pascal Edmond on 17/11/2018.
//

import Foundation

public enum BetaGroupRelationship: Codable {
    case app(App)
    case build(Build)
    case betaTester(BetaTester)
    
    enum CodingKeys: String, Decodable, CodingKey {
        case type
        case apps, builds, betaTesters
    }

    public init(from decoder: Decoder) throws {
        switch try decoder.container(keyedBy: CodingKeys.self).decode(CodingKeys.self, forKey: .type) {
        case .apps:
            self = try .app(App(from: decoder))
        case .builds:
            self = try .build(Build(from: decoder))
        case .betaTesters:
            self = try .betaTester(BetaTester(from: decoder))
        default:
            throw DecodingError.typeMismatch(
                BetaGroupRelationship.self,
                DecodingError.Context(codingPath: [], debugDescription: "Not convertable to \(BetaGroupRelationship.self)")
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        switch self {
        case .app(let value):
            try value.encode(to: encoder)
        case .build(let value):
            try value.encode(to: encoder)
        case .betaTester(let value):
            try value.encode(to: encoder)
        }
    }
}
