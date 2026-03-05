import 'package:cloud_firestore/cloud_firestore.dart';

/// メッセージタイプ（APK: HTMessageColumns.MESSAGE_TYPE準拠）
enum MessageType {
  text,   // テキスト
  photo,  // 写真
  image,  // 写真（エイリアス）
  yoro,   // よろ！
  system, // システム
}

/// メッセージステータス
enum MessageStatus {
  sending,  // 送信中
  sent,     // 送信済み
  failed,   // 失敗
}

/// メッセージモデル（APK: HTMessageColumns.smali準拠）
class Message {
  final String mid;         // メッセージID
  final String roomKey;     // ルームキー
  final String fromUserId;  // 送信者ID
  final String toUserId;    // 受信者ID
  final String body;        // メッセージ本文
  final MessageType type;   // タイプ
  final String? url;        // 画像URL
  final MessageStatus status; // ステータス
  final DateTime createdAt; // 作成日時
  final String uuid;        // UUID（重複送信防止用）

  Message({
    required this.mid,
    required this.roomKey,
    required this.fromUserId,
    required this.toUserId,
    required this.body,
    this.type = MessageType.text,
    this.url,
    this.status = MessageStatus.sent,
    required this.createdAt,
    required this.uuid,
  });

  bool isFromMe(String myUserId) => fromUserId == myUserId;

  Message copyWith({
    String? mid,
    String? roomKey,
    String? fromUserId,
    String? toUserId,
    String? body,
    MessageType? type,
    String? url,
    MessageStatus? status,
    DateTime? createdAt,
    String? uuid,
  }) {
    return Message(
      mid: mid ?? this.mid,
      roomKey: roomKey ?? this.roomKey,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      body: body ?? this.body,
      type: type ?? this.type,
      url: url ?? this.url,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      uuid: uuid ?? this.uuid,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'mid': mid,
      'roomKey': roomKey,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'body': body,
      'type': type.name,
      'url': url,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'uuid': uuid,
    };
  }

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      mid: doc.id,
      roomKey: data['roomKey'] as String? ?? '',
      fromUserId: data['fromUserId'] as String? ?? '',
      toUserId: data['toUserId'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      url: data['url'] as String?,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MessageStatus.sent,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      uuid: data['uuid'] as String? ?? '',
    );
  }

  /// 経過時間表示
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    return '${diff.inDays}日前';
  }

  /// 日付のみ表示（セクション用）
  String get sectionIdentifier {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (messageDate == today) return '今日';
    if (messageDate == today.subtract(const Duration(days: 1))) return '昨日';
    return '${createdAt.month}/${createdAt.day}';
  }
}

/// ルームモデル（APK: HTRoomColumns.smali準拠）
class Room {
  final String roomKey;       // ルームキー（ソート済みuser1_user2形式）
  final String partnerUid;    // 相手のユーザーID
  final String partnerName;   // 相手の名前
  final String? partnerImage; // 相手のアイコンURL
  final String? lastMessage;  // 最後のメッセージ
  final String? lastMid;      // 最後のメッセージID
  final String? lastUid;      // 最後のメッセージ送信者ID
  final DateTime updatedAt;   // 更新日時
  final int status;           // ステータス (0=active, 1=deleted)
  final bool readed;          // 既読フラグ
  final bool favorite;        // お気に入りフラグ
  final int friendshipLevel;  // 仲良しレベル
  final int messageCount;     // メッセージ累計数

  Room({
    required this.roomKey,
    required this.partnerUid,
    required this.partnerName,
    this.partnerImage,
    this.lastMessage,
    this.lastMid,
    this.lastUid,
    required this.updatedAt,
    this.status = 0,
    this.readed = true,
    this.favorite = false,
    this.friendshipLevel = 1,
    this.messageCount = 0,
  });

  /// ルームキー生成（常に同じ順序になるようにソート）
  static String generateRoomKey(String userId1, String userId2) {
    final sorted = [userId1, userId2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  bool get isActive => status == 0;
  bool get isDeleted => status == 1;

  /// 経過時間表示
  String get timeAgo {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inMinutes < 1) return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    if (diff.inDays < 7) return '${diff.inDays}日前';
    return '${diff.inDays ~/ 7}週間前';
  }

  /// エイリアス: main.dartから呼ばれる
  String get lastUpdatedText => timeAgo;

  Room copyWith({
    String? roomKey,
    String? partnerUid,
    String? partnerName,
    String? partnerImage,
    String? lastMessage,
    String? lastMid,
    String? lastUid,
    DateTime? updatedAt,
    int? status,
    bool? readed,
    bool? favorite,
    int? friendshipLevel,
    int? messageCount,
  }) {
    return Room(
      roomKey: roomKey ?? this.roomKey,
      partnerUid: partnerUid ?? this.partnerUid,
      partnerName: partnerName ?? this.partnerName,
      partnerImage: partnerImage ?? this.partnerImage,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMid: lastMid ?? this.lastMid,
      lastUid: lastUid ?? this.lastUid,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      readed: readed ?? this.readed,
      favorite: favorite ?? this.favorite,
      friendshipLevel: friendshipLevel ?? this.friendshipLevel,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomKey': roomKey,
      'partnerUid': partnerUid,
      'partnerName': partnerName,
      'partnerImage': partnerImage,
      'lastMessage': lastMessage,
      'lastMid': lastMid,
      'lastUid': lastUid,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status,
      'readed': readed,
      'favorite': favorite,
      'friendshipLevel': friendshipLevel,
      'messageCount': messageCount,
    };
  }

  factory Room.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Room(
      roomKey: doc.id,
      partnerUid: data['partnerUid'] as String? ?? '',
      partnerName: data['partnerName'] as String? ?? 'Unknown',
      partnerImage: data['partnerImage'] as String?,
      lastMessage: data['lastMessage'] as String?,
      lastMid: data['lastMid'] as String?,
      lastUid: data['lastUid'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] as int? ?? 0,
      readed: data['readed'] as bool? ?? true,
      favorite: data['favorite'] as bool? ?? false,
      friendshipLevel: data['friendshipLevel'] as int? ?? 1,
      messageCount: data['messageCount'] as int? ?? 0,
    );
  }
}

/// よろ！モデル
class Yoro {
  final String id;
  final String fromUserId;
  final String toUserId;
  final DateTime createdAt;
  final bool isRead;
  final String? fromUserName; // 送信者名（表示用）

  Yoro({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.createdAt,
    this.isRead = false,
    this.fromUserName,
  });

  /// 経過時間表示
  String get createdAtText {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    if (diff.inDays < 7) return '${diff.inDays}日前';
    return '${diff.inDays ~/ 7}週間前';
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  factory Yoro.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Yoro(
      id: doc.id,
      fromUserId: data['fromUserId'] as String? ?? '',
      toUserId: data['toUserId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      fromUserName: data['fromUserName'] as String?,
    );
  }
}
