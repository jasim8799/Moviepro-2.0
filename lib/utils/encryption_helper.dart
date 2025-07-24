import 'package:encrypt/encrypt.dart';

class EncryptionHelper {
  static final _key = Key.fromUtf8(
    'my32lengthsupersecretnooneknows1',
  ); // 32 chars
  static final _iv = IV.fromUtf8('1234567890abcdef'); // 16 chars
  static final _encrypter = Encrypter(
    AES(_key, mode: AESMode.cbc, padding: 'PKCS7'),
  );

  static String decrypt(String encryptedBase64) {
    try {
      return _encrypter.decrypt64(encryptedBase64, iv: _iv);
    } catch (e) {
      print('Decryption error: $e');
      return '';
    }
  }
}
