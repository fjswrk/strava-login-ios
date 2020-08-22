//
//  ViewController.swift
//  Example
//
//  Created by fjswrk on 2020/08/19.
//  Copyright © 2020 fjsw.work. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var loginLogoutBarButton: UIBarButtonItem!
    @IBOutlet weak var getProfileBarButton: UIBarButtonItem!
    @IBOutlet weak var profileTextView: UITextView!
    var isLogin: Bool {
        StravaLogIn.shared.isLogin()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: fix this
        StravaLogIn.shared.clientSecret = "YOUR-CLIENT-SECRET"
        // TODO: fix this
        StravaLogIn.shared.clientID = "YOUR-CLIENT-ID"
        // TODO: fix this
        StravaLogIn.shared.redirectURI = "stravaloginsdkexample://" + "YOUR-DOMAIN"
        StravaLogIn.shared.callbackUrlScheme = "stravaloginsdkexample://"
        StravaLogIn.shared.scope = [.activityReadAll]
        StravaLogIn.shared.presentingViewController = self
        StravaLogIn.shared.delegate = self
        
        updateSubViews()
    }

    @IBAction func tapLoginLogoutButton(_ sender: Any) {
        if isLogin {
            StravaLogIn.shared.logOut()
        } else {
            StravaLogIn.shared.logIn()
        }
    }
    
    @IBAction func tapGetProfileButton(_ sender: Any) {
        guard let requireRefreshTokens = StravaLogIn.shared.currentCredential?.requiresRefresh else {
            updateSubViews()
            return
        }
        
        if requireRefreshTokens {
            StravaLogIn.shared.refreshTokens { [weak self] (credential, error) in
                self?.getProfile()
            }
        } else {
            self.getProfile()
        }
    }
    
    private func getProfile() {
        guard let accessToken = StravaLogIn.shared.currentCredential?.accessToken else {
            return
        }
        
        var urlRequest = URLRequest(url: URL(string: "https://www.strava.com/api/v3/athlete")!)
        urlRequest.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self?.profileTextView.text = error.localizedDescription
                    return
                }

                if let data = data, let profileText = String(data: data, encoding: .utf8) {
                    self?.profileTextView.text = profileText
                }
            }
        }
        .resume()
    }
    
    private func updateSubViews(error: Error? = nil) {
        if let error = error {
            profileTextView.text = error.localizedDescription
            return
        }
        
        if isLogin {
            loginLogoutBarButton.title = "LOGOUT"
            getProfileBarButton.title = "GET PROFILE"
            profileTextView.text = "Login"
        } else {
            loginLogoutBarButton.title = "LOGIN"
            getProfileBarButton.title = ""
            profileTextView.text = "Not Login"
        }
    }
}

extension ViewController: StravaLogInDelegate {
    func didLogIn(credential: StravaCredential?, error: Error?) {
        updateSubViews(error: error)
    }
    
    func didLogOut(error: Error?) {
        updateSubViews(error: error)
    }
}
