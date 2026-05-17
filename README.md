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

The app now uses live Bluetooth discovery on Android and real device battery state on Android/iOS snapshots. The mesh UI is no longer seeded with fake peers; it reflects nearby devices as they appear.

## Recommended next step

Run the app on an Android device with Bluetooth permissions enabled to see live nearby-device discovery in action.

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

## Finalization work done

- Replaced mock peers with live discovery on Android (BLE native bridge).
- Added scaffolding for iOS BLE, Android Wi‑Fi Direct, and Mapbox offline integration.
- Added a Dart `RelayService` scaffold for deduplication and store-and-forward helpers.
- CI, packaging, and signing scaffolding present; production signing still requires user credentials.

## Remaining high-priority tasks

- Implement iOS native BLE discovery (requires macOS / Xcode and physical devices).
- Implement full Wi‑Fi Direct transport and native relay services (Android and iOS variants).
- Integrate Mapbox offline SDK on each platform and wire `OfflineMapService` to native implementations.
- Complete end-to-end encrypted packet relay and routing across devices (store-and-forward + dedupe + TTL).

## What I completed in this run

- Added Android AES‑GCM `CryptoHelper` and framed/encrypted Wi‑Fi Direct relay with retries.
- Added iOS BLE discovery and scaffold for background relay; wired discovery EventChannel.
- Added Mapbox native scaffolds (`MapboxService.kt`, `MapboxService.swift`) and updated `OfflineMapService` bridge.
- Added CI placeholder step for Android release build in `.github/workflows/flutter-ci.yml` and `docs/signing-and-provisioning.md`.

See `docs/signing-and-provisioning.md` for next steps to produce signed release artifacts.

If you want, I can continue implementing iOS BLE and Wi‑Fi Direct, but I will need an Apple/macOS environment and device testing access.
