import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// プッシュ通知サービス
/// Firebase Cloud Messaging を使用
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final _messaging = FirebaseMessaging.instance;
  String? _token;

  /// 初期化
  Future<void> initialize() async {
    // 権限リクエスト
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('通知権限: ${settings.authorizationStatus}');

    // トークン取得
    _token = await _messaging.getToken();
    debugPrint('FCMトークン: $_token');

    // トークン更新リスナー
    _messaging.onTokenRefresh.listen((token) {
      _token = token;
      debugPrint('FCMトークン更新: $token');
      // TODO: サーバーにトークンを送信
    });

    // フォアグラウンドメッセージリスナー
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // バックグラウンドタップリスナー
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundTap);

    // アプリ起動時の通知確認
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleInitialMessage(initialMessage);
    }
  }

  /// 現在のトークン取得
  String? get token => _token;

  /// フォアグラウンドメッセージ処理
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('フォアグラウンド通知: ${message.notification?.title}');
    // TODO: ローカル通知表示またはアプリ内通知
  }

  /// バックグラウンドタップ処理
  void _handleBackgroundTap(RemoteMessage message) {
    debugPrint('通知タップ: ${message.data}');
    // TODO: 適切な画面に遷移
  }

  /// 初期メッセージ処理
  void _handleInitialMessage(RemoteMessage message) {
    debugPrint('初期通知: ${message.data}');
    // TODO: 適切な画面に遷移
  }

  /// トピック購読
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('トピック購読: $topic');
  }

  /// トピック購読解除
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('トピック購読解除: $topic');
  }
}

/// バックグラウンドメッセージハンドラ（トップレベル関数として定義）
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('バックグラウンド通知: ${message.messageId}');
}
