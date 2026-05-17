package com.example.offline_mesh_app

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

class MainActivity : FlutterActivity() {
	private val channelName = "offline_mesh/platform"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
			when (call.method) {
				"snapshot" -> {
					result.success(
						mapOf(
							"bluetoothAvailable" to true,
							"wifiDirectAvailable" to true,
							"offlineMapsAvailable" to true,
							"platformLabel" to "android-${Locale.getDefault().language}",
						)
					)
				}
				"startDiscovery" -> result.success(null)
				"stopDiscovery" -> result.success(null)
				"broadcastEmergency" -> result.success(null)
				"shareLocationPacket" -> result.success(null)
				else -> result.notImplemented()
			}
		}
	}
}
