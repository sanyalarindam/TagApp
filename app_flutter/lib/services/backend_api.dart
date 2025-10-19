import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../providers/video_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackendApi {
  BackendApi._(this.baseUrl);
  static final BackendApi instance =
      BackendApi._('https://5k0rjokb6j.execute-api.us-west-2.amazonaws.com');

  final String baseUrl;

  // Authenticated user state (set on login/register/loadToken)
  String? _userId;
  String? _username;
  String? _token;

  String get currentUserId {
    final v = _userId;
    if (v == null || v.isEmpty) {
      throw StateError('Not authenticated: userId is not set');
    }
    return v;
  }

  String get currentUsername {
    final v = _username;
    if (v == null || v.isEmpty) {
      throw StateError('Not authenticated: username is not set');
    }
    return v;
  }

  Future<void> saveToken(String token, String userId, String username) async {
    _token = token;
    _userId = userId;
    _username = username;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('auth_userId', userId);
    await prefs.setString('auth_username', username);
  }

  Future<bool> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _userId = prefs.getString('auth_userId');
    _username = prefs.getString('auth_username');
    return _token != null && _userId != null && _username != null;
  }

  Future<void> clearToken() async {
    _token = null;
    _userId = null;
    _username = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_userId');
    await prefs.remove('auth_username');
    await prefs.remove('auth_password');
  }

  Future<Map<String, String>> getPresignedUrl(
      {String contentType = 'video/mp4'}) async {
    final res = await http.post(Uri.parse('$baseUrl/presign'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'contentType': contentType}));
    if (res.statusCode != 200) {
      throw Exception('presign failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return {
      'uploadUrl': data['uploadUrl'] as String,
      'objectKey': data['objectKey'] as String,
    };
  }

  Future<void> uploadToPresignedUrl(
      {required String uploadUrl,
      required File file,
      String contentType = 'video/mp4'}) async {
    final req = http.Request('PUT', Uri.parse(uploadUrl))
      ..headers['content-type'] = contentType
      ..bodyBytes = await file.readAsBytes();
    final res = await req.send();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('S3 upload failed: ${res.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createPost({
    required String userId,
    required String username,
    required String videoUrl,
    String description = '',
    List<String> hashtags = const [],
    List<String> taggedFriends = const [],
    List<String> taggedUsernames = const [],
    List<String> taggedCommunities = const [],
    String? responseToPostId,
  }) async {
    final res = await http.post(Uri.parse('$baseUrl/posts'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'username': username,
          'videoUrl': videoUrl,
          'description': description,
          'hashtags': hashtags,
          'taggedFriends': taggedFriends,
          'taggedUsernames': taggedUsernames,
          'taggedCommunities': taggedCommunities,
          if (responseToPostId != null) 'responseToPostId': responseToPostId,
        }));
    if (res.statusCode != 201) {
      throw Exception('createPost failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getCommunityFeed(
      String communityId) async {
    final res =
        await http.get(Uri.parse('$baseUrl/communities/$communityId/posts'));
    if (res.statusCode != 200) throw Exception('getCommunityFeed failed');
    final data = jsonDecode(res.body) as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<String>> listCommunities() async {
    final res = await http.get(Uri.parse('$baseUrl/communities'));
    if (res.statusCode != 200) throw Exception('listCommunities failed');
    final data = jsonDecode(res.body) as List;
    return data.map((e) => e.toString()).toList();
  }

  Future<Map<String, dynamic>> verifyVideo({
    required String objectKey,
    required String description,
  }) async {
    final res = await http.post(Uri.parse('$baseUrl/verify'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'video_s3_bucket': 'tagapp-videos',
          'video_s3_key': objectKey,
          'description': description,
        }));
    if (res.statusCode != 200) {
      throw Exception('verify failed: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getAllPosts() async {
    final res = await http.get(Uri.parse('$baseUrl/posts'));
    if (res.statusCode != 200) throw Exception('getAllPosts failed');
    final data = jsonDecode(res.body) as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getUser(String userId) async {
    final res = await http.get(Uri.parse('$baseUrl/users/$userId'));
    if (res.statusCode != 200) throw Exception('getUser failed');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUserRank(String userId) async {
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/rank'));
    if (res.statusCode != 200) throw Exception('getUserRank failed');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> updateUser(String userId,
      {required String username, required String bio}) async {
    final res = await http.put(Uri.parse('$baseUrl/users/$userId'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'username': username, 'bio': bio}));
    if (res.statusCode != 204) throw Exception('updateUser failed');
  }

  Future<List<Map<String, dynamic>>> getInbox(String userId) async {
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/inbox'));
    if (res.statusCode != 200) throw Exception('getInbox failed');
    final data = jsonDecode(res.body) as List;
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getUserPosts(String userId) async {
    final res = await http.get(Uri.parse('$baseUrl/users/$userId/posts'));
    if (res.statusCode != 200) throw Exception('getUserPosts failed');
    final data = jsonDecode(res.body) as List;
    return data.cast<Map<String, dynamic>>();
  }

  // Helpers to map backend post -> VideoItem for UI reuse
  VideoItem videoItemFromPost(Map<String, dynamic> post) {
    return VideoItem(
      id: (post['postId'] ?? '').toString().isEmpty
          ? null
          : post['postId'] as String,
      path: post['videoUrl'] as String,
      description: (post['description'] ?? '') as String,
      hashtag:
          (post['hashtags'] is List && (post['hashtags'] as List).isNotEmpty)
              ? (post['hashtags'] as List).first.toString()
              : '',
      community: ((post['taggedCommunities'] as List?)?.isNotEmpty ?? false)
          ? (post['taggedCommunities'][0] as String)
          : '',
      likes: (post['likes'] ?? 0) as int,
      likedBy: (post['likedBy'] as List?)?.cast<String>() ?? [],
      savedBy: (post['savedBy'] as List?)?.cast<String>() ?? [],
      comments: (post['comments'] as List?)?.cast<Map<String, dynamic>>() ?? [],
    );
  }

  // Interaction APIs
  Future<Map<String, dynamic>> likePost(String postId, String userId) async {
    final res = await http.post(Uri.parse('$baseUrl/posts/$postId/like'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'userId': userId}));
    if (res.statusCode != 200) throw Exception('likePost failed');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unlikePost(String postId, String userId) async {
    final res = await http.delete(Uri.parse('$baseUrl/posts/$postId/like'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'userId': userId}));
    if (res.statusCode != 200) throw Exception('unlikePost failed');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> savePost(String postId, String userId) async {
    final res = await http.post(Uri.parse('$baseUrl/posts/$postId/save'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'userId': userId}));
    if (res.statusCode != 200) throw Exception('savePost failed');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unsavePost(String postId, String userId) async {
    final res = await http.delete(Uri.parse('$baseUrl/posts/$postId/save'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'userId': userId}));
    if (res.statusCode != 200) throw Exception('unsavePost failed');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addComment(
      String postId, String userId, String username, String text) async {
    final res = await http.post(Uri.parse('$baseUrl/posts/$postId/comments'),
        headers: {'content-type': 'application/json'},
        body:
            jsonEncode({'userId': userId, 'username': username, 'text': text}));
    if (res.statusCode != 200) throw Exception('addComment failed');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // Auth APIs
  Future<Map<String, dynamic>> register(
      {required String username, required String password}) async {
    final res = await http.post(Uri.parse('$baseUrl/auth/register'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}));
    if (res.statusCode != 201) {
      throw Exception('register failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await saveToken(data['token'] as String, data['userId'] as String,
        data['username'] as String);
    // Store password for re-login after username change
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_password', password);
    return data;
  }

  Future<Map<String, dynamic>> login(
      {required String username, required String password}) async {
    final res = await http.post(Uri.parse('$baseUrl/auth/login'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}));
    if (res.statusCode != 200) {
      throw Exception('login failed: ${res.statusCode} ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    await saveToken(data['token'] as String, data['userId'] as String,
        data['username'] as String);
    // Store password for re-login after username change
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_password', password);
    return data;
  }
}
