import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';
import '../services/firestore_service.dart';

/// ルーム一覧管理（Room使用）
class RoomsNotifier extends Notifier<List<Room>> {
  @override
  List<Room> build() => [];

  void setRooms(List<Room> rooms) {
    state = rooms;
  }

  void addRoom(Room room) {
    final existingIndex = state.indexWhere((r) => r.roomKey == room.roomKey);
    if (existingIndex >= 0) {
      // 既存ルームを更新して先頭に移動
      state = [
        room,
        ...state.sublist(0, existingIndex),
        ...state.sublist(existingIndex + 1),
      ];
    } else {
      state = [room, ...state];
    }
  }

  void removeRoom(String roomKey) {
    state = state.where((r) => r.roomKey != roomKey).toList();
  }

  void markAsRead(String roomKey) {
    state = state.map((room) {
      if (room.roomKey == roomKey) {
        return room.copyWith(readed: true);
      }
      return room;
    }).toList();
  }

  void updateLastMessage(String roomKey, String message) {
    state = state.map((room) {
      if (room.roomKey == roomKey) {
        return room.copyWith(
          lastMessage: message,
          updatedAt: DateTime.now(),
        );
      }
      return room;
    }).toList();
    // 更新されたルームを先頭に移動
    final roomIndex = state.indexWhere((r) => r.roomKey == roomKey);
    if (roomIndex > 0) {
      final room = state[roomIndex];
      state = [
        room,
        ...state.sublist(0, roomIndex),
        ...state.sublist(roomIndex + 1),
      ];
    }
  }
}

final roomsProvider = NotifierProvider<RoomsNotifier, List<Room>>(() {
  return RoomsNotifier();
});

/// メッセージ一覧管理
class MessagesMapNotifier extends Notifier<Map<String, List<Message>>> {
  @override
  Map<String, List<Message>> build() => {};

  void setMessages(String roomKey, List<Message> messages) {
    state = {...state, roomKey: messages};
  }

  void addMessage(String roomKey, Message message) {
    final current = state[roomKey] ?? [];
    state = {...state, roomKey: [...current, message]};
  }

  List<Message> getMessages(String roomKey) {
    return state[roomKey] ?? [];
  }

  void clearMessages(String roomKey) {
    final newState = Map<String, List<Message>>.from(state);
    newState.remove(roomKey);
    state = newState;
  }
}

final messagesMapProvider = NotifierProvider<MessagesMapNotifier, Map<String, List<Message>>>(() {
  return MessagesMapNotifier();
});

/// 特定ルームのメッセージを取得
final messagesProvider = Provider.family<List<Message>, String>((ref, roomKey) {
  final messagesMap = ref.watch(messagesMapProvider);
  return messagesMap[roomKey] ?? [];
});

/// 未読メッセージ総数
final totalUnreadCountProvider = Provider<int>((ref) {
  final rooms = ref.watch(roomsProvider);
  return rooms.where((room) => !room.readed).length;
});

/// FirestoreServiceのプロバイダー
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// 現在選択中のルームキー
final currentRoomKeyProvider = StateProvider<String?>((ref) => null);
