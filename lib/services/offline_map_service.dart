import 'package:flutter/services.dart';
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
  static const MethodChannel _channel = MethodChannel('offline_mesh/map');

  const OfflineMapService();

  Future<bool> downloadRegion(String regionId, Map<String, dynamic> options) async {
    final res = await _channel.invokeMethod('downloadRegion', {'regionId': regionId, 'options': options});
    return res == true;
  }

  Future<void> removeRegion(String regionId) async {
    await _channel.invokeMethod('removeRegion', {'regionId': regionId});
  }

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
