import 'package:flutter/foundation.dart';
import '../services/backend_api.dart';

class VideoItem {
  final String? id; // backend postId if available
  final String path; // local file path for now
  final DateTime createdAt;
  final String description;
  final String hashtag;
  final String community;
  final int likes;
  final List<String> likedBy;
  final List<String> savedBy;
  final List<Map<String, dynamic>> comments;

  VideoItem({
    this.id,
    required this.path,
    this.description = '',
    this.hashtag = '',
    this.community = '',
    DateTime? createdAt,
    this.likes = 0,
    this.likedBy = const [],
    this.savedBy = const [],
    this.comments = const [],
  }) : createdAt = createdAt ?? DateTime.now();
}

class Comment {
  final String id;
  final String author; // simple display name for now
  final String text;
  final DateTime createdAt;

  Comment(
      {required this.id,
      required this.author,
      required this.text,
      DateTime? createdAt})
      : createdAt = createdAt ?? DateTime.now();
}

class VideoProvider extends ChangeNotifier {
  final List<VideoItem> _myUploads = [];
  // Global cache of videos (keyed by id if available, else by path)
  final Map<String, VideoItem> _cacheByKey = {};
  final Set<String> _likedKeys = {}; // liked videos by key
  final Set<String> _savedKeys = {}; // saved videos by key
  // In-flight toggle guards to avoid rapid duplicate requests
  final Set<String> _likeInFlight = {};
  final Set<String> _saveInFlight = {};
  // path -> list of comments
  final Map<String, List<Comment>> _comments = {};

  List<VideoItem> get myUploads => List.unmodifiable(_myUploads);

  List<VideoItem> get likedVideos {
    // Prefer returning items from cache (may include non-upload videos)
    final List<VideoItem> result = [];
    for (final key in _likedKeys) {
      final item = _cacheByKey[key];
      if (item != null) result.add(item);
    }
    return result;
  }

  List<VideoItem> get savedVideos {
    final List<VideoItem> result = [];
    for (final key in _savedKeys) {
      final item = _cacheByKey[key];
      if (item != null) result.add(item);
    }
    return result;
  }

  // Key derivation: prefer id else path
  String _keyFor(VideoItem v) =>
      (v.id != null && v.id!.isNotEmpty) ? v.id! : v.path;

  bool isLikedItem(VideoItem v) => _likedKeys.contains(_keyFor(v));
  bool isSavedItem(VideoItem v) => _savedKeys.contains(_keyFor(v));

  // Return the most up-to-date cached version of a video item
  VideoItem currentFor(VideoItem v) {
    final key = _keyFor(v);
    return _cacheByKey[key] ?? v;
  }

  // Comments API
  List<Comment> commentsFor(String path) =>
      List.unmodifiable(_comments[path] ?? const []);
  int commentCount(String path) => _comments[path]?.length ?? 0;
  void addComment(String path, String author, String text) {
    if (text.trim().isEmpty) return;
    final list = _comments.putIfAbsent(path, () => []);
    list.add(
        Comment(id: UniqueKey().toString(), author: author, text: text.trim()));
    notifyListeners();
  }

  void addLocalVideo(String path,
      {String description = '', String hashtag = '', String community = ''}) {
    // Avoid duplicates by path
    if (_myUploads.any((v) => v.path == path)) return;
    final item = VideoItem(
      path: path,
      description: description,
      hashtag: hashtag,
      community: community,
    );
    _myUploads.insert(0, item);
    // Also put into cache keyed by path so it can be liked/saved
    _cacheByKey[_keyFor(item)] = item;
    notifyListeners();
  }

  void removeByPath(String path) {
    _myUploads.removeWhere((v) => v.path == path);
    // Remove legacy path-based likes/saves
    _likedKeys.remove(path);
    _savedKeys.remove(path);
    _comments.remove(path);
    notifyListeners();
  }

  // New id/path aware toggles with backend sync
  Future<void> toggleLikeFor(VideoItem v) async {
    final key = _keyFor(v);
    if (_likeInFlight.contains(key)) return; // prevent spam
    _likeInFlight.add(key);
    final wasLiked = _likedKeys.contains(key);

    // Optimistic update
    if (wasLiked) {
      _likedKeys.remove(key);
    } else {
      _likedKeys.add(key);
    }
    notifyListeners();

    // Sync to backend if we have a postId
    if (v.id != null && v.id!.isNotEmpty) {
      try {
        final api = BackendApi.instance;
        final userId = api.currentUserId;
        final updated = wasLiked
            ? await api.unlikePost(v.id!, userId)
            : await api.likePost(v.id!, userId);

        // Update cached item with new data
        final newItem = api.videoItemFromPost(updated);
        _cacheByKey[key] = newItem;
        notifyListeners();
      } catch (e) {
        // Revert optimistic update on error
        if (wasLiked) {
          _likedKeys.add(key);
        } else {
          _likedKeys.remove(key);
        }
        notifyListeners();
        print('Failed to sync like: $e');
        rethrow;
      } finally {
        _likeInFlight.remove(key);
      }
    } else {
      // No backend id; clear in-flight guard
      _likeInFlight.remove(key);
    }
  }

