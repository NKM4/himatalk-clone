import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user.dart';
import 'firestore_service.dart';
import 'secure_storage_service.dart';

/// 認証サービス
/// Firebase Authとの連携、セキュアなクレデンシャル管理
/// APKの問題点を修正:
/// - APIキーのハードコードなし（Firebase SDKが管理）
/// - SSL検証バイパスなし（Firebase SDKが自動処理）
/// - クレデンシャルは暗号化保存
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final _firestoreService = FirestoreService();
  final _secureStorage = SecureStorageService();

  /// Firebase Auth状態監視
  Stream<fb.User?> get authStateChanges => _auth.authStateChanges();

  /// 現在のFirebaseユーザー
  fb.User? get currentFirebaseUser => _auth.currentUser;

  /// 現在のユーザーID
  String? get currentUserId => _auth.currentUser?.uid;

  /// 匿名ログイン（メイン認証方式）
  Future<User?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      if (credential.user != null) {
        final uid = credential.user!.uid;

        // セキュアストレージに保存
        await _secureStorage.setUserId(uid);

        // Firestoreからユーザー情報取得（なければ作成）
        var user = await _firestoreService.getUser(uid);
        if (user == null) {
          user = await _firestoreService.registerUser(uid);
          await _saveUserToSecureStorage(user);
        }

        // オンライン状態更新
        await _firestoreService.updateUserLastActive(uid);

        return user;
      }
      return null;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message ?? '匿名ログインに失敗しました');
    }
  }

  /// メール認証ログイン
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        final uid = credential.user!.uid;
        await _secureStorage.setUserId(uid);

        final user = await _firestoreService.getUser(uid);
        if (user != null) {
          await _saveUserToSecureStorage(user);
          await _firestoreService.updateUserLastActive(uid);
        }
        return user;
      }
      return null;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message ?? 'ログインに失敗しました');
    }
  }

  /// メール認証登録
  Future<User?> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required int age,
    required int sex,
    required int place,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final uid = credential.user!.uid;
        final now = DateTime.now();

        final user = User(
          uid: uid,
          name: name,
          age: age,
          sex: sex,
          place: place,
          createdAt: now,
          updatedAt: now,
        );

        await _firestoreService.updateUserProfile(user);
        await _secureStorage.setUserId(uid);
        await _saveUserToSecureStorage(user);

        return user;
      }
      return null;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(e.code, e.message ?? '登録に失敗しました');
    }
  }

  /// ログアウト
  Future<void> signOut() async {
    await _auth.signOut();
    // セキュアストレージはクリアしない（再ログイン時に使う可能性）
  }

  /// アカウント削除
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Firestoreからデータ削除
      await _firestoreService.deleteAccount(user.uid);
      // セキュアストレージクリア
      await _secureStorage.clearAll();
      // Firebase Auth削除
      await user.delete();
    }
  }

  /// パスワードリセット
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// 現在のユーザー情報取得
  Future<User?> getCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return await _firestoreService.getUser(uid);
  }

  /// プロフィール更新
  Future<void> updateProfile(User user) async {
    await _firestoreService.updateUserProfile(user);
    await _saveUserToSecureStorage(user);
  }

  /// BAN状態チェック
  Future<bool> checkBanStatus() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final user = await _firestoreService.getUser(uid);
    return user?.isBanned ?? false;
  }

  /// シークレットモード設定
  Future<void> setSecretMode(bool isSecret, int? hours) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    DateTime? until;
    if (isSecret && hours != null) {
      until = DateTime.now().add(Duration(hours: hours));
    }

    await _firestoreService.setSecretMode(uid, isSecret, until);
    await _secureStorage.setSecretMode(isSecret, until);
  }

  /// デバイストークン更新（FCM用）
  Future<void> updateDeviceToken(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestoreService.updateDeviceToken(uid, token);
    await _secureStorage.setDeviceToken(token);
  }

  /// セキュアストレージにユーザー情報保存
  Future<void> _saveUserToSecureStorage(User user) async {
    await _secureStorage.setUserName(user.name);
    await _secureStorage.setUserAge(user.age);
    await _secureStorage.setUserSex(user.sex);
    await _secureStorage.setUserPlace(user.place);
    await _secureStorage.setUserMsg(user.msg);
  }

  /// セキュアストレージからユーザー情報復元
  Future<Map<String, dynamic>> getStoredUserInfo() async {
    return {
      'userId': await _secureStorage.getUserId(),
      'name': await _secureStorage.getUserName(),
      'age': await _secureStorage.getUserAge(),
      'sex': await _secureStorage.getUserSex(),
      'place': await _secureStorage.getUserPlace(),
      'msg': await _secureStorage.getUserMsg(),
      'isSecret': await _secureStorage.isSecretMode(),
    };
  }
}

/// 認証例外
class AuthException implements Exception {
  final String code;
  final String message;

  AuthException(this.code, this.message);

  String get userFriendlyMessage {
    switch (code) {
      case 'user-not-found':
        return 'このメールアドレスは登録されていません';
      case 'wrong-password':
        return 'パスワードが間違っています';
      case 'email-already-in-use':
        return 'このメールアドレスは既に登録されています';
      case 'weak-password':
        return 'パスワードが弱すぎます（6文字以上）';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'user-disabled':
        return 'このアカウントは無効化されています';
      case 'too-many-requests':
        return '試行回数が多すぎます。しばらくしてから再試行してください';
      default:
        return message;
    }
  }

  @override
  String toString() => 'AuthException: $code - $message';
}
