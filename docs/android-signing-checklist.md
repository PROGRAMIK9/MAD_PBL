# Android Signing Checklist

Use these values for the release build of Offline Mesh.

## Identifiers

- Application ID: `com.example.offline_mesh_app`
- Keystore alias: `offline_mesh_app`
- Keystore file: `android/app/upload-keystore.jks`
- Properties file: `android/key.properties`

## Steps

1. Run `scripts/create_android_keystore.ps1` and enter your passwords.
2. Keep `android/key.properties` and `android/app/upload-keystore.jks` out of git.
3. Confirm `android/app/build.gradle.kts` is using the release signing config.
4. Build a signed APK with `flutter build apk --release` or an App Bundle with `flutter build appbundle --release`.
5. Upload the signed artifact to Play Console or your private distribution channel.

## CI secrets

- Store the keystore password, key password, and keystore file in your secret store.
- Never print the passwords in logs.
