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
                    handleAcceptedSocket(client)
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
            var attempts = 0
            var backoff = 200L
            val maxAttempts = 4
            while (attempts < maxAttempts) {
                try {
                    val sock = java.net.Socket(address, port)
                    val out = sock.getOutputStream()
                    // Encrypt
                    val ciphertext = CryptoHelper.encrypt(message.toByteArray()) ?: throw Exception("encryption_key_missing")
                    // Frame: 4-byte big-endian length + payload
                    val len = ciphertext.size
                    val header = byteArrayOf(
                        ((len shr 24) and 0xFF).toByte(),
                        ((len shr 16) and 0xFF).toByte(),
                        ((len shr 8) and 0xFF).toByte(),
                        (len and 0xFF).toByte()
                    )
                    out.write(header)
                    out.write(ciphertext)
                    out.flush()
                    sock.close()
                    eventSink?.success(mapOf("type" to "wifidirect_send", "status" to "sent", "to" to address))
                    break
                } catch (e: Exception) {
                    attempts += 1
                    if (attempts >= maxAttempts) {
                        eventSink?.error("send_error", e.message, null)
                        break
                    }
                    try {
                        Thread.sleep(backoff)
                    } catch (ie: InterruptedException) {
                        break
                    }
                    backoff *= 2
                }
            }
        }.start()
    }

    // Read framed+encrypted payloads from an accepted socket
    private fun handleAcceptedSocket(client: java.net.Socket) {
        Thread {
            try {
                val input = client.getInputStream()
                val header = ByteArray(4)
                while (true) {
                    var read = input.read(header)
                    if (read != 4) break
                    val len = ((header[0].toInt() and 0xFF) shl 24) or
                            ((header[1].toInt() and 0xFF) shl 16) or
                            ((header[2].toInt() and 0xFF) shl 8) or
                            (header[3].toInt() and 0xFF)
                    val buf = ByteArray(len)
                    var offset = 0
                    while (offset < len) {
                        val r = input.read(buf, offset, len - offset)
                        if (r <= 0) break
                        offset += r
                    }
                    val plaintext = CryptoHelper.decrypt(buf)
                    if (plaintext != null) {
                        val payload = String(plaintext)
                        eventSink?.success(mapOf("type" to "wifidirect_message", "payload" to payload))
                    }
                }
                client.close()
            } catch (e: Exception) {
                eventSink?.error("receive_error", e.message, null)
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
