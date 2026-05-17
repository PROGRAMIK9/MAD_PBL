# Signing Guide

## Android

1. Create a keystore with `keytool`.
2. Add `android/key.properties` locally with your keystore password and alias.
3. Configure `android/app/build.gradle.kts` to use the signing config for release builds.
4. Store passwords and keystore files in secure secret storage; do not commit them.

## iOS

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Set the signing team and bundle identifier in the Runner target.
3. Create or download a provisioning profile for release distribution.
4. Keep signing certificates in Apple Developer tooling or CI secrets.
