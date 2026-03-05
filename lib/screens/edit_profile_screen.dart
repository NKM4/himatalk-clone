import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/ng_word_filter.dart';
import '../theme/app_theme.dart';

/// プロフィール編集画面
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _msgController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _storageService = StorageService();

  int _selectedSex = Gender.unknown;
  int _selectedAge = 20;
  int _selectedPlace = 0;
  bool _isLoading = false;
  XFile? _selectedImage;
  String? _ngError;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  void _loadCurrentProfile() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _nameController.text = user.name;
      _msgController.text = user.msg;
      _selectedSex = user.sex;
      _selectedAge = user.age;
      _selectedPlace = user.place;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール編集'),
        backgroundColor: AppTheme.primary,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              '保存',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // プロフィール画像
                    Center(
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: AppTheme.getGenderColor(_selectedSex).withValues(alpha: 0.2),
                              backgroundImage: _selectedImage != null
                                  ? NetworkImage(_selectedImage!.path)
                                  : (currentUser?.img != null
                                      ? NetworkImage(currentUser!.img!)
                                      : null),
                              child: _selectedImage == null && currentUser?.img == null
                                  ? Icon(
                                      Icons.person,
                                      size: 60,
                                      color: AppTheme.getGenderColor(_selectedSex),
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ニックネーム
                    const Text('ニックネーム', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      maxLength: 20,
                      decoration: const InputDecoration(
                        hintText: 'ニックネームを入力',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'ニックネームを入力してください';
                        if (NgWordFilter.containsNgWord(value)) return '不適切な内容が含まれています';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ひとこと
                    const Text('ひとこと', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _msgController,
                      maxLength: 30,
                      decoration: InputDecoration(
                        hintText: 'ひとことを入力',
                        border: const OutlineInputBorder(),
                        errorText: _ngError,
                      ),
                      onChanged: (value) {
                        final validation = NgWordFilter.validate(value);
                        setState(() {
                          _ngError = validation.isValid ? null : validation.error;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // 性別
                    const Text('性別', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildGenderChip('男性', Gender.male, AppTheme.male),
                        const SizedBox(width: 8),
                        _buildGenderChip('女性', Gender.female, AppTheme.female),
                        const SizedBox(width: 8),
                        _buildGenderChip('未設定', Gender.unknown, Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 年齢
                    const Text('年齢', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedAge,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: List.generate(
                        83,
                        (i) => DropdownMenuItem(value: i + 18, child: Text('${i + 18}歳')),
                      ),
                      onChanged: (v) => setState(() => _selectedAge = v ?? 20),
                    ),
                    const SizedBox(height: 16),

                    // 地域
                    const Text('地域', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _selectedPlace,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: Prefecture.list.asMap().entries.map((e) {
                        return DropdownMenuItem(value: e.key, child: Text(e.value));
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedPlace = v ?? 0),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGenderChip(String label, int value, Color color) {
    final isSelected = _selectedSex == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withValues(alpha: 0.3),
      onSelected: (_) => setState(() => _selectedSex = value),
    );
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('カメラで撮影'),
              onTap: () async {
                Navigator.pop(context);
                final image = await _storageService.pickFromCamera();
                if (image != null) setState(() => _selectedImage = image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ライブラリから選択'),
              onTap: () async {
                Navigator.pop(context);
                final image = await _storageService.pickFromGallery();
                if (image != null) setState(() => _selectedImage = image);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ngError != null) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) throw Exception('ユーザーが見つかりません');

      String? imgUrl = currentUser.img;
      String? imgSUrl = currentUser.imgS;

      // 画像をアップロード
      if (_selectedImage != null) {
        final urls = await _storageService.uploadProfileImage(
          userId: currentUser.uid,
          imageFile: _selectedImage!,
          onProgress: (p) => debugPrint('アップロード: ${(p * 100).toInt()}%'),
        );
        imgUrl = urls.large;
        imgSUrl = urls.small;
      }

      // プロフィール更新
      final updatedUser = currentUser.copyWith(
        name: _nameController.text,
        msg: _msgController.text,
        sex: _selectedSex,
        age: _selectedAge,
        place: _selectedPlace,
        img: imgUrl,
        imgS: imgSUrl,
        updatedAt: DateTime.now(),
      );

      await _firestoreService.updateUserProfile(updatedUser);
      ref.read(currentUserProvider.notifier).setUser(updatedUser);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロフィールを更新しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
