import 'package:encrypt/encrypt.dart';

class EncryptionService {
  final key = Key.fromUtf8('bdKC0MrHrYvMraoCEmJcuG3Ef5PNbHrZ');
  final iv = IV.fromLength(16);

  final key2 = Key.fromUtf8('82601e8333073867448b310503b53655');
  final iv2 = IV.fromLength(16);

  String enc(String data) {
    final encrypter = Encrypter(AES(key));
    Encrypted encrypted = encrypter.encrypt(data, iv: iv);

    return encrypted.base64;
  }

  String dec(String data) {
    final encrypter = Encrypter(AES(key));
    Encrypted encrypted = Encrypted.fromBase64(data);
    String decrypted = encrypter.decrypt(encrypted, iv: iv);

    return decrypted;
  }

  String enc2(String data) {
    final encrypter = Encrypter(AES(key2));
    Encrypted encrypted = encrypter.encrypt(data, iv: iv2);

    return encrypted.base64;
  }

  String dec2(String data) {
    final encrypter = Encrypter(AES(key2));
    Encrypted encrypted = Encrypted.fromBase64(data);
    String decrypted = encrypter.decrypt(encrypted, iv: iv2);

    return decrypted;
  }
}

