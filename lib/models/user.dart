import 'package:cloud_firestore/cloud_firestore.dart';

class Gender {
  static const int unknown = 0;
  static const int male = 1;
  static const int female = 2;
  static String toDisplayString(int value) {
    switch (value) { case male: return '男性'; case female: return '女性'; default: return '未設定'; }
  }
  static String getName(int value) => toDisplayString(value);
  static int fromDisplayString(String value) {
    switch (value) { case '男性': return male; case '女性': return female; default: return unknown; }
  }
}

class Prefecture {
  static const List<String> list = ['未設定','北海道','青森県','岩手県','宮城県','秋田県','山形県','福島県','茨城県','栃木県','群馬県','埼玉県','千葉県','東京都','神奈川県','新潟県','富山県','石川県','福井県','山梨県','長野県','岐阜県','静岡県','愛知県','三重県','滋賀県','京都府','大阪府','兵庫県','奈良県','和歌山県','鳥取県','島根県','岡山県','広島県','山口県','徳島県','香川県','愛媛県','高知県','福岡県','佐賀県','長崎県','熊本県','大分県','宮崎県','鹿児島県','沖縄県','海外'];
  static String toDisplayString(int code) { if (code >= 0 && code < list.length) return list[code]; return '未設定'; }
  static String getName(int code) => toDisplayString(code);
  static int fromDisplayString(String name) { final index = list.indexOf(name); return index >= 0 ? index : 0; }
}

class User {
  final String uid; final int sex; final int place; final int age; final String name; final String msg;
  final String? img; final String? imgS; final DateTime createdAt; final DateTime updatedAt;
  final bool isSecret; final DateTime? secretUntil; final bool isBanned; final String? banReason;
  final DateTime? bannedAt; final List<String> blockedUserIds; final String? deviceToken;
  final String? lastIpAddress; final String? deviceId; final String? deviceModel;
  final String? osVersion; final String? platform; final String? appVersion;
  final String? googlePlayId; final String? appleId; final List<String> ipHistory;
  final int reportCount; final int warningCount; final bool isAdmin;

  User({required this.uid, this.sex = Gender.unknown, this.place = 0, required this.age,
    required this.name, this.msg = '', this.img, this.imgS, required this.createdAt,
    required this.updatedAt, this.isSecret = false, this.secretUntil, this.isBanned = false,
    this.banReason, this.bannedAt, this.blockedUserIds = const [], this.deviceToken,
    this.lastIpAddress, this.deviceId, this.deviceModel, this.osVersion, this.platform,
    this.appVersion, this.googlePlayId, this.appleId, this.ipHistory = const [],
    this.reportCount = 0, this.warningCount = 0, this.isAdmin = false});

  bool get isOnline => DateTime.now().difference(updatedAt).inMinutes < 5;
  String get genderDisplay => Gender.toDisplayString(sex);
  String get placeDisplay => Prefecture.toDisplayString(place);
  String get displayInfo => '$age歳 / $genderDisplay / $placeDisplay';
  String get lastActiveText => ago;
  String get ago { final diff = DateTime.now().difference(updatedAt);
    if (diff.inMinutes < 1) return 'たった今'; if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前'; if (diff.inDays < 7) return '${diff.inDays}日前';
    return '${diff.inDays ~/ 7}週間前'; }

