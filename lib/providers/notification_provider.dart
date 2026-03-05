import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';

class NotificationsNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() => _generateDummyNotifications();

  static List<AppNotification> _generateDummyNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: 'notif_1',
        type: NotificationType.yoro,
        title: 'User1 said Hi!',
        fromUserId: 'user_1',
        fromUserName: 'User1',
        relatedId: 'post_1',
        createdAt: now.subtract(const Duration(minutes: 5)),
      ),
      AppNotification(
        id: 'notif_2',
        type: NotificationType.message,
        title: 'New message from User2',
        fromUserId: 'user_2',
        fromUserName: 'User2',
        relatedId: 'chat_2',
        createdAt: now.subtract(const Duration(minutes: 10)),
      ),
      AppNotification(
        id: 'notif_3',
        type: NotificationType.like,
        title: 'User3 liked your post',
        fromUserId: 'user_3',
        fromUserName: 'User3',
        relatedId: 'post_5',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      AppNotification(
        id: 'notif_4',
        type: NotificationType.follow,
        title: 'User4 started following you',
        fromUserId: 'user_4',
        fromUserName: 'User4',
        createdAt: now.subtract(const Duration(hours: 2)),
      ),
    ];
  }

  void addNotification(AppNotification notification) {
    state = [notification, ...state];
  }

  void markAsRead(String notificationId) {
    state = state.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
  }

  void markAllAsRead() {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
  }

  void removeNotification(String notificationId) {
    state = state.where((n) => n.id != notificationId).toList();
  }

  void clearAll() {
    state = [];
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, List<AppNotification>>(() {
  return NotificationsNotifier();
});

// Unread notification count
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.where((n) => !n.isRead).length;
});
