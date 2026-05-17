# Release Notes

## Windows Desktop

- The app builds and runs on Windows using Flutter desktop support.
- A Windows installer can be produced from the release output in `build/windows/x64/runner/Release`.

## Android and iOS signing

- Android: create a keystore and configure `android/key.properties` plus Gradle signing config.
- iOS: configure signing in Xcode with a team, bundle identifier, and provisioning profile.
- Store signing secrets in CI secret storage and never commit them.
