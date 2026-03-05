class Post {
  final String id;
  final String userId;
  final String userName;
  final int userAge;
  final String userGender;
  final String userArea;
  final String? userProfileImageUrl;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final int yoroCount; // "Hi!" count
  final List<String> yoroUserIds;

  Post({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAge,
    required this.userGender,
    required this.userArea,
    this.userProfileImageUrl,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.yoroCount = 0,
    this.yoroUserIds = const [],
  });

  Post copyWith({
    String? id,
    String? userId,
    String? userName,
    int? userAge,
    String? userGender,
    String? userArea,
    String? userProfileImageUrl,
    String? content,
    String? imageUrl,
    DateTime? createdAt,
    int? yoroCount,
    List<String>? yoroUserIds,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAge: userAge ?? this.userAge,
      userGender: userGender ?? this.userGender,
      userArea: userArea ?? this.userArea,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      yoroCount: yoroCount ?? this.yoroCount,
      yoroUserIds: yoroUserIds ?? this.yoroUserIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAge': userAge,
      'userGender': userGender,
      'userArea': userArea,
      'userProfileImageUrl': userProfileImageUrl,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'yoroCount': yoroCount,
      'yoroUserIds': yoroUserIds,
    };
  }

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAge: json['userAge'] as int,
      userGender: json['userGender'] as String,
      userArea: json['userArea'] as String,
      userProfileImageUrl: json['userProfileImageUrl'] as String?,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      yoroCount: json['yoroCount'] as int? ?? 0,
      yoroUserIds: (json['yoroUserIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  String get userDisplayInfo => '$userAge / $userGender / $userArea';

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
