# eRideSafe

An iOS app for e-bike classification, rider education, safety maps, ride alerts,
and community safety reports. Built with SwiftUI and Firebase.

## Open and run

1. Clone this repository and open `eRideSafe.xcodeproj` in Xcode.
2. Allow Xcode to resolve the Swift package dependencies.
3. Download the iOS app configuration from your Firebase project and place it at
   `eRideSafe/Resources/GoogleService-Info.plist`. The Xcode project already
   references this file. Local Firebase configuration is excluded from Git.
4. Select your development team under **Signing & Capabilities** if running on a
   physical device, then select a simulator or device and run the app.

The app uses Firebase Authentication and Cloud Firestore. Backend rules are in
`firebase/firestore.rules`; the repository does not deploy them automatically.

## Documentation

- [Beginner walkthrough](docs/beginner-walkthrough.md)
- [Technical walkthrough](docs/technical-walkthrough.md)
- [Safety map data](docs/map-data.md)

Build outputs, temporary work, and personal Xcode settings are excluded from
version control.
