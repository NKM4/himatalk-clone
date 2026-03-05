import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// Firebase Storage サービス
/// 画像アップロード機能を提供
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  /// プロフィール画像をアップロード
  Future<ProfileImageUrls> uploadProfileImage({
    required String userId,
    required XFile imageFile,
    void Function(double)? onProgress,
  }) async {
    final extension = imageFile.path.split('.').last;
    final fileName = '${_uuid.v4()}.$extension';
    final largePath = 'users/$userId/profile/$fileName';
    final smallPath = 'users/$userId/profile/thumb_$fileName';

    // 大きい画像をアップロード
    final largeRef = _storage.ref().child(largePath);
    final uploadTask = kIsWeb
        ? largeRef.putData(await imageFile.readAsBytes())
        : largeRef.putFile(File(imageFile.path));

    // 進捗通知
    uploadTask.snapshotEvents.listen((event) {
      final progress = event.bytesTransferred / event.totalBytes;
      onProgress?.call(progress);
    });

    await uploadTask;
    final largeUrl = await largeRef.getDownloadURL();

    // サムネイル（Web/モバイルで同じ画像を使用、リサイズはCloud Functionsで）
    final smallUrl = largeUrl; // TODO: Cloud Functionsでリサイズ

    return ProfileImageUrls(large: largeUrl, small: smallUrl);
  }

  /// チャット画像をアップロード
  Future<String> uploadChatImage({
    required String roomKey,
    required XFile imageFile,
    void Function(double)? onProgress,
  }) async {
    final extension = imageFile.path.split('.').last;
    final fileName = '${_uuid.v4()}.$extension';
    final path = 'chats/$roomKey/$fileName';

    final ref = _storage.ref().child(path);
    final uploadTask = kIsWeb
        ? ref.putData(await imageFile.readAsBytes())
        : ref.putFile(File(imageFile.path));

    uploadTask.snapshotEvents.listen((event) {
      final progress = event.bytesTransferred / event.totalBytes;
      onProgress?.call(progress);
    });

    await uploadTask;
    return await ref.getDownloadURL();
  }

  /// 画像を選択（カメラ）
  Future<XFile?> pickFromCamera() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Camera error: $e');
      return null;
    }
  }

  /// 画像を選択（ギャラリー）
  Future<XFile?> pickFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Gallery error: $e');
      return null;
    }
  }

  /// 画像を削除
  Future<void> deleteImage(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      debugPrint('Delete error: $e');
    }
  }
}

/// プロフィール画像URL
class ProfileImageUrls {
  final String large;
  final String small;

  ProfileImageUrls({required this.large, required this.small});
}
