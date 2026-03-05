enum NotificationType { yoro, message, follow, like, system }

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String? body;
  final String? fromUserId;
  final String? fromUserName;
  final String? relatedId; // postId, chatId, etc.
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.fromUserId,
    this.fromUserName,
    this.relatedId,
    required this.createdAt,
    this.isRead = false,
  });

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? body,
    String? fromUserId,
    String? fromUserName,
    String? relatedId,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      relatedId: relatedId ?? this.relatedId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'body': body,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'relatedId': relatedId,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.system,
      ),
      title: json['title'] as String,
      body: json['body'] as String?,
      fromUserId: json['fromUserId'] as String?,
      fromUserName: json['fromUserName'] as String?,
      relatedId: json['relatedId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
