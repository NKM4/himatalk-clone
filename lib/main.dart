import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/ng_word_filter.dart';
import 'models/user.dart';
import 'models/message.dart';
import 'models/friendship.dart';
import 'theme/app_theme.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/block_list_screen.dart';
import 'screens/admin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const ProviderScope(child: HimaTalkApp()));
}

class HimaTalkApp extends ConsumerStatefulWidget {
  const HimaTalkApp({super.key});

  @override
  ConsumerState<HimaTalkApp> createState() => _HimaTalkAppState();
}

class _HimaTalkAppState extends ConsumerState<HimaTalkApp> {
  bool _isLoading = true;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _autoLogin();
  }

  Future<void> _autoLogin() async {
    try {
      final user = await _authService.signInAnonymously();
      if (user != null) {
        ref.read(currentUserProvider.notifier).setUser(user);
        ref.read(authStateProvider.notifier).setAuthenticated();
      }
    } catch (e) {
      debugPrint('Auto login error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ひまトーク+',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // APKカラーテーマ
      darkTheme: AppTheme.darkTheme,
      home: _isLoading ? const SplashScreen() : const MainScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // APKロゴ風アイコン
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.chat_bubble,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'ひまトーク+',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '暇つぶしトークアプリ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: AppTheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              '接続中...',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});
  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TimelinePage(),
          SearchPage(),
          ChatListPage(),
          NotificationPage(),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'タイムライン',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: '探す',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'トーク',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'お知らせ',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showPostDialog(context),
              backgroundColor: AppTheme.primary,
              child: const Icon(Icons.edit, color: Colors.white),
            )
          : null,
    );
  }

  void _showPostDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const PostSheet(),
    );
  }
}

// ==================== タイムラインページ ====================
class TimelinePage extends ConsumerWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreService = FirestoreService();
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('タイムライン'),
        backgroundColor: AppTheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
            tooltip: '更新',
          ),
        ],
      ),
      body: StreamBuilder<List<User>>(
        stream: firestoreService.getTimelineUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('エラー: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('まだユーザーがいません', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async {},
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) => PostCard(
                user: users[index],
                currentUserId: currentUser?.uid,
              ),
            ),
          );
        },
      ),
    );
  }
}

class PostCard extends StatelessWidget {
  final User user;
  final String? currentUserId;

