//
//  StravaLogIn.swift
//  StravaLoginSDK
//
//  Created by fjswrk on 2020/08/18.
//  Copyright © 2020 fjsw.work. All rights reserved.
//

import AuthenticationServices
import Foundation
import UIKit

public class StravaLogIn: NSObject {
    public typealias StravaCredentialHandler = ((_ credential: StravaCredential?, _ error: Error?) -> Void)?
    private typealias StravaWebLoginHandler = (URL?, Error?) -> Void
    
    public enum ApprovalPrompt: String {
        case auto = "auto"
        case force = "force"
    }

    public enum Scope: String {
        case activityRead = "activity:read"
        case activityReadAll = "activity:read_all"
        case activityWrite = "activity:write"
        case profileReadAll = "profile:read_all"
        case profileWrite = "profile:write"
        case read = "read"
        case readAll = "read_all"
    }
    
    private enum GrantType: String {
        case authorizationCode = "authorization_code"
        case refreshToken = "refresh_token"
    }
    
    private enum HttpMethod: String {
        case get = "GET"
        case post = "POST"
    }
    
    private enum Endpoint: String {
        case webLogin = "https://www.strava.com/oauth/authorize"
        case appLogin = "strava://oauth/mobile/authorize"
        case token = "https://www.strava.com/oauth/token"
        case logout = "https://www.strava.com/oauth/deauthorize"
    }
    
    private enum QueryItem: Equatable {
        case clientID
        case redirectURI
        case responseType
        case approvalPrompt
        case scope
        case state
        case accessToken
        case clientSecret
        case grantType(GrantType?)
        case code(String?)
        case refreshToken
        
        var name: String {
            switch self {
                case .clientID: return  "client_id"
                case .redirectURI: return "redirect_uri"
                case .responseType: return "response_type"
                case .approvalPrompt: return "approval_prompt"
                case .scope: return "scope"
                case .state: return "state"
                case .accessToken: return "access_token"
                case .clientSecret: return "client_secret"
                case .grantType: return "grant_type"
                case .code: return "code"
                case .refreshToken: return "refresh_token"
            }
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.name == rhs.name
        }
    }
    
    public static let shared: StravaLogIn = StravaLogIn()
    
    public weak var delegate: StravaLogInDelegate?
    public weak var presentingViewController: UIViewController?
    public var clientID: String?
    public var clientSecret: String?
    public var redirectURI: String?
    public let responseType: String = "code"
    public var approvalPrompt: ApprovalPrompt? = ApprovalPrompt.auto
    public var scope: Set<Scope>?
    public var state: String?
    public var callbackUrlScheme: String?
    
    public private(set) var currentCredential: StravaCredential? {
        get {
            StravaCredential.current
        }
        set {
            StravaCredential.current = newValue
        }
    }
    
    private let LOGIN_CREDENTIAL_KEY = "strava-login-credential"
    private var webAuthSession: ASWebAuthenticationSession?
    private var dataTask: URLSessionTask?
    private var isRefreshingToken: Bool = false
    
    public func isLogin() -> Bool  {
        currentCredential != nil
    }
    
    public func logIn() {
        // use STRAVA app to log in
        if let appLoginURL = makeAppLogInURL(), UIApplication.shared.canOpenURL(appLoginURL) {
            UIApplication.shared.open(appLoginURL, options: [:])
            return
        }
        
        // use STRAVA web to log in
        guard let presentingViewController = presentingViewController else {
            delegate?.didLogIn(credential: nil, error: StravaLoginError.notSettingPresentingViewController)
            return
        }
        
        signInUseWeb(presentingViewController: presentingViewController) { [weak self] (url, error) in
            if let error = error {
                self?.delegate?.didLogIn(credential: nil, error: StravaLoginError.loginRequestFailed(error: error))
                return
            }
            
            guard let url = url else {
                self?.delegate?.didLogIn(credential: nil, error: StravaLoginError.noLoginResponse)
                return
            }
            
            self?.handle(url: url)
        }
    }
    
    @discardableResult
    public func handle(url: URL) -> Bool {
        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let failureReason = urlComponents?.queryItems?.first(where: { $0.name == "error" })?.value {
            self.delegate?.didLogIn(credential: nil, error: StravaLoginError.tokenExchangeFailed(failureReason: failureReason))
            return false
        }
        
        guard let code = urlComponents?.queryItems?.first(where: { $0.name == responseType })?.value else {
            self.delegate?.didLogIn(credential: nil, error: StravaLoginError.noTokenExchangeResponse)
            return false
        }
        exchangeWithCredential(code: code)
        return true
    }
    
