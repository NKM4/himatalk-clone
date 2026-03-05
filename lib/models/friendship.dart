/// 仲良しレベルシステム
/// レベル1: 初対面（メッセージ100文字まで、写真送信不可）
/// レベル2: 顔見知り（メッセージ200文字まで、写真送信不可）
/// レベル3: 知り合い（メッセージ500文字まで、写真送信可）
/// レベル4: 友達（メッセージ1000文字まで、写真送信可）
/// レベル5: 親友（制限なし）
class Friendship {
  /// レベルから最大文字数を取得（静的メソッド）
  static int getMaxMessageLength(int level) {
    switch (level) {
      case 1:
        return 100;
      case 2:
        return 200;
      case 3:
        return 500;
      case 4:
        return 1000;
      case 5:
        return 10000;
      default:
        return 100;
    }
  }

  /// メッセージ数からレベルを計算（静的メソッド）
  static int calculateLevel(int messageCount) {
    if (messageCount >= 200) return 5;
    if (messageCount >= 100) return 4;
    if (messageCount >= 50) return 3;
    if (messageCount >= 10) return 2;
    return 1;
  }

  /// 写真送信可能か（静的メソッド）
  static bool canSendPhotoAtLevel(int level) => level >= 3;

  final String id;
  final String userId1;
  final String userId2;
  final int level; // 1-5
  final int messageCount; // 累計メッセージ数
  final DateTime createdAt;
  final DateTime lastInteractionAt;
  final bool hasYoroSent; // userId1がuserId2によろ！を送ったか
  final bool hasYoroReceived; // userId1がuserId2からよろ！を受け取ったか

  Friendship({
    required this.id,
    required this.userId1,
    required this.userId2,
    this.level = 1,
    this.messageCount = 0,
    required this.createdAt,
    required this.lastInteractionAt,
    this.hasYoroSent = false,
    this.hasYoroReceived = false,
  });

  /// レベルアップに必要なメッセージ数
  static const Map<int, int> levelThresholds = {
    1: 0,    // 初対面
    2: 10,   // 顔見知り
    3: 50,   // 知り合い
    4: 100,  // 友達
    5: 200,  // 親友
  };

  /// レベル名を取得
  String get levelName {
    switch (level) {
      case 1:
        return '初対面';
      case 2:
        return '顔見知り';
      case 3:
        return '知り合い';
      case 4:
        return '友達';
      case 5:
        return '親友';
      default:
        return '不明';
    }
  }

  /// メッセージ文字数制限
  int get maxMessageLength {
    switch (level) {
      case 1:
        return 100;
      case 2:
        return 200;
      case 3:
        return 500;
      case 4:
        return 1000;
      case 5:
        return 10000; // 実質無制限
      default:
        return 100;
    }
  }

  /// 写真送信可能かどうか
  bool get canSendPhoto {
    return level >= 3;
  }

  /// 次のレベルまでに必要なメッセージ数
  int get messagesUntilNextLevel {
    if (level >= 5) return 0;
    final nextThreshold = levelThresholds[level + 1] ?? 0;
    return nextThreshold - messageCount;
  }

  /// 現在のレベルの進捗率 (0.0-1.0)
  double get levelProgress {
    if (level >= 5) return 1.0;
    final currentThreshold = levelThresholds[level] ?? 0;
    final nextThreshold = levelThresholds[level + 1] ?? 0;
    final range = nextThreshold - currentThreshold;
    if (range == 0) return 1.0;
    return (messageCount - currentThreshold) / range;
  }

  Friendship copyWith({
    String? id,
    String? userId1,
    String? userId2,
    int? level,
    int? messageCount,
    DateTime? createdAt,
    DateTime? lastInteractionAt,
    bool? hasYoroSent,
    bool? hasYoroReceived,
  }) {
    return Friendship(
      id: id ?? this.id,
      userId1: userId1 ?? this.userId1,
      userId2: userId2 ?? this.userId2,
      level: level ?? this.level,
      messageCount: messageCount ?? this.messageCount,
      createdAt: createdAt ?? this.createdAt,
      lastInteractionAt: lastInteractionAt ?? this.lastInteractionAt,
      hasYoroSent: hasYoroSent ?? this.hasYoroSent,
      hasYoroReceived: hasYoroReceived ?? this.hasYoroReceived,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId1': userId1,
      'userId2': userId2,
      'level': level,
      'messageCount': messageCount,
      'createdAt': createdAt.toIso8601String(),
      'lastInteractionAt': lastInteractionAt.toIso8601String(),
      'hasYoroSent': hasYoroSent,
      'hasYoroReceived': hasYoroReceived,
    };
  }

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['id'] as String,
      userId1: json['userId1'] as String,
      userId2: json['userId2'] as String,
      level: json['level'] as int? ?? 1,
      messageCount: json['messageCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastInteractionAt: DateTime.parse(json['lastInteractionAt'] as String),
      hasYoroSent: json['hasYoroSent'] as bool? ?? false,
      hasYoroReceived: json['hasYoroReceived'] as bool? ?? false,
    );
  }

  /// メッセージ数を更新してレベルを再計算
  Friendship incrementMessageCount() {
    final newCount = messageCount + 1;
    int newLevel = level;

    // レベルアップチェック
    for (int l = 5; l >= 1; l--) {
      if (newCount >= (levelThresholds[l] ?? 0)) {
        newLevel = l;
        break;
      }
    }

    return copyWith(
      messageCount: newCount,
      level: newLevel,
      lastInteractionAt: DateTime.now(),
    );
  }
}
