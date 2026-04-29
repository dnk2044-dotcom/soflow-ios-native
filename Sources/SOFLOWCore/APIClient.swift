// APIClient.swift
// HTTP API client for the SOFLOW backend.
//
// Backend: http://47.52.238.166:8080/  (Alibaba Cloud Hong Kong, plain HTTP).
// Source of truth: com/inuker/bluetooth/bledata/network/constant/NetConstant.java
// (`SERVICE_URI = "http://47.52.238.166:8080/"`).
//
// IMPORTANT: iOS App Transport Security blocks plain HTTP by default.
// Add this to Info.plist:
//
//   <key>NSAppTransportSecurity</key>
//   <dict>
//       <key>NSExceptionDomains</key>
//       <dict>
//           <key>47.52.238.166</key>
//           <dict>
//               <key>NSExceptionAllowsInsecureHTTPLoads</key>
//               <true/>
//           </dict>
//       </dict>
//   </dict>
//
// The exact endpoint paths (login, register, queryUnlockRecords, etc.) are
// NOT exposed in the decompiled bytecode in any easily-readable way: the
// SO ONE-PLUS app uses Retrofit interfaces that get heavily proguarded
// during the release build, so the @POST("…") annotations on the methods
// are stripped to obfuscated names. We've left scaffolding here for the
// endpoints we know exist by name from the compiled string-pool, but the
// full path strings will need to be observed via mitmproxy or Frida if
// fleet/account features are needed.
//
// For OFFLINE BLE-only use (the 90 % use case), this file is not used.

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

    // MARK: - Public API

    /// Mirror of LoginActivity → `loginV` endpoint. Path string is a
    /// best-guess from the string pool; replace with actual path if observed.
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

    /// Path token: `MSG_REGISTER` from the string pool.
    public func register(username: String, password: String, email: String) async throws {
        _ = try await postForm("register", fields: [
            "username": username, "password": password, "email": email
        ])
    }

    /// Path token: `QUERY_UNLOCK_RECORDS` / `QUERY_UNLOCK_RECORDS_NEW`
    public func queryUnlockRecords() async throws -> Data {
        return try await getJSON("queryUnlockRecords")
    }

    public func clearUnlockRecords() async throws {
        _ = try await postForm("clearUnlockRecords", fields: [:])
    }

    public func apiVersion() async throws -> Data {
        return try await getJSON("apiVersion")
    }

    // MARK: - Plumbing

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