    public func logOut() {
        guard isLogin() else {
            self.delegate?.didLogOut(error: StravaLoginError.notLogin)
            return
        }
        
        guard let url = makeLogOutURL() else {
            self.delegate?.didLogOut(error: StravaLoginError.invalidURL)
            return
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HttpMethod.post.rawValue
        
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self?.delegate?.didLogOut(error: StravaLoginError.logoutRequestFailed(error: error))
                    return
                }
                self?.currentCredential = nil
                self?.delegate?.didLogOut(error: nil)
            }
        }
        dataTask.resume()
        
        self.dataTask = dataTask
    }
    
    public func refreshTokens(handler: StravaCredentialHandler) {
        guard isLogin() else {
            handler?(nil, StravaLoginError.notLogin)
            return
        }
        
        guard !isRefreshingToken else {
            handler?(nil, StravaLoginError.alreadyRefreshing)
            return
        }
        isRefreshingToken = true
        
        guard let url = makeRefreshTokensURL() else {
            handler?(nil, StravaLoginError.invalidURL)
            return
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = HttpMethod.post.rawValue
        
        let dataTask = URLSession.shared.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            DispatchQueue.main.async {
                self?.isRefreshingToken = false
                
                if let error = error {
                    handler?(nil, StravaLoginError.refreshTokenRequestFailed(error: error))
                    return
                }
                
                guard let credentialData = data else {
                    handler?(nil, StravaLoginError.noRefreshTokenResponse)
                    return
                }
                
                do {
                    let jsonDecoder = JSONDecoder()
                    jsonDecoder.dateDecodingStrategy = .secondsSince1970
                    let credential = try jsonDecoder.decode(StravaCredential.self, from: credentialData)
                    
                    self?.currentCredential = credential
                    handler?(credential, nil)
                } catch {
                    handler?(nil, StravaLoginError.decodeRefreshTokenFailed(error: error))
                }
            }
        }
        dataTask.resume()
        
        self.dataTask = dataTask
    }
    
    private func makeURL(endpoint: Endpoint, queryNames: [QueryItem]) -> URL? {
        let queryItems: [URLQueryItem] = queryNames.map {
            let queryItem = $0
            let queryNameString = $0.name
            
            switch queryItem {
            case .clientID: return URLQueryItem(name: queryNameString, value: clientID)
            case .clientSecret: return URLQueryItem(name: queryNameString, value: clientSecret)
            case .redirectURI: return URLQueryItem(name: queryNameString, value: redirectURI)
            case .responseType: return URLQueryItem(name: queryNameString, value: responseType)
            case .approvalPrompt: return URLQueryItem(name: queryNameString, value: approvalPrompt?.rawValue)
            case .code(let value): return URLQueryItem(name: queryNameString, value: value)
            case .scope: return URLQueryItem(name: queryNameString, value: scope?.map { $0.rawValue }.joined())
            case .state: return URLQueryItem(name: queryNameString, value: state)
            case .refreshToken: return URLQueryItem(name: queryNameString, value: currentCredential?.refreshToken)
            case .accessToken: return URLQueryItem(name: queryNameString, value: currentCredential?.accessToken)
            case .grantType(let value): return URLQueryItem(name: queryNameString, value: value?.rawValue)
            }
        }
        
        var urlComponents = URLComponents(string: endpoint.rawValue)
        urlComponents?.queryItems = queryItems
        
        return urlComponents?.url
    }
    
    private func makeAppLogInURL() -> URL? {
        makeURL(endpoint: .appLogin, queryNames: [
            .clientID, .redirectURI, .responseType, .approvalPrompt, .scope, .state
        ])
    }
    
    private func makeWebLogInURL() -> URL? {
        makeURL(endpoint: .webLogin, queryNames: [
            .clientID, .redirectURI, .responseType, .approvalPrompt, .scope, .state
        ])
    }
    
    private func makeLogOutURL() -> URL? {
        makeURL(endpoint: .logout, queryNames: [
            .accessToken
        ])
    }
    
    private func makeTokenExchangeURL(code: String) -> URL?  {
        makeURL(endpoint: .token, queryNames: [
            .clientID, .clientSecret, .code(code), .grantType(.authorizationCode)
        ])
    }
    
    private func makeRefreshTokensURL() -> URL?  {
        makeURL(endpoint: .token, queryNames: [
            .clientID, .clientSecret, .grantType(.refreshToken), .refreshToken
        ])
    }
    
    private func signInUseWeb(presentingViewController: UIViewController, completion: @escaping StravaWebLoginHandler) {
        guard let webLoginURL = makeWebLogInURL() else {
            // TODO: replace suitable error
            completion(nil, StravaLoginError.unknown)
            return
        }
        
        let authSession = ASWebAuthenticationSession(url: webLoginURL, callbackURLScheme: callbackUrlScheme) { (url, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            completion(url, nil)
        }
        authSession.presentationContextProvider = self
        authSession.start()
        
        self.webAuthSession = authSession
    }
    
    private func exchangeWithCredential(code: String) {
        guard let url = makeTokenExchangeURL(code: code) else {
            self.delegate?.didLogIn(credential: nil, error: StravaLoginError.invalidURL)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = HttpMethod.post.rawValue
        
        let dataTask = URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) in
            DispatchQueue.main.async {
                
                if let error = error {
                    self?.delegate?.didLogIn(credential: nil, error: error)
                    return
                }
                
                guard let credentialData = data else {
                    self?.delegate?.didLogIn(credential: nil, error: StravaLoginError.unknown)
                    return
                }
            
                do {
                    let jsonDecoder = JSONDecoder()
                    jsonDecoder.dateDecodingStrategy = .secondsSince1970
                    let credential = try jsonDecoder.decode(StravaCredential.self, from: credentialData)
                    
                    self?.currentCredential = credential
                    self?.delegate?.didLogIn(credential: credential, error: nil)
                } catch {
                    self?.delegate?.didLogIn(credential: nil, error: error)
                }
            }
        }
        
        dataTask.resume()
        
        self.dataTask = dataTask
    }
}

extension StravaLogIn: ASWebAuthenticationPresentationContextProviding {
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        presentingViewController?.view.window ?? ASPresentationAnchor()
    }
}
