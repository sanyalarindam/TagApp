import 'package:flutter/foundation.dart';

class VideoItem {
  final String path; // local file path for now
  final DateTime createdAt;
  final String description;
  final String hashtag;
  final String community;

  VideoItem({
    required this.path,
    this.description = '',
    this.hashtag = '',
    this.community = '',
    DateTime? createdAt,
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
  final Set<String> _likedPaths = {}; // paths of liked videos
  final Set<String> _savedPaths = {}; // paths of saved videos
  // path -> list of comments
  final Map<String, List<Comment>> _comments = {};

  List<VideoItem> get myUploads => List.unmodifiable(_myUploads);

  List<VideoItem> get likedVideos =>
      _myUploads.where((v) => _likedPaths.contains(v.path)).toList();

  List<VideoItem> get savedVideos =>
      _myUploads.where((v) => _savedPaths.contains(v.path)).toList();

  bool isLiked(String path) => _likedPaths.contains(path);
  bool isSaved(String path) => _savedPaths.contains(path);

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
    _myUploads.insert(
        0,
        VideoItem(
          path: path,
          description: description,
          hashtag: hashtag,
          community: community,
        ));
    notifyListeners();
  }

  void removeByPath(String path) {
    _myUploads.removeWhere((v) => v.path == path);
    _likedPaths.remove(path);
    _savedPaths.remove(path);
    _comments.remove(path);
    notifyListeners();
  }

  void toggleLike(String path) {
    if (_likedPaths.contains(path)) {
      _likedPaths.remove(path);
    } else {
      _likedPaths.add(path);
    }
    notifyListeners();
  }

  void toggleSave(String path) {
    if (_savedPaths.contains(path)) {
      _savedPaths.remove(path);
    } else {
      _savedPaths.add(path);
    }
    notifyListeners();
  }

  void clear() {
    _myUploads.clear();
    _likedPaths.clear();
    _savedPaths.clear();
    notifyListeners();
  }
}
