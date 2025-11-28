import Foundation

@available(macOS 12.0, iOS 15.0, *)
public final class EspoCRMClient: @unchecked Sendable {
    public private(set) var authSession: EspoAuthSession?
    public let configuration: EspoCRMConfiguration
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(configuration: EspoCRMConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    @discardableResult
    public func login(userName: String, password: String) async throws -> EspoAuthSession {
        struct Payload: Encodable { let userName: String; let password: String }
        let request = try buildRequest(
            path: "/api/v1/App/user/auth",
            method: .post,
            body: Payload(userName: userName, password: password),
            injectAuth: false
        )
        let auth: EspoAuthResponse = try await send(request)
        let session = EspoAuthSession(token: auth.token, refreshToken: auth.refreshToken, expiresAt: auth.expireAt)
        authSession = session
        return session
    }

    public func list<T: Decodable & Sendable>(
        entity: String,
        parameters: [URLQueryItem] = []
    ) async throws -> EspoListResponse<T> {
        let request = try buildRequest(path: "/api/v1/\(entity)", method: .get, query: parameters)
        return try await send(request)
    }

    public func fetch<T: Decodable & Sendable>(
        entity: String,
        id: String,
        select: [String]? = nil
    ) async throws -> T {
        var query: [URLQueryItem] = []
        if let select { query.append(URLQueryItem(name: "select", value: select.joined(separator: ","))) }
        let request = try buildRequest(path: "/api/v1/\(entity)/\(id)", method: .get, query: query)
        return try await send(request)
    }

    @discardableResult
    public func create<T: Decodable & Sendable>(
        entity: String,
        body: Encodable
    ) async throws -> T {
        let request = try buildRequest(path: "/api/v1/\(entity)", method: .post, body: body)
        return try await send(request)
    }

    @discardableResult
    public func update<T: Decodable & Sendable>(
        entity: String,
        id: String,
        body: Encodable
    ) async throws -> T {
        let request = try buildRequest(path: "/api/v1/\(entity)/\(id)", method: .patch, body: body)
        return try await send(request)
    }

    private func buildRequest(
        path: String,
        method: HTTPMethod,
        query: [URLQueryItem] = [],
        body: Encodable? = nil,
        injectAuth: Bool = true
    ) throws -> URLRequest {
        guard var components = URLComponents(url: configuration.baseURL, resolvingAgainstBaseURL: false) else {
            throw EspoCRMError.invalidURL
        }
        components.path = components.path.appending(path)
        components.queryItems = query.isEmpty ? nil : query
        guard let url = components.url else { throw EspoCRMError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let apiKey = configuration.apiKey {
            request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")
        }
        if injectAuth {
            guard let token = authSession?.token ?? configuration.apiKey else { throw EspoCRMError.missingAuthToken }
            if configuration.apiKey == nil {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }
        if let body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }
        return request
    }

    private func send<T: Decodable & Sendable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EspoCRMError.httpStatus(-1, "Invalid response")
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 { throw EspoCRMError.unauthorized }
            let message = String(data: data, encoding: .utf8) ?? "No message"
            throw EspoCRMError.httpStatus(httpResponse.statusCode, message)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw EspoCRMError.decoding(error.localizedDescription)
        }
    }
}

private struct AnyEncodable: Encodable {
    private let encodeClosure: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        encodeClosure = wrapped.encode(to:)
    }

    func encode(to encoder: Encoder) throws {
        try encodeClosure(encoder)
    }
}
