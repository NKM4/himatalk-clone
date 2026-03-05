import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post.dart';

// Posts state
class PostsNotifier extends Notifier<List<Post>> {
  @override
  List<Post> build() => _generateDummyPosts();

  static List<Post> _generateDummyPosts() {
    final now = DateTime.now();
    return List.generate(20, (index) {
      final genders = ['Male', 'Female'];
      final areas = ['Tokyo', 'Osaka', 'Kyoto', 'Fukuoka', 'Hokkaido', 'Nagoya'];
      final messages = [
        'Anyone free to chat?',
        'Looking for friends!',
        'Bored at work...',
        'Just woke up',
        "Can't sleep",
        'Hello everyone!',
        'Any gamers here?',
        'Movie recommendations?',
        "What's everyone up to?",
        'Weekend plans?',
      ];

      return Post(
        id: 'post_$index',
        userId: 'user_$index',
        userName: 'User${index + 1}',
        userAge: 20 + (index % 30),
        userGender: genders[index % 2],
        userArea: areas[index % areas.length],
        content: messages[index % messages.length],
        createdAt: now.subtract(Duration(minutes: index * 3)),
        yoroCount: index % 5,
      );
    });
  }

  void addPost(Post post) {
    state = [post, ...state];
  }

  void removePost(String postId) {
    state = state.where((p) => p.id != postId).toList();
  }

  void sendYoro(String postId, String userId) {
    state = state.map((post) {
      if (post.id == postId && !post.yoroUserIds.contains(userId)) {
        return post.copyWith(
          yoroCount: post.yoroCount + 1,
          yoroUserIds: [...post.yoroUserIds, userId],
        );
      }
      return post;
    }).toList();
  }

  void refresh() {
    state = _generateDummyPosts();
  }
}

final postsProvider = NotifierProvider<PostsNotifier, List<Post>>(() {
  return PostsNotifier();
});

// Search filter state
class SearchFilter {
  final String? gender;
  final int minAge;
  final int maxAge;
  final String? area;

  SearchFilter({
    this.gender,
    this.minAge = 18,
    this.maxAge = 80,
    this.area,
  });

  SearchFilter copyWith({
    String? gender,
    int? minAge,
    int? maxAge,
    String? area,
  }) {
    return SearchFilter(
      gender: gender ?? this.gender,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      area: area ?? this.area,
    );
  }
}

class SearchFilterNotifier extends Notifier<SearchFilter> {
  @override
  SearchFilter build() => SearchFilter();

  void setGender(String? gender) {
    state = state.copyWith(gender: gender);
  }

  void setAgeRange(int min, int max) {
    state = state.copyWith(minAge: min, maxAge: max);
  }

  void setArea(String? area) {
    state = state.copyWith(area: area);
  }

  void reset() {
    state = SearchFilter();
  }
}

final searchFilterProvider = NotifierProvider<SearchFilterNotifier, SearchFilter>(() {
  return SearchFilterNotifier();
});

// Filtered posts
final filteredPostsProvider = Provider<List<Post>>((ref) {
  final posts = ref.watch(postsProvider);
  final filter = ref.watch(searchFilterProvider);

  return posts.where((post) {
    if (filter.gender != null && filter.gender != 'All' && post.userGender != filter.gender) {
      return false;
    }
    if (post.userAge < filter.minAge || post.userAge > filter.maxAge) {
      return false;
    }
    if (filter.area != null && filter.area != 'All' && post.userArea != filter.area) {
      return false;
    }
    return true;
  }).toList();
});
