# iOS Signing Checklist

Use these values for the Offline Mesh release build.

## Identifiers

- Bundle identifier: `com.example.offlineMeshApp`
- Team ID: `YOUR_TEAM_ID`
- Product name: `Offline Mesh`

## Steps

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Set the Runner target bundle identifier to `com.example.offlineMeshApp`.
3. Select your Apple Developer team for signing.
4. Enable automatic signing or attach a release provisioning profile.
5. Confirm the release config matches `ios/Flutter/Signing.xcconfig`.
6. Archive with `Product > Archive` and export the build for TestFlight or App Store Connect.

## Notes

- Keep certificates and provisioning profiles in Apple Developer tooling or CI secret storage.
- Update `YOUR_TEAM_ID` before submitting a release build.
