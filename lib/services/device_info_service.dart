import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// デバイス情報サービス
/// 運営用ユーザー照会のためのデバイス・IP情報を取得
class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  final _deviceInfo = DeviceInfoPlugin();
  DeviceData? _cachedDeviceData;

  /// デバイス情報を取得
  Future<DeviceData> getDeviceData() async {
    if (_cachedDeviceData != null) return _cachedDeviceData!;

    String deviceId = '';
    String deviceModel = '';
    String osVersion = '';
    String platform = '';
    String appVersion = '';
    String? ipAddress;

    try {
      // パッケージ情報
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      // プラットフォーム別デバイス情報
      if (kIsWeb) {
        platform = 'web';
        final webInfo = await _deviceInfo.webBrowserInfo;
        deviceId = webInfo.userAgent ?? 'unknown';
        deviceModel = '${webInfo.browserName.name} on ${webInfo.platform}';
        osVersion = webInfo.platform ?? 'unknown';
      } else if (Platform.isAndroid) {
        platform = 'android';
        final androidInfo = await _deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
        osVersion = 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      } else if (Platform.isIOS) {
        platform = 'ios';
        final iosInfo = await _deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? 'unknown';
        deviceModel = '${iosInfo.name} (${iosInfo.model})';
        osVersion = '${iosInfo.systemName} ${iosInfo.systemVersion}';
      } else if (Platform.isWindows) {
        platform = 'windows';
        final windowsInfo = await _deviceInfo.windowsInfo;
        deviceId = windowsInfo.deviceId;
        deviceModel = windowsInfo.computerName;
        osVersion = 'Windows ${windowsInfo.majorVersion}.${windowsInfo.minorVersion}';
      } else if (Platform.isMacOS) {
        platform = 'macos';
        final macInfo = await _deviceInfo.macOsInfo;
        deviceId = macInfo.systemGUID ?? 'unknown';
        deviceModel = macInfo.model;
        osVersion = 'macOS ${macInfo.osRelease}';
      } else if (Platform.isLinux) {
        platform = 'linux';
        final linuxInfo = await _deviceInfo.linuxInfo;
        deviceId = linuxInfo.machineId ?? 'unknown';
        deviceModel = linuxInfo.prettyName;
        osVersion = linuxInfo.versionId ?? 'unknown';
      }

      // IP アドレス取得（外部API使用）
      ipAddress = await _getPublicIp();
    } catch (e) {
      debugPrint('DeviceInfoService error: $e');
    }

    _cachedDeviceData = DeviceData(
      deviceId: deviceId,
      deviceModel: deviceModel,
      osVersion: osVersion,
      platform: platform,
      appVersion: appVersion,
      ipAddress: ipAddress,
      collectedAt: DateTime.now(),
    );

    return _cachedDeviceData!;
  }

  /// 公開IPアドレスを取得
  Future<String?> _getPublicIp() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.ipify.org'),
      ).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return response.body.trim();
      }
    } catch (e) {
      debugPrint('Failed to get public IP: $e');
    }
    return null;
  }

  /// キャッシュをクリア
  void clearCache() {
    _cachedDeviceData = null;
  }
}

/// デバイス情報データクラス
class DeviceData {
  final String deviceId;
  final String deviceModel;
  final String osVersion;
  final String platform;
  final String appVersion;
  final String? ipAddress;
  final DateTime collectedAt;

  DeviceData({
    required this.deviceId,
    required this.deviceModel,
    required this.osVersion,
    required this.platform,
    required this.appVersion,
    this.ipAddress,
    required this.collectedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'deviceModel': deviceModel,
      'osVersion': osVersion,
      'platform': platform,
      'appVersion': appVersion,
      'ipAddress': ipAddress,
      'collectedAt': collectedAt.toIso8601String(),
    };
  }

  factory DeviceData.fromMap(Map<String, dynamic> map) {
    return DeviceData(
      deviceId: map['deviceId'] ?? '',
      deviceModel: map['deviceModel'] ?? '',
      osVersion: map['osVersion'] ?? '',
      platform: map['platform'] ?? '',
      appVersion: map['appVersion'] ?? '',
      ipAddress: map['ipAddress'],
      collectedAt: map['collectedAt'] != null
          ? DateTime.parse(map['collectedAt'])
          : DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'DeviceData(platform: $platform, model: $deviceModel, os: $osVersion, ip: $ipAddress)';
  }
}
