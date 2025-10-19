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

class VideoProvider extends ChangeNotifier {
  final List<VideoItem> _myUploads = [];
  final Set<String> _likedPaths = {}; // paths of liked videos
  final Set<String> _savedPaths = {}; // paths of saved videos

  List<VideoItem> get myUploads => List.unmodifiable(_myUploads);

  List<VideoItem> get likedVideos =>
      _myUploads.where((v) => _likedPaths.contains(v.path)).toList();

  List<VideoItem> get savedVideos =>
      _myUploads.where((v) => _savedPaths.contains(v.path)).toList();

  bool isLiked(String path) => _likedPaths.contains(path);
  bool isSaved(String path) => _savedPaths.contains(path);

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
