import 'package:flutter/foundation.dart';

class OfflineMapStatus {
  const OfflineMapStatus({
    required this.enabled,
    required this.downloadedRegion,
    required this.tilesCached,
    required this.providerLabel,
  });

  final bool enabled;
  final String downloadedRegion;
  final int tilesCached;
  final String providerLabel;
}

class OfflineMapService {
  const OfflineMapService();

  OfflineMapStatus current() {
    return const OfflineMapStatus(
      enabled: true,
      downloadedRegion: 'Emergency region pack',
      tilesCached: 1280,
      providerLabel: 'Mapbox offline SDK (planned)',
    );
  }

  String tileStrategy() {
    if (kIsWeb) {
      return 'Static rescue preview';
    }
    return 'Preloaded offline tiles with local cache';
  }
}