  const PostCard({
    super.key,
    required this.user,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final genderColor = AppTheme.getGenderColor(user.sex);
    final isOnline = user.isOnline;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // プロフィール画像
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: genderColor.withValues(alpha: 0.2),
                      backgroundImage: user.img != null
                          ? NetworkImage(user.img!)
                          : null,
                      child: user.img == null
                          ? Icon(Icons.person, color: genderColor)
                          : null,
                    ),
                    // オンライン状態
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isOnline ? AppTheme.online : AppTheme.offline,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 性別アイコン
                          Icon(
                            user.sex == 1 ? Icons.male : Icons.female,
                            size: 18,
                            color: genderColor,
                          ),
                        ],
                      ),
                      Text(
                        '${user.age}歳 / ${Gender.getName(user.sex)} / ${Prefecture.getName(user.place)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  user.lastActiveText,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ひとこと表示
            if (user.msg.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.format_quote, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        user.msg,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // よろ！ボタン（APKカラー）
                TextButton.icon(
                  onPressed: () => _sendYoro(context, user.uid),
                  style: YoroButtonStyle.outlined,
                  icon: const Icon(Icons.waving_hand, size: 18),
                  label: const Text('よろ！'),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomPage(
                        partnerId: user.uid,
                        partnerName: user.name,
                        partnerImage: user.imgS,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: const Text('トーク'),
                ),
                TextButton.icon(
                  onPressed: () => _showUserProfile(context, user),
                  icon: const Icon(Icons.person_outline, size: 18),
                  label: const Text('プロフ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sendYoro(BuildContext context, String toUserId) async {
    debugPrint('[DEBUG] _sendYoro called: currentUserId=$currentUserId, toUserId=$toUserId');

    if (currentUserId == null) {
      debugPrint('[DEBUG] _sendYoro: currentUserId is null, showing login prompt');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ログインしてください'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return;
    }

    final firestoreService = FirestoreService();
    try {
      debugPrint('[DEBUG] _sendYoro: calling firestoreService.sendYoro');
      await firestoreService.sendYoro(currentUserId!, toUserId);
      debugPrint('[DEBUG] _sendYoro: success');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('よろ！を送りました'),
            backgroundColor: AppTheme.accent,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[ERROR] _sendYoro failed: $e');
      debugPrint('[ERROR] Stack trace: $stackTrace');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('エラー'),
            content: SingleChildScrollView(
              child: Text('$e\n\n$stackTrace'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('閉じる'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showUserProfile(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => UserProfileSheet(user: user, currentUserId: currentUserId),
    );
  }
}

// ユーザープロフィールシート
class UserProfileSheet extends StatelessWidget {
  final User user;
  final String? currentUserId;

  const UserProfileSheet({
    super.key,
    required this.user,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final genderColor = AppTheme.getGenderColor(user.sex);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // ハンドル
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // プロフィール画像
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: genderColor.withValues(alpha: 0.2),
                  backgroundImage: user.img != null
                      ? NetworkImage(user.img!)
                      : null,
                  child: user.img == null
                      ? Icon(Icons.person, size: 50, color: genderColor)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              // 名前と性別
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      user.sex == 1 ? Icons.male : Icons.female,
                      color: genderColor,
                      size: 28,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // 基本情報
              Center(
                child: Text(
                  '${user.age}歳 / ${Gender.getName(user.sex)} / ${Prefecture.getName(user.place)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              // ひとこと
              if (user.msg.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.format_quote, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'ひとこと',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(user.msg, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              // 仲良しレベル表示（Firestoreから取得）
              FutureBuilder<Friendship?>(
                future: _getFriendship(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const SizedBox.shrink();
                  }
                  return _buildFriendshipLevel(snapshot.data!);
                },
              ),
              const SizedBox(height: 24),
              // アクションボタン
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _sendYoro(context),
                      icon: const Icon(Icons.waving_hand),
                      label: const Text('よろ！'),
                      style: YoroButtonStyle.elevated,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatRoomPage(
                              partnerId: user.uid,
                              partnerName: user.name,
                              partnerImage: user.imgS,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat),
                      label: const Text('トーク'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ブロック・通報ボタン
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => _showBlockConfirm(context),
                    icon: const Icon(Icons.block, color: AppTheme.error, size: 18),
                    label: const Text('ブロック', style: TextStyle(color: AppTheme.error)),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () => _showReportDialog(context),
                    icon: const Icon(Icons.flag, color: AppTheme.warning, size: 18),
                    label: const Text('通報', style: TextStyle(color: AppTheme.warning)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Friendship?> _getFriendship() async {
    if (currentUserId == null) return null;
    final firestoreService = FirestoreService();
    return await firestoreService.getFriendship(currentUserId!, user.uid);
  }

  Widget _buildFriendshipLevel(Friendship friendship) {
    final levelColor = AppTheme.getFriendshipLevelColor(friendship.level);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '仲良しレベル',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: levelColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Lv.${friendship.level} ${friendship.levelName}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // プログレスバー
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: friendship.levelProgress,
              backgroundColor: Colors.grey[200],
              color: levelColor,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          if (friendship.level < 5)
            Text(
              '次のレベルまであと${friendship.messagesUntilNextLevel}通',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          const SizedBox(height: 8),
          // 制限情報
          Row(
            children: [
              Icon(Icons.message, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '文字数: ${friendship.maxMessageLength}文字まで',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(width: 16),
              Icon(
                friendship.canSendPhoto ? Icons.photo : Icons.photo_outlined,
                size: 16,
                color: friendship.canSendPhoto ? AppTheme.online : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                friendship.canSendPhoto ? '写真送信OK' : '写真送信不可',
                style: TextStyle(
                  color: friendship.canSendPhoto ? AppTheme.online : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendYoro(BuildContext context) async {
    debugPrint('[DEBUG] _sendYoro(profile) called: currentUserId=$currentUserId, toUserId=${user.uid}');

    if (currentUserId == null) {
      debugPrint('[DEBUG] _sendYoro(profile): currentUserId is null');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ログインしてください'), backgroundColor: AppTheme.error),
        );
      }
      return;
    }

    final firestoreService = FirestoreService();
    try {
      debugPrint('[DEBUG] _sendYoro(profile): calling sendYoro');
      await firestoreService.sendYoro(currentUserId!, user.uid);
      debugPrint('[DEBUG] _sendYoro(profile): success');
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('よろ！を送りました'),
            backgroundColor: AppTheme.accent,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[ERROR] _sendYoro(profile) failed: $e');
      debugPrint('[ERROR] Stack trace: $stackTrace');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('エラー'),
            content: SingleChildScrollView(child: Text('$e\n\n$stackTrace')),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('閉じる'))],
          ),
        );
      }
    }
  }

  void _showBlockConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ブロック確認'),
        content: Text('${user.name}をブロックしますか？\nブロックすると、お互いのメッセージが見えなくなります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              if (currentUserId != null) {
                final firestoreService = FirestoreService();
                await firestoreService.blockUser(currentUserId!, user.uid);
              }
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ブロックしました')),
                );
              }
            },
            child: const Text('ブロック', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('通報'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('スパム・宣伝'),
              onTap: () => _submitReport(context, 'spam'),
            ),
            ListTile(
              title: const Text('不適切な内容'),
              onTap: () => _submitReport(context, 'inappropriate'),
            ),
            ListTile(
              title: const Text('嫌がらせ'),
              onTap: () => _submitReport(context, 'harassment'),
            ),
            ListTile(
              title: const Text('なりすまし'),
              onTap: () => _submitReport(context, 'impersonation'),
            ),
            ListTile(
              title: const Text('その他'),
              onTap: () => _submitReport(context, 'other'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitReport(BuildContext context, String reason) async {
    if (currentUserId != null) {
      final firestoreService = FirestoreService();
      await firestoreService.reportUser(
        reporterUid: currentUserId!,
        reportedUid: user.uid,
        reason: reason,
      );
    }
    if (context.mounted) {
      Navigator.pop(context);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('通報しました。ご協力ありがとうございます。')),
      );
    }
  }
}

class PostSheet extends ConsumerStatefulWidget {
  const PostSheet({super.key});
  @override
  ConsumerState<PostSheet> createState() => _PostSheetState();
}

class _PostSheetState extends ConsumerState<PostSheet> {
  final _controller = TextEditingController();
  String? _ngError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            maxLines: 4,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: '今なにしてる？',
              errorText: _ngError,
            ),
            onChanged: (text) {
              // NGワードチェック
              final validation = NgWordFilter.validate(text);
              setState(() {
                _ngError = validation.isValid ? null : validation.error;
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.photo),
                onPressed: () {},
                tooltip: '写真を追加',
              ),
              ElevatedButton(
                onPressed: _ngError == null && _controller.text.isNotEmpty
                    ? () => _updateHitokoto(context)
                    : null,
                child: const Text('投稿'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _updateHitokoto(BuildContext context) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final firestoreService = FirestoreService();
    try {
      await firestoreService.updateUserProfile(
        currentUser.copyWith(msg: _controller.text),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ひとことを更新しました')),
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

// ==================== 探すページ ====================
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});
  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  int? _selectedGender;
  RangeValues _ageRange = const RangeValues(18, 50);
  int? _selectedPlace;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ユーザーを探す'),
        backgroundColor: AppTheme.primary,
      ),
      body: Column(
        children: [
          // 検索フィルター
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.background,
            child: Column(
              children: [
                // 性別フィルター
                Row(
                  children: [
                    const Text('性別: '),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('すべて'),
                      selected: _selectedGender == null,
                      onSelected: (s) => setState(() => _selectedGender = null),
                      selectedColor: AppTheme.primary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 4),
                    ChoiceChip(
                      label: const Text('男性'),
                      selected: _selectedGender == 1,
                      onSelected: (s) => setState(() => _selectedGender = 1),
                      selectedColor: AppTheme.male.withValues(alpha: 0.3),
                    ),
                    const SizedBox(width: 4),
                    ChoiceChip(
                      label: const Text('女性'),
                      selected: _selectedGender == 2,
                      onSelected: (s) => setState(() => _selectedGender = 2),
                      selectedColor: AppTheme.female.withValues(alpha: 0.3),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 年齢フィルター
                Row(
                  children: [
                    Text('年齢: ${_ageRange.start.round()}〜${_ageRange.end.round()}歳'),
                    Expanded(
                      child: RangeSlider(
                        values: _ageRange,
                        min: 18,
                        max: 80,
                        divisions: 62,
                        activeColor: AppTheme.primary,
                        onChanged: (v) => setState(() => _ageRange = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ユーザーリスト
          Expanded(
            child: StreamBuilder<List<User>>(
              stream: FirestoreService().searchUsers(
                sex: _selectedGender,
                minAge: _ageRange.start.round(),
                maxAge: _ageRange.end.round(),
                place: _selectedPlace,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                final users = snapshot.data ?? [];
                if (users.isEmpty) {
                  return const Center(
                    child: Text('該当するユーザーがいません'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: users.length,
                  itemBuilder: (context, index) => UserCard(
                    user: users[index],
                    currentUserId: currentUser?.uid,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class UserCard extends StatelessWidget {
  final User user;
  final String? currentUserId;

  const UserCard({
    super.key,
    required this.user,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final genderColor = AppTheme.getGenderColor(user.sex);

    return Card(
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => UserProfileSheet(
              user: user,
              currentUserId: currentUserId,
            ),
          );
        },
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: genderColor.withValues(alpha: 0.2),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: user.img != null
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Image.network(
                                user.img!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            )
                          : Icon(Icons.person, size: 60, color: genderColor),
                    ),
                    // オンライン表示
                    if (user.isOnline)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.online,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'オンライン',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          user.sex == 1 ? Icons.male : Icons.female,
                          size: 16,
                          color: genderColor,
                        ),
                      ],
                    ),
                    Text(
                      '${user.age}歳 / ${Prefecture.getName(user.place)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    if (user.msg.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.msg,
                        style: TextStyle(color: Colors.grey[700], fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // よろ！・トークボタン
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    context: context,
                    icon: Icons.waving_hand,
                    label: 'よろ！',
                    color: AppTheme.accent,
                    onTap: () => _sendYoro(context),
                  ),
                  _buildActionButton(
                    context: context,
                    icon: Icons.chat,
                    label: 'トーク',
                    color: AppTheme.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoomPage(
                            partnerId: user.uid,
                            partnerName: user.name,
                            partnerImage: user.imgS,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _sendYoro(BuildContext context) async {
    debugPrint('[DEBUG] _sendYoro(card) called: currentUserId=$currentUserId, toUserId=${user.uid}');

    if (currentUserId == null) {
      debugPrint('[DEBUG] _sendYoro(card): currentUserId is null');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ログインしてください'), backgroundColor: AppTheme.error),
        );
      }
      return;
    }

    try {
      debugPrint('[DEBUG] _sendYoro(card): calling sendYoro');
      await FirestoreService().sendYoro(currentUserId!, user.uid);
      debugPrint('[DEBUG] _sendYoro(card): success');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('よろ！を送りました'),
            backgroundColor: AppTheme.accent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[ERROR] _sendYoro(card) failed: $e');
      debugPrint('[ERROR] Stack trace: $stackTrace');
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('エラー'),
            content: SingleChildScrollView(child: Text('$e\n\n$stackTrace')),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('閉じる'))],
          ),
        );
      }
    }
  }
}

// ==================== トークリストページ ====================
class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('ログインが必要です')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('トーク'),
        backgroundColor: AppTheme.primary,
      ),
      body: StreamBuilder<List<Room>>(
        stream: FirestoreService().getRooms(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          final rooms = snapshot.data ?? [];
          if (rooms.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('トーク履歴がありません', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('タイムラインから話しかけてみましょう！', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final levelColor = AppTheme.getFriendshipLevelColor(room.friendshipLevel);

              return ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      backgroundImage: room.partnerImage != null
                          ? NetworkImage(room.partnerImage!)
                          : null,
                      child: room.partnerImage == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    // 仲良しレベルバッジ
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: levelColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          '${room.friendshipLevel}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                title: Text(room.partnerName),
                subtitle: Text(
                  room.lastMessage ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      room.lastUpdatedText,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                    if (!room.readed)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatRoomPage(
                      partnerId: room.partnerUid,
                      partnerName: room.partnerName,
                      partnerImage: room.partnerImage,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatRoomPage extends ConsumerStatefulWidget {
  final String partnerId;
  final String partnerName;
  final String? partnerImage;

  const ChatRoomPage({
    super.key,
    required this.partnerId,
    required this.partnerName,
    this.partnerImage,
  });

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final _controller = TextEditingController();
  final _firestoreService = FirestoreService();
  Friendship? _friendship;
  String? _ngError;
  String? _roomKey;

  @override
  void initState() {
    super.initState();
    _loadFriendship();
  }

  Future<void> _loadFriendship() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    _roomKey = Room.generateRoomKey(currentUser.uid, widget.partnerId);
    final friendship = await _firestoreService.getFriendship(
      currentUser.uid,
      widget.partnerId,
    );
    if (mounted) {
      setState(() {
        _friendship = friendship;
      });
    }

    // 既読マーク
    await _firestoreService.markAsRead(_roomKey!, currentUser.uid);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null || _friendship == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final levelColor = AppTheme.getFriendshipLevelColor(_friendship!.level);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: Column(
          children: [
            Text(widget.partnerName),
            Text(
              'Lv.${_friendship!.level} ${_friendship!.levelName}',
              style: TextStyle(fontSize: 12, color: levelColor),
            ),
          ],
        ),
        actions: [
          if (_friendship!.canSendPhoto)
            IconButton(
              icon: const Icon(Icons.photo),
              onPressed: () => _showPhotoOption(),
              tooltip: '写真を送信',
            ),
          PopupMenuButton(
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'profile', child: Text('プロフィール')),
              const PopupMenuItem(value: 'block', child: Text('ブロック')),
              const PopupMenuItem(value: 'report', child: Text('通報')),
            ],
            onSelected: (v) {
              if (v == 'block') _showBlockDialog();
              if (v == 'report') _showReportDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 仲良しレベル進捗バー
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.background,
            child: Row(
              children: [
                Text(
                  'Lv.${_friendship!.level}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: levelColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _friendship!.levelProgress,
                      backgroundColor: Colors.grey[300],
                      color: levelColor,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_friendship!.level < 5)
                  Text(
                    'Lv.${_friendship!.level + 1}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
              ],
            ),
          ),
          // メッセージリスト
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _roomKey != null
                  ? _firestoreService.getMessages(_roomKey!)
                  : const Stream.empty(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('最初のメッセージを送ってみましょう！', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.fromUserId == currentUser.uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.primary : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        child: msg.type == MessageType.image && msg.url != null
                            ? Image.network(msg.url!, fit: BoxFit.cover)
                            : Text(
                                msg.body,
                                style: TextStyle(color: isMe ? Colors.white : Colors.black),
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // 入力欄
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.background,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                // 文字数制限・NGワードエラー表示
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_controller.text.length}/${_friendship!.maxMessageLength}文字',
                        style: TextStyle(
                          color: _controller.text.length > _friendship!.maxMessageLength
                              ? AppTheme.error
                              : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (_ngError != null)
                        Text(
                          _ngError!,
                          style: const TextStyle(color: AppTheme.error, fontSize: 11),
                        )
                      else if (!_friendship!.canSendPhoto)
                        Text(
                          '写真はLv.3から送信可能',
                          style: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.photo,
                        color: _friendship!.canSendPhoto ? null : Colors.grey[400],
                      ),
                      onPressed: _friendship!.canSendPhoto ? () => _showPhotoOption() : null,
                      tooltip: _friendship!.canSendPhoto ? '写真を送信' : '写真はLv.3から送信可能',
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        maxLength: _friendship!.maxMessageLength,
                        decoration: const InputDecoration(
                          hintText: 'メッセージを入力...',
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        onChanged: (v) {
                          // NGワードチェック
                          final validation = NgWordFilter.validate(v);
                          setState(() {
                            _ngError = validation.isValid ? null : validation.error;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: AppTheme.primary),
                      onPressed: _canSend() ? () => _sendMessage(currentUser.uid) : null,
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

  bool _canSend() {
    return _controller.text.isNotEmpty &&
        _controller.text.length <= _friendship!.maxMessageLength &&
        _ngError == null;
  }

  Future<void> _sendMessage(String userId) async {
    if (!_canSend()) return;

    try {
      await _firestoreService.sendMessage(
        fromUserId: userId,
        toUserId: widget.partnerId,
        body: _controller.text,
      );
      _controller.clear();
      setState(() => _ngError = null);

      // 仲良しレベル更新
      await _loadFriendship();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _showPhotoOption() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('カメラで撮影'),
              onTap: () {
                Navigator.pop(context);
                // TODO: カメラ実装
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('ライブラリから選択'),
              onTap: () {
                Navigator.pop(context);
                // TODO: ギャラリー実装
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ブロック'),
        content: Text('${widget.partnerName}をブロックしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              final currentUser = ref.read(currentUserProvider);
              if (currentUser != null) {
                await _firestoreService.blockUser(currentUser.uid, widget.partnerId);
              }
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ブロックしました')),
                );
              }
            },
            child: const Text('ブロック', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('通報'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('スパム・宣伝'), onTap: () => _submitReport('spam')),
            ListTile(title: const Text('不適切な内容'), onTap: () => _submitReport('inappropriate')),
            ListTile(title: const Text('嫌がらせ'), onTap: () => _submitReport('harassment')),
            ListTile(title: const Text('その他'), onTap: () => _submitReport('other')),
          ],
        ),
      ),
    );
  }

  void _submitReport(String reason) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      await _firestoreService.reportUser(
        reporterUid: currentUser.uid,
        reportedUid: widget.partnerId,
        reason: reason,
      );
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('通報しました')),
      );
    }
  }
}

// ==================== お知らせページ ====================
class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('ログインが必要です')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('お知らせ'),
        backgroundColor: AppTheme.primary,
      ),
      body: StreamBuilder<List<Yoro>>(
        stream: FirestoreService().getReceivedYoros(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          final yoros = snapshot.data ?? [];
          if (yoros.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('お知らせはありません', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: yoros.length,
            itemBuilder: (context, index) {
              final yoro = yoros[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
                  child: const Icon(Icons.waving_hand, color: AppTheme.accent),
                ),
                title: Text('${yoro.fromUserName ?? 'ユーザー'}さんからよろ！'),
                subtitle: Text(yoro.createdAtText),
                onTap: () {
                  // ユーザープロフィールを表示
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ==================== 設定ページ ====================
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _secretMode = false;
  bool _pushNotifications = true;
  DateTime? _secretModeUntil;
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: AppTheme.primary,
      ),
      body: ListView(
        children: [
          // プロフィールヘッダー
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: currentUser != null
                      ? AppTheme.getGenderColor(currentUser.sex).withValues(alpha: 0.2)
                      : Colors.grey[200],
                  backgroundImage: currentUser?.img != null
                      ? NetworkImage(currentUser!.img!)
                      : null,
                  child: currentUser?.img == null
                      ? Icon(
                          Icons.person,
                          size: 40,
                          color: currentUser != null
                              ? AppTheme.getGenderColor(currentUser.sex)
                              : Colors.grey,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.name ?? 'ゲスト',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        currentUser != null
                            ? '${currentUser.age}歳 / ${Gender.getName(currentUser.sex)} / ${Prefecture.getName(currentUser.place)}'
                            : '未設定',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                  },
                  tooltip: 'プロフィール編集',
                ),
              ],
            ),
          ),
          // ひとこと設定
          ListTile(
            leading: const Icon(Icons.format_quote),
            title: const Text('ひとこと'),
            subtitle: Text(
              currentUser?.msg ?? '未設定',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showHitokotoDialog(),
          ),
          const Divider(),
          // シークレットモード
          SwitchListTile(
            title: const Text('シークレットモード'),
            subtitle: Text(
              _secretMode
                  ? '${_secretModeUntil != null ? "${_secretModeUntil!.difference(DateTime.now()).inHours}時間後に自動解除" : "有効中"}'
                  : 'タイムラインと検索に表示されません（最大48時間）',
            ),
            value: _secretMode,
            activeColor: AppTheme.primary,
            onChanged: (v) {
              if (v) {
                _showSecretModeDialog();
              } else {
                setState(() {
                  _secretMode = false;
                  _secretModeUntil = null;
                });
                _authService.setSecretMode(false, null);
              }
            },
            secondary: const Icon(Icons.visibility_off),
          ),
          SwitchListTile(
            title: const Text('プッシュ通知'),
            subtitle: const Text('メッセージやよろ！の通知'),
            value: _pushNotifications,
            activeColor: AppTheme.primary,
            onChanged: (v) => setState(() => _pushNotifications = v),
            secondary: const Icon(Icons.notifications),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('ブロックリスト'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BlockListScreen()),
              );
            },
          ),
          // 管理者専用メニュー
          if (currentUser?.isAdmin == true)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: AppTheme.primary),
              title: const Text('管理画面', style: TextStyle(color: AppTheme.primary)),
              subtitle: const Text('ユーザー照会・凍結'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('ヘルプ'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('利用規約'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('プライバシーポリシー'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.error),
            title: const Text('ログアウト', style: TextStyle(color: AppTheme.error)),
            onTap: () => _showLogoutDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppTheme.error),
            title: const Text('アカウント削除', style: TextStyle(color: AppTheme.error)),
            onTap: () => _showDeleteAccountDialog(),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'バージョン 1.0.0',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }


  void _showHitokotoDialog() {
    final currentUser = ref.read(currentUserProvider);
    final controller = TextEditingController(text: currentUser?.msg ?? '');
    String? ngError;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('ひとことを編集'),
          content: TextField(
            controller: controller,
            maxLength: 30,
            decoration: InputDecoration(
              hintText: 'ひとことを入力...',
              errorText: ngError,
            ),
            onChanged: (text) {
              final validation = NgWordFilter.validate(text);
              setDialogState(() {
                ngError = validation.isValid ? null : validation.error;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: ngError == null
                  ? () async {
                      if (currentUser != null) {
                        await FirestoreService().updateUserProfile(
                          currentUser.copyWith(msg: controller.text),
                        );
                        ref.read(currentUserProvider.notifier).setUser(
                          currentUser.copyWith(msg: controller.text),
                        );
                      }
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('ひとことを更新しました')),
                        );
                      }
                    }
                  : null,
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSecretModeDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('シークレットモード'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('タイムラインと検索結果に表示されなくなります。'),
            const SizedBox(height: 16),
            const Text('解除時間を選択:'),
            const SizedBox(height: 8),
            ListTile(title: const Text('6時間後'), onTap: () => _setSecretMode(6)),
            ListTile(title: const Text('12時間後'), onTap: () => _setSecretMode(12)),
            ListTile(title: const Text('24時間後'), onTap: () => _setSecretMode(24)),
            ListTile(title: const Text('48時間後（最大）'), onTap: () => _setSecretMode(48)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  void _setSecretMode(int hours) {
    setState(() {
      _secretMode = true;
      _secretModeUntil = DateTime.now().add(Duration(hours: hours));
    });
    _authService.setSecretMode(true, hours);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('シークレットモードを${hours}時間に設定しました')),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトすると、トーク履歴は保存されますが、再度ログインが必要です。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              await _authService.signOut();
              ref.read(currentUserProvider.notifier).clearUser();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ログアウトしました')),
                );
              }
            },
            child: const Text('ログアウト', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('アカウント削除'),
        content: const Text(
          'アカウントを削除すると、すべてのデータが完全に削除され、復元できません。\n\n本当に削除しますか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () async {
              await _authService.deleteAccount();
              ref.read(currentUserProvider.notifier).clearUser();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('アカウントを削除しました')),
                );
              }
            },
            child: const Text('削除する', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
