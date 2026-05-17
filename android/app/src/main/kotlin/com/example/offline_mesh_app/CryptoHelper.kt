package com.example.offline_mesh_app

import android.util.Base64
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

object CryptoHelper {
    private const val TRANSFORMATION = "AES/GCM/NoPadding"
    private const val IV_SIZE = 12
    private const val TAG_LENGTH = 128
    private var key: ByteArray? = null

    fun setKeyBase64(b64: String) {
        key = Base64.decode(b64, Base64.DEFAULT)
    }

    fun encrypt(plaintext: ByteArray): ByteArray? {
        val k = key ?: return null
        val iv = ByteArray(IV_SIZE)
        SecureRandom().nextBytes(iv)
        val cipher = Cipher.getInstance(TRANSFORMATION)
        val spec = GCMParameterSpec(TAG_LENGTH, iv)
        val secretKey = SecretKeySpec(k, "AES")
        cipher.init(Cipher.ENCRYPT_MODE, secretKey, spec)
        val cipherText = cipher.doFinal(plaintext)
        // Prepend IV to ciphertext
        return iv + cipherText
    }

    fun decrypt(data: ByteArray): ByteArray? {
        val k = key ?: return null
        if (data.size < IV_SIZE) return null
        val iv = data.sliceArray(0 until IV_SIZE)
        val cipherText = data.sliceArray(IV_SIZE until data.size)
        val cipher = Cipher.getInstance(TRANSFORMATION)
        val spec = GCMParameterSpec(TAG_LENGTH, iv)
        val secretKey = SecretKeySpec(k, "AES")
        cipher.init(Cipher.DECRYPT_MODE, secretKey, spec)
        return cipher.doFinal(cipherText)
    }
}
