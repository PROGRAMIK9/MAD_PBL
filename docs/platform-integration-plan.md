# Platform Integration Plan

## Bluetooth LE / Wi-Fi Direct

- Use a platform channel at `offline_mesh/platform` for discovery and packet relay.
- Add Android native code for Bluetooth LE scanning and Wi-Fi Direct group formation.
- Add iOS native code for Bluetooth LE discovery and constrained peer discovery fallback.
- Keep the Flutter layer simulation-first so the UI remains usable without native plugins.

## Offline Maps

- Use an offline-capable tile cache and region downloads.
- Wire the app to a native Mapbox adapter when the SDK is added.
- Keep the current rescue map as a fallback preview for desktop and web.

## Recommended next plugin work

- `flutter_blue_plus` or equivalent for discovery.
- `wifi_direct`/native Android channel bridge for high-throughput relays.
- Mapbox offline SDK binding for region downloads and cached tile rendering.
