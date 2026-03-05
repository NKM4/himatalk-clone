import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

/// ブロックリスト画面
class BlockListScreen extends ConsumerStatefulWidget {
  const BlockListScreen({super.key});

  @override
  ConsumerState<BlockListScreen> createState() => _BlockListScreenState();
}

class _BlockListScreenState extends ConsumerState<BlockListScreen> {
  final _firestoreService = FirestoreService();
  List<User> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      final users = await _firestoreService.getBlockedUsers(currentUser.uid);
      if (mounted) {
        setState(() {
          _blockedUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ブロックリスト'),
        backgroundColor: AppTheme.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _blockedUsers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('ブロックしているユーザーはいません',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _blockedUsers.length,
                  itemBuilder: (context, index) {
                    final user = _blockedUsers[index];
                    return _buildBlockedUserTile(user);
                  },
                ),
    );
  }

  Widget _buildBlockedUserTile(User user) {
    final genderColor = AppTheme.getGenderColor(user.sex);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: genderColor.withValues(alpha: 0.2),
        backgroundImage: user.img != null ? NetworkImage(user.img!) : null,
        child: user.img == null
            ? Icon(Icons.person, color: genderColor)
            : null,
      ),
      title: Text(user.name),
      subtitle: Text('${user.age}歳 / ${Gender.getName(user.sex)} / ${Prefecture.getName(user.place)}'),
      trailing: TextButton(
        onPressed: () => _showUnblockDialog(user),
        child: const Text('解除', style: TextStyle(color: AppTheme.primary)),
      ),
    );
  }

  void _showUnblockDialog(User user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ブロック解除'),
        content: Text('${user.name}のブロックを解除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _unblockUser(user);
            },
            child: const Text('解除', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _unblockUser(User user) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      await _firestoreService.unblockUser(currentUser.uid, user.uid);
      setState(() {
        _blockedUsers.removeWhere((u) => u.uid == user.uid);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name}のブロックを解除しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }
}
