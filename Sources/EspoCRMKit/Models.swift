import Foundation

public struct EspoCRMConfiguration: Sendable, Equatable {
    public let baseURL: URL
    public let apiKey: String?

    public init(baseURL: URL, apiKey: String? = nil) {
        self.baseURL = baseURL
        self.apiKey = apiKey
    }
}

public struct EspoAuthSession: Codable, Equatable, Sendable {
    public let token: String
    public let refreshToken: String?
    public let expiresAt: Date?

    public init(token: String, refreshToken: String? = nil, expiresAt: Date? = nil) {
        self.token = token
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }
}

public struct EspoListResponse<T: Decodable & Sendable>: Decodable, Sendable {
    public let total: Int?
    public let list: [T]
}

public struct EspoRecord: Codable, Equatable, Sendable {
    public let id: String?
    public let type: String?
    public var attributes: [String: JSONValue]

    public init(id: String?, type: String?, attributes: [String: JSONValue]) {
        self.id = id
        self.type = type
        self.attributes = attributes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        var attrs: [String: JSONValue] = [:]
        var foundId: String?
        var foundType: String?

        for key in container.allKeys {
            switch key.stringValue {
            case "id":
                foundId = try container.decodeIfPresent(String.self, forKey: key)
            case "_type":
                foundType = try container.decodeIfPresent(String.self, forKey: key)
            default:
                attrs[key.stringValue] = try container.decode(JSONValue.self, forKey: key)
            }
        }

        id = foundId
        type = foundType
        attributes = attrs
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        try container.encodeIfPresent(id, forKey: DynamicCodingKeys(stringValue: "id")!)
        try container.encodeIfPresent(type, forKey: DynamicCodingKeys(stringValue: "_type")!)
        for (key, value) in attributes {
            try container.encode(value, forKey: DynamicCodingKeys(stringValue: key)!)
        }
    }
}

struct EspoAuthResponse: Decodable {
    let token: String
    let refreshToken: String?
    let expireAt: Date?
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
}

enum EspoCRMError: Error, LocalizedError {
    case invalidURL
    case missingAuthToken
    case httpStatus(Int, String)
    case decoding(String)
    case unauthorized

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .missingAuthToken:
            return "Authentication token missing. Call login or provide apiKey."
        case .httpStatus(let code, let message):
            return "Request failed with HTTP \(code): \(message)"
        case .decoding(let message):
            return "Failed to decode response: \(message)"
        case .unauthorized:
            return "Unauthorized. Token may be expired or invalid."
        }
    }
}

struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    init?(stringValue: String) { self.stringValue = stringValue }
    var intValue: Int? { nil }
    init?(intValue: Int) { nil }
}
