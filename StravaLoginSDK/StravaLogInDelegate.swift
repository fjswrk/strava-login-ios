//
//  StravaLogInDelegate.swift
//  StravaLogIn
//
//  Created by fjswrk on 2020/08/18.
//  Copyright © 2020 fjsw.work. All rights reserved.
//

import Foundation

public protocol StravaLogInDelegate: NSObjectProtocol {
    func didLogIn(credential: StravaCredential?, error: Error?)
    func didLogOut(error: Error?)
}
