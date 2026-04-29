// APIClient.swift
import Foundation

public actor APIClient {
    public static let shared = APIClient()

    private let session: URLSession
    private(set) public var token: String?

    private init() {
        let cfg = URLSessionConfiguration.default
        cfg.waitsForConnectivity = true
        cfg.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: cfg)
    }

    public func login(username: String, password: String) async throws {
        let resp = try await postForm("loginV", fields: [
            "username": username,
            "password": password
        ])
        if let t = parseTokenFromJSON(resp) {
            self.token = t
        } else {
            throw APIError.noToken
        }
    }

    public func register(username: String, password: String, email: String) async throws {
        _ = try await postForm("register", fields: [
            "username": username, "password": password, "email": email
        ])
    }

    public func queryUnlockRecords() async throws -> Data {
        return try await getJSON("queryUnlockRecords")
    }

    public func clearUnlockRecords() async throws {
        _ = try await postForm("clearUnlockRecords", fields: [:])
    }

    public func apiVersion() async throws -> Data {
        return try await getJSON("apiVersion")
    }

    public func postForm(_ path: String, fields: [String: String]) async throws -> Data {
        var req = URLRequest(url: SOFLOWNet.baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        if let token { req.setValue(token, forHTTPHeaderField: "Authorization") }
        let body = fields
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
        req.httpBody = Data(body.utf8)
        let (data, resp) = try await session.data(for: req)
        try checkHTTP(resp)
        return data
    }

    public func getJSON(_ path: String) async throws -> Data {
        var req = URLRequest(url: SOFLOWNet.baseURL.appendingPathComponent(path))
        if let token { req.setValue(token, forHTTPHeaderField: "Authorization") }
        let (data, resp) = try await session.data(for: req)
        try checkHTTP(resp)
        return data
    }

    private func checkHTTP(_ resp: URLResponse) throws {
        guard let http = resp as? HTTPURLResponse else { return }
        if !(200..<300).contains(http.statusCode) {
            throw APIError.httpStatus(http.statusCode)
        }
    }

    private func parseTokenFromJSON(_ data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json["token"] as? String
            ?? (json["data"] as? [String: Any])?["token"] as? String
    }
}

public enum APIError: Error, CustomStringConvertible {
    case httpStatus(Int)
    case noToken
    public var description: String {
        switch self {
        case .httpStatus(let c): return "HTTP \(c)"
        case .noToken: return "Server response did not contain an auth token"
        }
    }
}
