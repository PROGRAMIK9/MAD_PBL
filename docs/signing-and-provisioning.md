# Signing and Provisioning Notes

Android
- Place your `keystore` and fill `android/key.properties` with `storePassword`, `keyPassword`, `keyAlias`, and `storeFile` path.
- In CI, provide these values as secrets and inject into `android/key.properties` during the workflow.
- Example gradle command to build release after configuring signing: `./gradlew assembleRelease -p android`.

iOS
- Use Xcode to create provisioning profiles and export a signing certificate.
- CI signing requires `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` or using `match`/`cert` automation; we did not enable automatic iOS signing here.

Key distribution
- Current implementation expects a symmetric AES key (base64) to be set via `setSymmetricKey` on both peers before exchanging messages.
- For secure key agreement, implement ECDH (Curve25519) and derive symmetric keys via HKDF. Do NOT hard-code keys in source.
