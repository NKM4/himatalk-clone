import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';

// Current user state
class CurrentUserNotifier extends Notifier<User?> {
  @override
  User? build() => null;

  void setUser(User user) {
    state = user;
  }

  void clearUser() {
    state = null;
  }

  void updateProfile({
    String? name,
    int? age,
    int? sex,
    int? place,
    String? msg,
    String? img,
  }) {
    if (state == null) return;
    state = state!.copyWith(
      name: name,
      age: age,
      sex: sex,
      place: place,
      msg: msg,
      img: img,
    );
  }

  void toggleSecretMode(bool enabled, {int hours = 24}) {
    if (state == null) return;
    state = state!.copyWith(
      isSecret: enabled,
      secretUntil: enabled
          ? DateTime.now().add(Duration(hours: hours.clamp(1, 48)))
          : null,
    );
  }

  void blockUser(String userId) {
    if (state == null) return;
    if (!state!.blockedUserIds.contains(userId)) {
      state = state!.copyWith(
        blockedUserIds: [...state!.blockedUserIds, userId],
      );
    }
  }

  void unblockUser(String userId) {
    if (state == null) return;
    state = state!.copyWith(
      blockedUserIds: state!.blockedUserIds.where((id) => id != userId).toList(),
    );
  }
}

final currentUserProvider = NotifierProvider<CurrentUserNotifier, User?>(() {
  return CurrentUserNotifier();
});

// Auth state
enum AuthState { initial, authenticated, unauthenticated, loading }

class AuthStateNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => AuthState.initial;

  void setAuthenticated() => state = AuthState.authenticated;
  void setUnauthenticated() => state = AuthState.unauthenticated;
  void setLoading() => state = AuthState.loading;
}

final authStateProvider = NotifierProvider<AuthStateNotifier, AuthState>(() {
  return AuthStateNotifier();
});

// Is logged in
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
