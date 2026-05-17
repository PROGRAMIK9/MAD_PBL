import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class EncryptedPacket {
  const EncryptedPacket({required this.cipherText, required this.iv});

  final String cipherText;
  final String iv;
}

class MeshCrypto {
  const MeshCrypto._();

  static EncryptedPacket encryptText(String plaintext, String passphrase) {
    final keyBytes = sha256.convert(utf8.encode(passphrase)).bytes;
    final key = Key(Uint8List.fromList(keyBytes));
    final iv = IV.fromSecureRandom(12);
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    return EncryptedPacket(cipherText: encrypted.base64, iv: iv.base64);
  }

  static String decryptText(EncryptedPacket packet, String passphrase) {
    final keyBytes = sha256.convert(utf8.encode(passphrase)).bytes;
    final key = Key(Uint8List.fromList(keyBytes));
    final iv = IV.fromBase64(packet.iv);
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    return encrypter.decrypt64(packet.cipherText, iv: iv);
  }
}