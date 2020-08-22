//
//  StravaLoginError.swift
//  StravaLoginSDK
//
//  Created by fjswrk on 2020/08/19.
//  Copyright © 2020 fjsw.work. All rights reserved.
//

import Foundation

public enum StravaLoginError: Swift.Error {
    case invalidURL
    case notLogin
    case alreadyRefreshing
    case refreshTokenRequestFailed(error: Error)
    case decodeRefreshTokenFailed(error: Error)
    case logoutRequestFailed(error: Error)
    case notSettingPresentingViewController
    case loginRequestFailed(error: Error)
    case noLoginResponse
    case noRefreshTokenResponse
    case tokenExchangeFailed(failureReason: String)
    case noTokenExchangeResponse
    case unknown
}
