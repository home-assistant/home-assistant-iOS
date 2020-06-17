Home Assistant for iOS
=================

[![TestFlight Beta invite](https://img.shields.io/badge/TestFlight-Beta-blue.svg)](https://testflight.apple.com/join/XCUga7ko)
[![Download on the App Store](https://img.shields.io/itunes/v/1099568401.svg)](https://itunes.apple.com/app/home-assistant-open-source-home-automation/id1099568401)
[![Swift 3.0](https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat)](https://developer.apple.com/swift/)
[![Platform iOS](https://img.shields.io/badge/Platforms-iOS-lightgray.svg?style=flat)](https://developer.apple.com/swift/)
[![Build Status](https://travis-ci.org/home-assistant/home-assistant-iOS.svg?branch=master)](https://travis-ci.org/home-assistant/home-assistant-iOS)
[![codebeat badge](https://codebeat.co/badges/c6e6173b-c64f-44be-a692-29b922891db7)](https://codebeat.co/projects/github-com-home-assistant-home-assistant-ios)
[![GitHub issues](https://img.shields.io/github/issues/home-assistant/home-assistant-iOS.svg?style=flat)](https://github.com/home-assistant/home-assistant-iOS/issues)
[![License MIT](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/home-assistant/home-assistant-iOS/blob/master/LICENSE)
[![Twitter](https://img.shields.io/twitter/url/https/twitter.com/home_assistant.svg?style=social)](https://twitter.com/home_assistant)

## Getting Started

Run the following two commands to install Xcode's command line tools and bundler, if you don't have that yet.

```bash
[sudo] gem install bundler
xcode-select --install
```

The following commands will clone the repo and install all the required dependencies.

```bash
git clone https://github.com/home-assistant/home-assistant-iOS.git
cd home-assistant-iOS
bundle install
pod install --repo-update
bundle exec pod install
```

Now you can open `HomeAssistant.xcworkspace` and run the `HomeAssistant` target onto your simulator or iOS device.

## Code style

This project will follow the [GitHub Swift Styleguide](https://github.com/github/swift-style-guide) in every way possible.

In order to enforce this, the project will also have a [Swiftlint](https://github.com/realm/SwiftLint) build phase to run the linter everytime the app is built.

## Project Structure

To keep the Xcode layout mirrored with on-disk layout we're using [Synx](https://github.com/venmo/synx).

## Dependencies

### Model

- [ObjectMapper](https://github.com/Hearst-DD/ObjectMapper): Simple JSON Object mapping written in Swift

### Networking

- [Alamofire](https://github.com/Alamofire/Alamofire): Elegant HTTP Networking in Swift
- [AlamofireImage](https://github.com/Alamofire/AlamofireImage): AlamofireImage is an image component library for Alamofire
- [AlamofireNetworkActivityIndicator](https://github.com/Alamofire/AlamofireNetworkActivityIndicator): Controls the visibility of the network activity indicator on iOS using Alamofire.
- [AlamofireObjectMapper](https://github.com/tristanhimmelman/AlamofireObjectMapper): An Alamofire extension which converts JSON response data into swift objects using ObjectMapper
- [IKEventSource](https://github.com/inaka/EventSource): A simple Swift client library for Server Sent Events (SSE)

### UI

- [CPDAcknowledgements](https://github.com/CocoaPods/CPDAcknowledgements): Show your CocoaPods dependencies in-app.
- [Eureka](https://github.com/xmartlabs/Eureka): Elegant iOS form builder in Swift
- [FontAwesomeKit](https://github.com/robbiet480/FontAwesomeKit): Icon font library for iOS.
- [MBProgressHUD](https://github.com/jdg/MBProgressHUD): MBProgressHUD + Customizations
- [Whisper](https://github.com/hyperoslo/Whisper): Whisper is a component that will make the task of display messages and in-app notifications simple. It has three different views inside

### Translations
-  [Lokalise](https://lokalise.com/public/834452985a05254348aee2.46389241/): Translations are handled through Lokalise and not through this repository. To contribute to the translations please join the [Lokalise](https://lokalise.com/public/834452985a05254348aee2.46389241/) team.

### Utilities

- [DeviceKit](https://github.com/dennisweissmann/DeviceKit): DeviceKit is a value-type replacement of UIDevice.
- [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess): Simple Swift wrapper for Keychain that works on iOS and OS X
- [PromiseKit](https://github.com/mxcl/PromiseKit): Promises for Swift & ObjC
- [SwiftLocation](https://github.com/malcommac/SwiftLocation): Easy Location Manager and Beacon Monitoring in Swift sauce

### Environment

- [SwiftLint](https://github.com/realm/SwiftLint): A tool to enforce Swift style and conventions.
- [SwiftGen](https://github.com/AliSoftware/SwiftGen): A collection of Swift tools to generate Swift code (enums for your assets, storyboards, Localizable.strings, …)
- [Firebase](https://firebase.google.com/): Firebase gives you functionality like analytics, databases, messaging and crash reporting so you can move quickly and focus on your users.
- [Crashlytics](https://firebase.google.com/products/crashlytics): The most powerful, yet lightest weight crash reporting solution
- [Synx](https://github.com/venmo/synx): A command-line tool that reorganizes your Xcode project folder to match your Xcode groups
- [Fastlane](https://github.com/fastlane/fastlane): The easiest way to automate building and releasing your iOS and Android apps

## Continuous Integration

We are using [Travis](https://travis-ci.org/home-assistant/home-assistant-iOS) alongside [Fastlane](https://fastlane.tools/) to perform continuous integration both by unit testing and deploying to [App Store Connect](https://appstoreconnect.apple.com) later on.

### Environment variables

To make sure iTunes can deploy, make sure you have them set to something similar to the following environment variables. **The values are only examples!**.

**Note:** For ENV variables to work in Xcode you to set `$ defaults write com.apple.dt.Xcode UseSanitizedBuildSystemEnvironment -bool NO` and launch Xcode from the terminal. [Apple Developer Forums](https://forums.developer.apple.com/thread/8451)

#### Signing

- `HOMEASSISTANT_CERTIFICATE_KEY`: The Certificate key used in [Match](https://github.com/fastlane/fastlane/tree/master/match)
- `HOMEASSISTANT_CERTIFICATE_USER`: The username for the git being where Match is saving the Certificates.
- `HOMEASSISTANT_CERTIFICATE_TOKEN`: The access token for the git being where Match is saving the Certificates.
- `HOMEASSISTANT_CERTIFICATE_GIT`: The address or the git being where Match is saving the Certificates. (e.g. https://gitlab.com/username/Certificates)

#### iTunes deployment

- `HOMEASSISTANT_TEAM_ID`: Team ID from [iTunes Membership](https://developer.apple.com/account/#/membership)
- `HOMEASSISTANT_ITUNES_TEAM_ID`: Team ID from [iTunes Connect](https://itunesconnect.apple.com/). (`$ pilot list` to check the number)
- `HOMEASSISTANT_APPLE_ID`: Your Apple ID (e.g. john@apple.com)

### Deployment

Although all the deployment is done through Travis, you can do it manually through [Fastlane](https://github.com/home-assistant/home-assistant-iOS/blob/master/fastlane/README.md):

### Deployment to iTunes Connect

```bash
bundle exec fastlane itc
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## LICENSE

Apache-2.0

## Credits

The format and some content of this README.md comes from the [SwipeIt](https://github.com/ivanbruel/SwipeIt) project.
