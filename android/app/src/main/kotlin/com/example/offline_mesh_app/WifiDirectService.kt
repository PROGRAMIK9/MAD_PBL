package com.example.offline_mesh_app

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.net.wifi.p2p.WifiP2pDevice
import android.net.wifi.p2p.WifiP2pManager
import android.os.Build
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.EventChannel

// Wi‑Fi Direct service: discovers peers and emits events to Flutter via EventChannel sink.
class WifiDirectService(private val context: Context) {
    private val manager: WifiP2pManager? =
        context.getSystemService(Context.WIFI_P2P_SERVICE) as? WifiP2pManager
    private val channel: WifiP2pManager.Channel? = manager?.initialize(context, context.mainLooper, null)

    private var eventSink: EventChannel.EventSink? = null
    private var receiver: BroadcastReceiver? = null

    fun attachSink(sink: EventChannel.EventSink?) {
        eventSink = sink
    }

    fun startDiscovery() {
        if (manager == null || channel == null) {
            eventSink?.error("wifidirect_unavailable", "Wi‑Fi Direct manager unavailable", null)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                eventSink?.error("permissions_missing", "ACCESS_FINE_LOCATION required for Wi‑Fi Direct discovery.", null)
                return
            }
        }

        receiver = createReceiver()
        val filter = IntentFilter().apply {
            addAction(WifiP2pManager.WIFI_P2P_STATE_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_CONNECTION_CHANGED_ACTION)
            addAction(WifiP2pManager.WIFI_P2P_THIS_DEVICE_CHANGED_ACTION)
        }
        context.registerReceiver(receiver, filter)

        manager.discoverPeers(channel, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                eventSink?.success(mapOf("type" to "wifidirect_status", "message" to "discover_started"))
            }

            override fun onFailure(reason: Int) {
                eventSink?.error("discover_failed", "Wi‑Fi Direct discovery failed: $reason", null)
            }
        })
    }

    fun stopDiscovery() {
        try {
            receiver?.let { context.unregisterReceiver(it) }
        } catch (e: Exception) {
        }
        receiver = null
        eventSink?.success(mapOf("type" to "wifidirect_status", "message" to "discover_stopped"))
    }

    fun connectToDevice(deviceAddress: String) {
        // Attempt to find the device and request a connection
        val peerConfig = WifiP2pManager.WifiP2pConfig().apply {
            deviceAddress?.let { deviceAddress }
        }
        manager?.connect(channel, peerConfig, object : WifiP2pManager.ActionListener {
            override fun onSuccess() {
                eventSink?.success(mapOf("type" to "wifidirect_status", "message" to "connect_requested"))
            }

            override fun onFailure(reason: Int) {
                eventSink?.error("connect_failed", "Wi‑Fi Direct connect failed: $reason", null)
            }
        })
    }

    // Simple server socket to accept incoming relay connections
    private var serverThread: Thread? = null

    fun startServerSocket(port: Int = 8988) {
        if (serverThread != null) return
        serverThread = Thread {
            try {
                val server = java.net.ServerSocket(port)
                while (!Thread.currentThread().isInterrupted) {
                    val client = server.accept()
                    // Read a simple length-prefixed message
                    val input = client.getInputStream()
                    val buf = ByteArray(4096)
                    val read = input.read(buf)
                    if (read > 0) {
                        val payload = String(buf, 0, read)
                        eventSink?.success(mapOf("type" to "wifidirect_message", "payload" to payload))
                    }
                    client.close()
                }
                server.close()
            } catch (e: Exception) {
                eventSink?.error("server_error", e.message, null)
            }
        }
        serverThread?.start()
    }

    fun stopServerSocket() {
        serverThread?.interrupt()
        serverThread = null
    }

    fun sendMessageTo(address: String, port: Int = 8988, message: String) {
        Thread {
            try {
                val sock = java.net.Socket(address, port)
                val out = sock.getOutputStream()
                out.write(message.toByteArray())
                out.flush()
                sock.close()
                eventSink?.success(mapOf("type" to "wifidirect_send", "status" to "sent", "to" to address))
            } catch (e: Exception) {
                eventSink?.error("send_error", e.message, null)
            }
        }.start()
    }

    private fun createReceiver(): BroadcastReceiver {
        return object : BroadcastReceiver() {
            override fun onReceive(ctx: Context?, intent: Intent?) {
                when (intent?.action) {
                    WifiP2pManager.WIFI_P2P_PEERS_CHANGED_ACTION -> {
                        manager?.requestPeers(channel) { peers ->
                            val deviceList = peers.deviceList
                            deviceList?.forEach { device ->
                                emitDevice(device)
                            }
                        }
                    }
                }
            }
        }
    }

    private fun emitDevice(device: WifiP2pDevice) {
        val id = device.deviceAddress ?: return
        val name = device.deviceName ?: id.takeLast(6)
        val status = when (device.status) {
            WifiP2pDevice.AVAILABLE -> "available"
            WifiP2pDevice.INVITED -> "invited"
            WifiP2pDevice.CONNECTED -> "connected"
            WifiP2pDevice.FAILED -> "failed"
            WifiP2pDevice.UNAVAILABLE -> "unavailable"
            else -> "unknown"
        }

        eventSink?.success(mapOf(
            "deviceId" to id,
            "deviceName" to name,
            "platformLabel" to "android",
            "transport" to "wifidirect",
            "status" to status
        ))
    }
}
