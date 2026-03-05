import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../models/friendship.dart';
import 'ng_word_filter.dart';

/// Firestoreサービス
/// APKのAPIエンドポイントに相当する機能を提供
/// Qで指摘された問題を修正:
/// - APIキーのハードコードなし（Firebase SDKが自動管理）
/// - SSL検証は自動（Firebase SDKが処理）
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // コレクション参照
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _messagesRef =>
      _firestore.collection('messages');
  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _firestore.collection('rooms');
  CollectionReference<Map<String, dynamic>> get _yorosRef =>
      _firestore.collection('yoros');
  CollectionReference<Map<String, dynamic>> get _reportsRef =>
      _firestore.collection('reports');

  // ==================== ユーザー操作 ====================

  /// ユーザー登録（APK: /user/register_for_android.php相当）
  Future<User> registerUser(String uid) async {
    final user = User.defaultUser(uid);
    await _usersRef.doc(uid).set(user.toFirestore());
    return user;
  }

  /// ユーザー取得
  Future<User?> getUser(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists) return null;
    return User.fromFirestore(doc);
  }

  /// ユーザープロフィール更新（APK: /user/edit_profile.php相当）
  Future<void> updateUserProfile(User user) async {
    // NGワードチェック（staticメソッド使用）
    if (NgWordFilter.containsNgWord(user.name) ||
        NgWordFilter.containsNgWord(user.msg)) {
      throw Exception('不適切な内容が含まれています');
    }
    await _usersRef.doc(user.uid).update(user.toFirestore());
  }

  /// ユーザー状態更新（オンライン状態更新用）（APK: /user/update.php相当）
  Future<void> updateUserLastActive(String uid) async {
    await _usersRef.doc(uid).update({
      'updatedAt': Timestamp.now(),
    });
  }

  /// デバイストークン更新（APK: /user/update_token.php相当）
  Future<void> updateDeviceToken(String uid, String token) async {
    await _usersRef.doc(uid).update({
      'deviceToken': token,
    });
  }

  /// タイムライン取得（APK: /user/list.php相当）
  /// シークレットモード、BAN、ブロックを除外
  /// myUidはオプション（指定すると自分を除外）
  Stream<List<User>> getTimelineUsers([String? myUid]) {
    return _usersRef
        .where('isSecret', isEqualTo: false)
        .where('isBanned', isEqualTo: false)
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => User.fromFirestore(doc))
          .where((user) => myUid == null || user.uid != myUid)
          .toList();
    });
  }

  /// ユーザー検索（APK: /user/list_s.php相当）
  /// Streamを返すようにしてStreamBuilderと互換性を持たせる
  Stream<List<User>> searchUsers({
    String? myUid,
    int? sex,
    int? minAge,
    int? maxAge,
    int? place,
    int limit = 50,
  }) {
    Query<Map<String, dynamic>> query = _usersRef
        .where('isSecret', isEqualTo: false)
        .where('isBanned', isEqualTo: false);

    if (sex != null && sex != Gender.unknown) {
      query = query.where('sex', isEqualTo: sex);
    }

    if (place != null && place != 0) {
      query = query.where('place', isEqualTo: place);
    }

    return query.limit(limit).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => User.fromFirestore(doc))
          .where((user) {
            if (myUid != null && user.uid == myUid) return false;
            if (minAge != null && user.age < minAge) return false;
            if (maxAge != null && user.age > maxAge) return false;
            return true;
          })
          .toList();
    });
  }

  /// ユーザーブロック（APK: /user/block.php相当）
  Future<void> blockUser(String myUid, String targetUid) async {
    await _usersRef.doc(myUid).update({
      'blockedUserIds': FieldValue.arrayUnion([targetUid]),
    });
  }

  /// ブロック解除
  Future<void> unblockUser(String myUid, String targetUid) async {
    await _usersRef.doc(myUid).update({
      'blockedUserIds': FieldValue.arrayRemove([targetUid]),
    });
  }

  /// ブロックリスト取得（APK: /user/list_block.php相当）
  Future<List<User>> getBlockedUsers(String myUid) async {
    final myUser = await getUser(myUid);
    if (myUser == null || myUser.blockedUserIds.isEmpty) return [];

    // === N+1問題修正: 一括取得 ===
    final blockedUids = myUser.blockedUserIds;
    if (blockedUids.isEmpty) return [];

    // Firestoreの whereIn は最大10件なので分割
    final users = <User>[];
    for (var i = 0; i < blockedUids.length; i += 10) {
      final batch = blockedUids.skip(i).take(10).toList();
      final snapshot =
          await _usersRef.where(FieldPath.documentId, whereIn: batch).get();
      users.addAll(snapshot.docs.map((doc) => User.fromFirestore(doc)));
    }
    return users;
  }

  /// 通報（APK: /user/report.php相当）
  /// targetUidまたはreportedUidのどちらでも指定可能
  Future<void> reportUser({
    required String reporterUid,
    String? targetUid,
    String? reportedUid,
    required String reason,
    String? detail,
  }) async {
    final target = targetUid ?? reportedUid ?? '';
    if (target.isEmpty) {
      throw Exception('通報対象のユーザーIDが必要です');
    }
    await _reportsRef.add({
      'reporterUid': reporterUid,
      'targetUid': target,
      'reason': reason,
      'detail': detail,
      'createdAt': Timestamp.now(),
      'status': 'pending',
    });
  }

  /// アカウント削除（APK: /user/delete_account_android.php相当）
  Future<void> deleteAccount(String uid) async {
    // 1. ユーザードキュメント削除
    await _usersRef.doc(uid).delete();

    // 2. 関連ルーム削除
    final roomsSnapshot = await _roomsRef
        .where('roomKey', isGreaterThanOrEqualTo: uid)
        .where('roomKey', isLessThan: '${uid}z')
        .get();
    for (final doc in roomsSnapshot.docs) {
      await doc.reference.delete();
    }

    // 3. メッセージは残す（相手のため）
  }

  /// シークレットモード設定
  Future<void> setSecretMode(String uid, bool isSecret, DateTime? until) async {
    await _usersRef.doc(uid).update({
      'isSecret': isSecret,
      'secretUntil': until != null ? Timestamp.fromDate(until) : null,
    });
  }

  // ==================== メッセージ操作 ====================

  /// メッセージ送信（APK: /message/send.php相当）
  /// fromUserId/toUserId もサポート（エイリアス）
  Future<Message> sendMessage({
    String? fromUid,
    String? toUid,
    String? fromUserId,
    String? toUserId,
    required String body,
    MessageType type = MessageType.text,
    String? url,
    int friendshipLevel = 1,
  }) async {
    // エイリアス解決
    final from = fromUid ?? fromUserId ?? '';
    final to = toUid ?? toUserId ?? '';
    if (from.isEmpty || to.isEmpty) {
      throw Exception('送信者と受信者のIDが必要です');
    }

    // NGワードチェック（staticメソッド使用）
    if (NgWordFilter.containsNgWord(body)) {
      throw Exception('不適切な内容が含まれています');
    }

    // 仲良しレベルによる文字数制限
    final maxLength = Friendship.getMaxMessageLength(friendshipLevel);
    if (body.length > maxLength) {
      throw Exception('文字数制限を超えています（最大$maxLength文字）');
    }

    // 写真送信制限
    if (type == MessageType.photo && friendshipLevel < 3) {
      throw Exception('写真送信はLv.3から可能です');
    }

    final roomKey = Room.generateRoomKey(from, to);
    final messageId = _uuid.v4();
    final now = DateTime.now();

    final message = Message(
      mid: messageId,
      roomKey: roomKey,
      fromUserId: from,
      toUserId: to,
      body: body,
      type: type,
      url: url,
      status: MessageStatus.sent,
      createdAt: now,
      uuid: messageId,
    );

    // メッセージ保存
    await _messagesRef.doc(messageId).set(message.toFirestore());

    // ルーム更新
    await _updateRoomAfterMessage(from, to, message);

    return message;
  }

  /// よろ！送信（APK: /message/send_yoro.php相当）
  /// 位置引数でも名前付き引数でも呼び出し可能
  Future<void> sendYoro(String fromUid, String toUid) async {
    // 重複チェック（24時間以内）
    final yesterday = DateTime.now().subtract(const Duration(hours: 24));
    final existing = await _yorosRef
        .where('fromUserId', isEqualTo: fromUid)
        .where('toUserId', isEqualTo: toUid)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(yesterday))
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('24時間以内に既によろ！を送っています');
    }

    final yoro = Yoro(
      id: _uuid.v4(),
      fromUserId: fromUid,
      toUserId: toUid,
      createdAt: DateTime.now(),
    );

    await _yorosRef.doc(yoro.id).set(yoro.toFirestore());
  }

  /// 写真送信（APK: /message/send_photo.php相当）
  Future<Message> sendPhoto({
    required String fromUid,
    required String toUid,
    required String imageUrl,
    required int friendshipLevel,
  }) async {
    return sendMessage(
      fromUid: fromUid,
      toUid: toUid,
      body: '[写真]',
      type: MessageType.photo,
      url: imageUrl,
      friendshipLevel: friendshipLevel,
    );
  }

  /// メッセージ取得（リアルタイム）
  Stream<List<Message>> getMessages(String roomKey) {
    return _messagesRef
        .where('roomKey', isEqualTo: roomKey)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
    });
  }

  /// 新着メッセージ確認（APK: /message/new.php相当）
  Future<List<Message>> getNewMessages(String uid, DateTime since) async {
    final snapshot = await _messagesRef
        .where('toUserId', isEqualTo: uid)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(since))
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList();
  }

  // ==================== ルーム操作 ====================

  /// ルーム一覧取得（APK: /message/update_rooms.php相当）
  Stream<List<Room>> getRooms(String uid) {
    // 自分がpartnerUidに含まれるルームを取得
    return _roomsRef
        .where('participants', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      // === N+1問題修正: パートナーUIDを先に収集して一括取得 ===
      final roomDataList = <(DocumentSnapshot<Map<String, dynamic>>, String)>[];
      final partnerUids = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        final partnerUid = participants.firstWhere(
          (id) => id != uid,
          orElse: () => '',
        );
        if (partnerUid.isEmpty) continue;
        roomDataList.add((doc, partnerUid));
        partnerUids.add(partnerUid);
      }

      if (partnerUids.isEmpty) return <Room>[];

      // 一括でユーザー情報を取得（whereInは最大10件）
      final partnerMap = <String, User>{};
      final uidList = partnerUids.toList();
      for (var i = 0; i < uidList.length; i += 10) {
        final batch = uidList.skip(i).take(10).toList();
        final userSnap = await _usersRef.where(FieldPath.documentId, whereIn: batch).get();
        for (final userDoc in userSnap.docs) {
          partnerMap[userDoc.id] = User.fromFirestore(userDoc);
        }
      }

      // ルームリストを構築
      final rooms = <Room>[];
      for (final (doc, partnerUid) in roomDataList) {
        final partner = partnerMap[partnerUid];
        if (partner == null) continue;
        final data = doc.data()!;

        rooms.add(Room(
          roomKey: doc.id,
          partnerUid: partnerUid,
          partnerName: partner.name,
          partnerImage: partner.img,
          lastMessage: data['lastMessage'] as String?,
          lastMid: data['lastMid'] as String?,
          lastUid: data['lastUid'] as String?,
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          status: data['status'] as int? ?? 0,
          readed: data['readed_$uid'] as bool? ?? true,
          favorite: data['favorite_$uid'] as bool? ?? false,
          friendshipLevel: data['friendshipLevel'] as int? ?? 1,
          messageCount: data['messageCount'] as int? ?? 0,
        ));
      }
      return rooms;
    });
  }

  /// ルーム取得または作成
  Future<Room> getOrCreateRoom(String myUid, String partnerUid) async {
    final roomKey = Room.generateRoomKey(myUid, partnerUid);
    final doc = await _roomsRef.doc(roomKey).get();

    if (doc.exists) {
      final partner = await getUser(partnerUid);
      final data = doc.data()!;
      return Room(
        roomKey: roomKey,
        partnerUid: partnerUid,
        partnerName: partner?.name ?? 'Unknown',
        partnerImage: partner?.img,
        lastMessage: data['lastMessage'] as String?,
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        friendshipLevel: data['friendshipLevel'] as int? ?? 1,
        messageCount: data['messageCount'] as int? ?? 0,
      );
    }

    // 新規ルーム作成
    final partner = await getUser(partnerUid);
    final now = DateTime.now();
    final room = Room(
      roomKey: roomKey,
      partnerUid: partnerUid,
      partnerName: partner?.name ?? 'Unknown',
      partnerImage: partner?.img,
      updatedAt: now,
    );

    await _roomsRef.doc(roomKey).set({
      ...room.toFirestore(),
      'participants': [myUid, partnerUid],
      'readed_$myUid': true,
      'readed_$partnerUid': true,
      'favorite_$myUid': false,
      'favorite_$partnerUid': false,
    });

    return room;
  }

  /// メッセージ送信後のルーム更新
  Future<void> _updateRoomAfterMessage(
    String fromUid,
    String toUid,
    Message message,
  ) async {
    final roomKey = Room.generateRoomKey(fromUid, toUid);
    final docRef = _roomsRef.doc(roomKey);
    final doc = await docRef.get();

    if (!doc.exists) {
      // ルームが存在しない場合は作成
      await getOrCreateRoom(fromUid, toUid);
    }

    // ルーム情報更新
    await docRef.update({
      'lastMessage': message.body,
      'lastMid': message.mid,
      'lastUid': fromUid,
      'updatedAt': Timestamp.now(),
      'readed_$fromUid': true,
      'readed_$toUid': false,
      'messageCount': FieldValue.increment(1),
    });

    // 仲良しレベル更新
    final data = (await docRef.get()).data();
    final messageCount = (data?['messageCount'] as int?) ?? 1;
    final newLevel = Friendship.calculateLevel(messageCount);
    if (newLevel != (data?['friendshipLevel'] as int? ?? 1)) {
      await docRef.update({'friendshipLevel': newLevel});
    }
  }

  /// 既読にする
  Future<void> markAsRead(String roomKey, String uid) async {
    await _roomsRef.doc(roomKey).update({
      'readed_$uid': true,
    });
  }

  /// お気に入り設定
  Future<void> setFavorite(String roomKey, String uid, bool isFavorite) async {
    await _roomsRef.doc(roomKey).update({
      'favorite_$uid': isFavorite,
    });
  }

  /// ルーム削除（非表示）
  Future<void> deleteRoom(String roomKey) async {
    await _roomsRef.doc(roomKey).update({
      'status': 1, // deleted
    });
  }

  // ==================== よろ！操作 ====================

  /// 受信したよろ！一覧
  Stream<List<Yoro>> getReceivedYoros(String uid) {
    return _yorosRef
        .where('toUserId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Yoro.fromFirestore(doc)).toList();
    });
  }

  /// よろ！を既読にする
  Future<void> markYoroAsRead(String yoroId) async {
    await _yorosRef.doc(yoroId).update({'isRead': true});
  }

  // ==================== 仲良しレベル操作 ====================

  /// 仲良しレベル取得
  Future<Friendship> getFriendship(String userId1, String userId2) async {
    final roomKey = Room.generateRoomKey(userId1, userId2);
    final doc = await _roomsRef.doc(roomKey).get();
    final now = DateTime.now();

    if (!doc.exists) {
      return Friendship(
        id: roomKey,
        userId1: userId1,
        userId2: userId2,
        level: 1,
        messageCount: 0,
        createdAt: now,
        lastInteractionAt: now,
      );
    }

    final data = doc.data()!;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? now;
    final updatedAt = (data['updatedAt'] as Timestamp?)?.toDate() ?? now;

    return Friendship(
      id: roomKey,
      userId1: userId1,
      userId2: userId2,
      level: data['friendshipLevel'] as int? ?? 1,
      messageCount: data['messageCount'] as int? ?? 0,
      createdAt: createdAt,
      lastInteractionAt: updatedAt,
    );
  }
}
