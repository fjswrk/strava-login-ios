#
#  Be sure to run `pod spec lint StravaLoginSDK.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|
  spec.name         = "StravaLoginSDK"
  spec.version      = "0.0.1"
  spec.summary      = "Provide strava authorization function to use strava api"
  spec.homepage     = "https://github.com/fjswrk/strava-login-ios"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "fjsw" => "ffsj1975@gmail.com" }
  spec.platform     = :ios, "13.0"
  spec.source       = { :git => "https://github.com/fjswrk/strava-login-ios.git", :tag => "#{spec.version}" }
  spec.requires_arc = true
  spec.source_files = 'StravaLoginSDK/*.{h,swift}'
  spec.swift_version = '5.0'
end
