import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// セキュアストレージサービス
/// Q指摘事項の修正: SharedPreferencesではなくEncryptedStorageを使用
/// APKの問題: USER_ID, USER_KEY, USER_SECRETが平文保存されていた
/// 改善: flutter_secure_storageで暗号化保存
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ストレージキー（APKのSharedPreferencesキーに対応）
  static const _keyUserId = 'USER_ID';
  static const _keyUserKey = 'USER_KEY';
  static const _keyUserSecret = 'USER_SECRET';
  static const _keyDeviceToken = 'DEVICE_TOKEN';
  static const _keyUserName = 'USER_NAME';
  static const _keyUserAge = 'USER_AGE';
  static const _keyUserSex = 'USER_SEX';
  static const _keyUserPlace = 'USER_PLACE';
  static const _keyUserMsg = 'USER_HITOKOTO';
  static const _keyIsSecret = 'USER_SECRET_MODE';
  static const _keySecretUntil = 'SECRET_UNTIL';

  // ==================== ユーザーID ====================
  Future<void> setUserId(String userId) async {
    await _storage.write(key: _keyUserId, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  // ==================== ユーザーキー（認証用） ====================
  Future<void> setUserKey(String userKey) async {
    await _storage.write(key: _keyUserKey, value: userKey);
  }

  Future<String?> getUserKey() async {
    return await _storage.read(key: _keyUserKey);
  }

  // ==================== ユーザーシークレット（認証用） ====================
  Future<void> setUserSecret(String secret) async {
    await _storage.write(key: _keyUserSecret, value: secret);
  }

  Future<String?> getUserSecret() async {
    return await _storage.read(key: _keyUserSecret);
  }

  // ==================== デバイストークン（FCM用） ====================
  Future<void> setDeviceToken(String token) async {
    await _storage.write(key: _keyDeviceToken, value: token);
  }

  Future<String?> getDeviceToken() async {
    return await _storage.read(key: _keyDeviceToken);
  }

  // ==================== ユーザー基本情報 ====================
  Future<void> setUserName(String name) async {
    await _storage.write(key: _keyUserName, value: name);
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: _keyUserName);
  }

  Future<void> setUserAge(int age) async {
    await _storage.write(key: _keyUserAge, value: age.toString());
  }

  Future<int?> getUserAge() async {
    final value = await _storage.read(key: _keyUserAge);
    return value != null ? int.tryParse(value) : null;
  }

  Future<void> setUserSex(int sex) async {
    await _storage.write(key: _keyUserSex, value: sex.toString());
  }

  Future<int?> getUserSex() async {
    final value = await _storage.read(key: _keyUserSex);
    return value != null ? int.tryParse(value) : null;
  }

  Future<void> setUserPlace(int place) async {
    await _storage.write(key: _keyUserPlace, value: place.toString());
  }

  Future<int?> getUserPlace() async {
    final value = await _storage.read(key: _keyUserPlace);
    return value != null ? int.tryParse(value) : null;
  }

  Future<void> setUserMsg(String msg) async {
    await _storage.write(key: _keyUserMsg, value: msg);
  }

  Future<String?> getUserMsg() async {
    return await _storage.read(key: _keyUserMsg);
  }

  // ==================== シークレットモード ====================
  Future<void> setSecretMode(bool isSecret, DateTime? until) async {
    await _storage.write(key: _keyIsSecret, value: isSecret.toString());
    if (until != null) {
      await _storage.write(key: _keySecretUntil, value: until.toIso8601String());
    } else {
      await _storage.delete(key: _keySecretUntil);
    }
  }

  Future<bool> isSecretMode() async {
    final value = await _storage.read(key: _keyIsSecret);
    return value == 'true';
  }

  Future<DateTime?> getSecretUntil() async {
    final value = await _storage.read(key: _keySecretUntil);
    return value != null ? DateTime.tryParse(value) : null;
  }

  // ==================== 全削除 ====================
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // ==================== ログイン状態チェック ====================
  Future<bool> isLoggedIn() async {
    final userId = await getUserId();
    return userId != null && userId.isNotEmpty;
  }
}