  User copyWith({String? uid, int? sex, int? place, int? age, String? name, String? msg,
    String? img, String? imgS, DateTime? createdAt, DateTime? updatedAt, bool? isSecret,
    DateTime? secretUntil, bool? isBanned, String? banReason, DateTime? bannedAt,
    List<String>? blockedUserIds, String? deviceToken, String? lastIpAddress, String? deviceId,
    String? deviceModel, String? osVersion, String? platform, String? appVersion,
    String? googlePlayId, String? appleId, List<String>? ipHistory,
    int? reportCount, int? warningCount, bool? isAdmin}) {
    return User(uid: uid ?? this.uid, sex: sex ?? this.sex, place: place ?? this.place,
      age: age ?? this.age, name: name ?? this.name, msg: msg ?? this.msg, img: img ?? this.img,
      imgS: imgS ?? this.imgS, createdAt: createdAt ?? this.createdAt, updatedAt: updatedAt ?? this.updatedAt,
      isSecret: isSecret ?? this.isSecret, secretUntil: secretUntil ?? this.secretUntil,
      isBanned: isBanned ?? this.isBanned, banReason: banReason ?? this.banReason,
      bannedAt: bannedAt ?? this.bannedAt, blockedUserIds: blockedUserIds ?? this.blockedUserIds,
      deviceToken: deviceToken ?? this.deviceToken, lastIpAddress: lastIpAddress ?? this.lastIpAddress,
      deviceId: deviceId ?? this.deviceId, deviceModel: deviceModel ?? this.deviceModel,
      osVersion: osVersion ?? this.osVersion, platform: platform ?? this.platform,
      appVersion: appVersion ?? this.appVersion, googlePlayId: googlePlayId ?? this.googlePlayId,
      appleId: appleId ?? this.appleId, ipHistory: ipHistory ?? this.ipHistory,
      reportCount: reportCount ?? this.reportCount, warningCount: warningCount ?? this.warningCount,
      isAdmin: isAdmin ?? this.isAdmin); }

  Map<String, dynamic> toFirestore() => {'uid': uid, 'sex': sex, 'place': place, 'age': age, 'name': name,
    'msg': msg, 'img': img, 'imgS': imgS, 'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt), 'isSecret': isSecret,
    'secretUntil': secretUntil != null ? Timestamp.fromDate(secretUntil!) : null, 'isBanned': isBanned,
    'banReason': banReason, 'bannedAt': bannedAt != null ? Timestamp.fromDate(bannedAt!) : null,
    'blockedUserIds': blockedUserIds, 'deviceToken': deviceToken, 'lastIpAddress': lastIpAddress,
    'deviceId': deviceId, 'deviceModel': deviceModel, 'osVersion': osVersion, 'platform': platform,
    'appVersion': appVersion, 'googlePlayId': googlePlayId, 'appleId': appleId, 'ipHistory': ipHistory,
    'reportCount': reportCount, 'warningCount': warningCount, 'isAdmin': isAdmin};

  factory User.fromFirestore(DocumentSnapshot doc) { final data = doc.data() as Map<String, dynamic>;
    return User(uid: doc.id, sex: data['sex'] as int? ?? Gender.unknown, place: data['place'] as int? ?? 0,
      age: data['age'] as int? ?? 20, name: data['name'] as String? ?? 'ゲスト', msg: data['msg'] as String? ?? '',
      img: data['img'] as String?, imgS: data['imgS'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSecret: data['isSecret'] as bool? ?? false, secretUntil: (data['secretUntil'] as Timestamp?)?.toDate(),
      isBanned: data['isBanned'] as bool? ?? false, banReason: data['banReason'] as String?,
      bannedAt: (data['bannedAt'] as Timestamp?)?.toDate(),
      blockedUserIds: (data['blockedUserIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      deviceToken: data['deviceToken'] as String?, lastIpAddress: data['lastIpAddress'] as String?,
      deviceId: data['deviceId'] as String?, deviceModel: data['deviceModel'] as String?,
      osVersion: data['osVersion'] as String?, platform: data['platform'] as String?,
      appVersion: data['appVersion'] as String?, googlePlayId: data['googlePlayId'] as String?,
      appleId: data['appleId'] as String?,
      ipHistory: (data['ipHistory'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      reportCount: data['reportCount'] as int? ?? 0, warningCount: data['warningCount'] as int? ?? 0,
      isAdmin: data['isAdmin'] as bool? ?? false); }

  factory User.defaultUser(String uid) { final now = DateTime.now();
    return User(uid: uid, sex: Gender.unknown, place: 0, age: 20, name: 'ゲスト', msg: '', createdAt: now, updatedAt: now); }
}
