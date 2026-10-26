# eRideSafe

An iOS app for e-bike safety. Repository created for Congressional App Challenge

## Copyright and permissions

Copyright (c) 2026 Annirudh Raman. **All rights reserved.**

This repository is public for Congressional App Challenge. It is not open source, and public
visibility does not grant general permission to reuse, redistribute, or modify
the original project. See [LICENSE](LICENSE) for the terms and exceptions,
including rights under GitHub's Terms of Service and third-party licenses.

## Development setup

These instructions are for the copyright holder and authorized developers or
reviewers.

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
