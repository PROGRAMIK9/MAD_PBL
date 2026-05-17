# Offline Mesh Communication App

Flutter MVP for internet-free communication over nearby devices.

## Included

- Local mesh message simulation
- Emergency broadcast routing
- Peer status dashboard
- Topology visualization
- Offline map-style rescue screen
- AES-256 encryption helpers

## Notes

This repository contains the app source and architecture only. Native Bluetooth LE, Wi-Fi Direct, and Mapbox offline SDK integrations are structured for implementation, but platform-specific wiring still needs Flutter toolchain generation and device testing.

## Recommended next step

Run `flutter create .` in this folder, then add the generated Android and iOS platform directories if they are not already present.

## Local commands

- `Set-Location C:\MAD_PBL`
- `& 'C:\src\flutter\bin\flutter.bat' pub get`
- `& 'C:\src\flutter\bin\flutter.bat' analyze`
- `& 'C:\src\flutter\bin\flutter.bat' test`
- `& 'C:\src\flutter\bin\flutter.bat' run -d windows`

## Windows packaging

- `scripts\build_windows_installer.ps1`
- Portable output: `build/windows/installer/offline_mesh_app-windows-portable.zip`

## Release setup

- Android signing example: `android/key.properties.example`
- iOS signing notes: `ios/Flutter/Signing.xcconfig`
- Native platform bridge: `android/app/src/main/kotlin/com/example/offline_mesh_app/MainActivity.kt` and `ios/Runner/AppDelegate.swift`
- Android release checklist: `docs/android-signing-checklist.md`
- iOS release checklist: `docs/ios-signing-checklist.md`
- Android keystore generator: `scripts/create_android_keystore.ps1`