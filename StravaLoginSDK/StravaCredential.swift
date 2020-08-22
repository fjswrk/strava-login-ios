//
//  StravaCredential.swift
//  StravaSignIn
//
//  Created by fjswrk on 2020/08/18.
//  Copyright © 2020 fjsw.work. All rights reserved.
//

import Foundation

public class StravaCredential: NSObject, Codable {
    static var current: StravaCredential? {
        get {
            guard let data = UserDefaults.standard.data(forKey: LOGIN_CREDENTIAL_KEY) else { return nil }
            return try? JSONDecoder().decode(StravaCredential.self, from: data)
        }
        set {
            if let credential = newValue {
                UserDefaults.standard.set(try? JSONEncoder().encode(credential), forKey: LOGIN_CREDENTIAL_KEY)
            } else {
                UserDefaults.standard.removeObject(forKey: LOGIN_CREDENTIAL_KEY)
            }
        }
    }
    private static let LOGIN_CREDENTIAL_KEY = "strava-login-credential"
    
    public let tokenType: String
    public let expiresAt: Date
    public let expiresIn: TimeInterval
    public let refreshToken: String
    public let accessToken: String
    public var timeIntervalBeforeExpires: TimeInterval = 60
    
    public var requiresRefresh: Bool {
        Date(timeIntervalSinceNow: timeIntervalBeforeExpires * -1) > expiresAt
    }
    
    enum CodingKeys: String, CodingKey {
        case tokenType = "token_type"
        case expiresAt = "expires_at"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case accessToken = "access_token"
    }
}
