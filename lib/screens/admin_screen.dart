import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

/// 運営用管理画面
/// ユーザー照会・凍結機能
class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _searchController = TextEditingController();
  String _searchType = 'uid'; // uid, ip, deviceId, name
  List<User> _searchResults = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    // 管理者チェック
    if (currentUser == null || !currentUser.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('管理画面'), backgroundColor: AppTheme.error),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('アクセス権限がありません', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('運営管理'),
        backgroundColor: AppTheme.error,
      ),
      body: Column(
        children: [
          // 検索タイプ選択
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                Row(
                  children: [
                    _buildSearchTypeChip('UID', 'uid'),
                    const SizedBox(width: 8),
                    _buildSearchTypeChip('IP', 'ip'),
                    const SizedBox(width: 8),
                    _buildSearchTypeChip('デバイスID', 'deviceId'),
                    const SizedBox(width: 8),
                    _buildSearchTypeChip('名前', 'name'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: _getSearchHint(),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _search,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                      child: const Text('検索'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 統計情報
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('総ユーザー', Icons.people),
                _buildStatCard('BAN中', Icons.block),
                _buildStatCard('通報件数', Icons.flag),
              ],
            ),
          ),

          // 検索結果
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.error))
                : _searchResults.isEmpty
                    ? const Center(child: Text('検索結果がありません'))
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          return _buildUserCard(_searchResults[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchTypeChip(String label, String value) {
    final isSelected = _searchType == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: AppTheme.error.withValues(alpha: 0.3),
      onSelected: (_) => setState(() => _searchType = value),
    );
  }

  String _getSearchHint() {
    switch (_searchType) {
      case 'ip': return 'IPアドレスを入力';
      case 'deviceId': return 'デバイスIDを入力';
      case 'name': return 'ユーザー名を入力';
      default: return 'ユーザーIDを入力';
    }
  }

  Widget _buildStatCard(String label, IconData icon) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getStatStream(label),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, color: AppTheme.error),
                const SizedBox(height: 4),
                Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  Stream<QuerySnapshot> _getStatStream(String label) {
    switch (label) {
      case 'BAN中':
        return _firestore.collection('users').where('isBanned', isEqualTo: true).snapshots();
      case '通報件数':
        return _firestore.collection('reports').where('status', isEqualTo: 'pending').snapshots();
      default:
        return _firestore.collection('users').snapshots();
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      QuerySnapshot snapshot;

      switch (_searchType) {
        case 'ip':
          snapshot = await _firestore.collection('users')
              .where('lastIpAddress', isEqualTo: query)
              .get();
          // IP履歴も検索
          final historySnapshot = await _firestore.collection('users')
              .where('ipHistory', arrayContains: query)
              .get();
          final combined = [...snapshot.docs, ...historySnapshot.docs];
          final uniqueIds = <String>{};
          _searchResults = combined
              .where((doc) => uniqueIds.add(doc.id))
              .map((doc) => User.fromFirestore(doc))
              .toList();
          break;

        case 'deviceId':
          snapshot = await _firestore.collection('users')
              .where('deviceId', isEqualTo: query)
              .get();
          _searchResults = snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
          break;

        case 'name':
          snapshot = await _firestore.collection('users')
              .where('name', isGreaterThanOrEqualTo: query)
              .where('name', isLessThan: '${query}z')
              .get();
          _searchResults = snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
          break;

        default: // uid
          final doc = await _firestore.collection('users').doc(query).get();
          _searchResults = doc.exists ? [User.fromFirestore(doc)] : [];
      }

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildUserCard(User user) {
    final genderColor = AppTheme.getGenderColor(user.sex);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: genderColor.withValues(alpha: 0.2),
              backgroundImage: user.img != null ? NetworkImage(user.img!) : null,
              child: user.img == null ? Icon(Icons.person, color: genderColor) : null,
            ),
            if (user.isBanned)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: AppTheme.error, shape: BoxShape.circle),
                  child: const Icon(Icons.block, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (user.isBanned) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('BAN', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ],
          ],
        ),
        subtitle: Text('${user.age}歳 / ${Gender.getName(user.sex)} / ${Prefecture.getName(user.place)}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 照会情報
                _buildInfoRow('UID', user.uid),
                _buildInfoRow('最終IP', user.lastIpAddress ?? '不明'),
                _buildInfoRow('デバイスID', user.deviceId ?? '不明'),
                _buildInfoRow('デバイス', user.deviceModel ?? '不明'),
                _buildInfoRow('OS', user.osVersion ?? '不明'),
                _buildInfoRow('プラットフォーム', user.platform ?? '不明'),
                _buildInfoRow('アプリVer', user.appVersion ?? '不明'),
                _buildInfoRow('Google ID', user.googlePlayId ?? '未連携'),
                _buildInfoRow('Apple ID', user.appleId ?? '未連携'),
                _buildInfoRow('通報回数', '${user.reportCount}回'),
                _buildInfoRow('警告回数', '${user.warningCount}回'),
                _buildInfoRow('登録日', _formatDate(user.createdAt)),
                _buildInfoRow('最終活動', user.ago),

                // IP履歴
                if (user.ipHistory.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('IP履歴:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...user.ipHistory.map((ip) => Text('  • $ip', style: TextStyle(color: Colors.grey[600]))),
                ],

                // BAN情報
                if (user.isBanned && user.banReason != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('BAN理由:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error)),
                        Text(user.banReason!),
                        if (user.bannedAt != null) Text('BAN日時: ${_formatDate(user.bannedAt!)}'),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // アクションボタン
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (!user.isBanned)
                      ElevatedButton.icon(
                        onPressed: () => _showBanDialog(user),
                        icon: const Icon(Icons.block, size: 16),
                        label: const Text('凍結'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => _unbanUser(user),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('解除'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.online),
                      ),
                    ElevatedButton.icon(
                      onPressed: () => _showWarningDialog(user),
                      icon: const Icon(Icons.warning, size: 16),
                      label: const Text('警告'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _searchRelatedUsers(user),
                      icon: const Icon(Icons.search, size: 16),
                      label: const Text('関連検索'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            child: SelectableText(value, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showBanDialog(User user) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${user.name}を凍結'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('凍結理由を入力してください'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '凍結理由',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _banUser(user, reasonController.text);
            },
            child: const Text('凍結', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _banUser(User user, String reason) async {
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isBanned': true,
        'banReason': reason,
        'bannedAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name}を凍結しました')),
        );
        _search(); // 再検索
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _unbanUser(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isBanned': false,
        'banReason': null,
        'bannedAt': null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name}の凍結を解除しました')),
        );
        _search();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _showWarningDialog(User user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('${user.name}に警告'),
        content: const Text('警告を送信しますか？（警告回数がカウントされます）'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firestore.collection('users').doc(user.uid).update({
                'warningCount': FieldValue.increment(1),
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${user.name}に警告を送信しました')),
                );
                _search();
              }
            },
            child: const Text('警告', style: TextStyle(color: AppTheme.warning)),
          ),
        ],
      ),
    );
  }

  void _searchRelatedUsers(User user) {
    // 同じIP/デバイスIDを持つユーザーを検索
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('関連ユーザー検索'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('同じIPアドレス'),
              subtitle: Text(user.lastIpAddress ?? '不明'),
              onTap: () {
                Navigator.pop(context);
                if (user.lastIpAddress != null) {
                  _searchController.text = user.lastIpAddress!;
                  _searchType = 'ip';
                  _search();
                }
              },
            ),
            ListTile(
              title: const Text('同じデバイスID'),
              subtitle: Text(user.deviceId ?? '不明'),
              onTap: () {
                Navigator.pop(context);
                if (user.deviceId != null) {
                  _searchController.text = user.deviceId!;
                  _searchType = 'deviceId';
                  _search();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
