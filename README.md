# Camera Protractor

Camera Protractor is a SwiftUI iOS app that combines a live camera preview, motion-based angle readings, a protractor overlay, photo capture, and local measurement history.

## Features

- Live rear-camera preview with an angle guide overlay.
- Core Motion angle readings for pitch and roll.
- Capture measurement photos locally.
- Save and browse measurement history on-device.
- SwiftUI app structure organized into Models, Services, ViewModels, and Views.

## Requirements

- Xcode 16 or newer
- iOS 16.0 or newer

## Build

Open `CameraProtractor.xcodeproj` in Xcode, select the `Camera Protractor` scheme, and run on an iPhone device or simulator.

For a command-line build:

```sh
xcodebuild \
  -project CameraProtractor.xcodeproj \
  -scheme "Camera Protractor" \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath Build/DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Privacy

Camera Protractor stores measurement data locally and does not include backend, analytics, tracking, or network calls. Camera access is requested to show the live preview and capture measurement photos.
