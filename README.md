# strava-login-ios
This is to simplify the acquisition of permissions to use the Strava API in iOS apps.

# DEMO
## LogIn
```swift
StravaLogIn.shared.logIn()
```

## AccessToken
```swift
StravaLogIn.shared.currentCredential?.accessToken
```

## LogOut
```swift
StravaLogIn.shared.logOut()
```

## Whether you are logged in
```swift
StravaLogIn.shared.isLogin
```

## Refresh Tokens
```swift
StravaLogIn.shared.refreshTokens { [weak self] (credential, error) in
    // implement
}
```

## Require refresh Tokens
```swift
StravaLogIn.shared.currentCredential?.requiresRefresh
```

# Requirement
* iOS 13.0 ~

# Installation
## CocoaPods
You can use [CocoaPods](http://cocoapods.org/) to install `StravaLoginSDK` by adding it to your `Podfile`:

```ruby
platform :ios, '13.0'
use_frameworks!
pod 'StravaLoginSDK'
```

#### Carthage
Create a `Cartfile` that lists the framework and run `carthage update`. Follow the [instructions](https://github.com/Carthage/Carthage#if-youre-building-for-ios) to add `$(SRCROOT)/Carthage/Build/iOS/StravaLoginSDK.framework` to an iOS project.

```
github "fjswrk/strava-login-ios"
```

# Usage
## Precondition
Go to https://www.strava.com/settings/api and create an app.

See detail
https://developers.strava.com/docs/getting-started/#account

## Setting
### Info.plist(if needs)
If you log in using the Strava App instead of the web, add the Strava App URL Scheme to Info.plist

```
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>strava</string>
</array>
```

### Implement(requirement)
```swift
// Specify your app client id
StravaLogIn.shared.clientSecret = "YOUR-CLIENT-SECRET"

// Specify your app client id
StravaLogIn.shared.clientID = "YOUR-CLIENT-ID"

// Specify app redirect uri
StravaLogIn.shared.redirectURI = "YOUR-APP-URL-SCHEME://" + "YOUR-DOMAIN"

// Specify your app url scheme
StravaLogIn.shared.callbackUrlScheme = "YOUR-APP-URL-SCHEME://"

// Specify the required permissions
StravaLogIn.shared.scope = [.activityReadAll]

// Specify presenting view controller
StravaLogIn.shared.presentingViewController = self

// Specify Delegate login process completion process
StravaLogIn.shared.delegate = self

```

# Execution
## LogIn
```swift
StravaLogIn.shared.logIn()
```

## LogOut
```swift
StravaLogIn.shared.logOut()
```

## Whether you are logged in
```swift
StravaLogIn.shared.isLogin
```

## Refresh Tokens
```swift
StravaLogIn.shared.refreshTokens { [weak self] (credential, error) in
    // implement
}
```

## Require refresh Tokens
```swift
StravaLogIn.shared.currentCredential?.requiresRefresh
```

## Example
Open Example/Example.xcodeproj, set up Implement(requirement) section.

# License
strava-login-ios is released under the MIT license. See LICENSE for details.