  Future<void> toggleSaveFor(VideoItem v) async {
    final key = _keyFor(v);
    if (_saveInFlight.contains(key)) return;
    _saveInFlight.add(key);
    final wasSaved = _savedKeys.contains(key);

    // Optimistic update
    if (wasSaved) {
      _savedKeys.remove(key);
    } else {
      _savedKeys.add(key);
    }
    notifyListeners();

    // Sync to backend if we have a postId
    if (v.id != null && v.id!.isNotEmpty) {
      try {
        final api = BackendApi.instance;
        final userId = api.currentUserId;
        final updated = wasSaved
            ? await api.unsavePost(v.id!, userId)
            : await api.savePost(v.id!, userId);

        final newItem = api.videoItemFromPost(updated);
        _cacheByKey[key] = newItem;
        notifyListeners();
      } catch (e) {
        // Revert on error
        if (wasSaved) {
          _savedKeys.add(key);
        } else {
          _savedKeys.remove(key);
        }
        notifyListeners();
        print('Failed to sync save: $e');
        rethrow;
      } finally {
        _saveInFlight.remove(key);
      }
    } else {
      _saveInFlight.remove(key);
    }
  }

  // Comment with backend sync
  Future<void> addCommentToPost(VideoItem v, String author, String text) async {
    if (text.trim().isEmpty) return;

    // Optimistic local update
    final list = _comments.putIfAbsent(v.path, () => []);
    final tempComment =
        Comment(id: UniqueKey().toString(), author: author, text: text.trim());
    list.add(tempComment);
    notifyListeners();

    // Sync to backend if we have a postId
    if (v.id != null && v.id!.isNotEmpty) {
      try {
        final api = BackendApi.instance;
        final userId = api.currentUserId;
        final username = api.currentUsername;
        final updated =
            await api.addComment(v.id!, userId, username, text.trim());

        // Update cached item with backend comments
        final newItem = api.videoItemFromPost(updated);
        _cacheByKey[_keyFor(v)] = newItem;
        // Clear local optimistic comments now that backend has the source of truth
        _comments[v.path] = [];
        notifyListeners();
      } catch (e) {
        print('Failed to sync comment: $e');
        // Keep local comment even if backend fails
      }
    }
  }

  // Legacy helpers for places still using path directly
  bool isLiked(String path) => _likedKeys.contains(path);
  bool isSaved(String path) => _savedKeys.contains(path);
  void toggleLike(String path) {
    if (_likedKeys.contains(path)) {
      _likedKeys.remove(path);
    } else {
      _likedKeys.add(path);
    }
    notifyListeners();
  }

  void toggleSave(String path) {
    if (_savedKeys.contains(path)) {
      _savedKeys.remove(path);
    } else {
      _savedKeys.add(path);
    }
    notifyListeners();
  }

  void clear() {
    _myUploads.clear();
    _cacheByKey.clear();
    _likedKeys.clear();
    _savedKeys.clear();
    notifyListeners();
  }

  // Load user's posts from backend and populate state
  Future<void> loadFromBackend(String userId) async {
    try {
      final api = BackendApi.instance;
      final posts = await api.getUserPosts(userId);

      // Clear existing state for this user session (uploads and interactions)
      _myUploads.clear();
      _likedKeys.clear();
      _savedKeys.clear();
      _comments.clear();
      for (final post in posts) {
        final item = api.videoItemFromPost(post);
        _myUploads.add(item);
        _cacheByKey[_keyFor(item)] = item;
      }

      notifyListeners();
    } catch (e) {
      print('Failed to load posts from backend: $e');
      // Don't throw - app should work even if backend fetch fails
    }
  }

  // Cache a list of items (e.g., from Explore or Community feeds)
  void cacheItems(List<VideoItem> items) {
    final api = BackendApi.instance;
    final userId = api.currentUserId;

    for (final item in items) {
      final key = _keyFor(item);
      _cacheByKey[key] = item;

      // Hydrate liked/saved state from backend
      if (item.likedBy.contains(userId)) {
        _likedKeys.add(key);
      }
      if (item.savedBy.contains(userId)) {
        _savedKeys.add(key);
      }
    }
    notifyListeners();
  }
}
