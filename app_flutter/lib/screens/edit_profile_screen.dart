import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  final String username;
  final String bio;
  final String avatarUrl;

  const EditProfileScreen({
    Key? key,
    required this.username,
    required this.bio,
    required this.avatarUrl,
  }) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _usernameCtrl;
  late TextEditingController _bioCtrl;
  late String _avatarUrl;
  final _formKey = GlobalKey<FormState>();
  String? _usernameError;
  String? _bioError;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.username);
    _bioCtrl = TextEditingController(text: widget.bio);
    _avatarUrl = widget.avatarUrl;
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _changeAvatar() async {
    // TODO: integrate image picker. For now, toggle a sample image URL.
    setState(() {
      _avatarUrl = _avatarUrl.contains('73398c7f28ca')
          ? 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=facearea&w=256&h=256'
          : 'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=facearea&w=256&h=256';
    });
  }

  bool _validate() {
    String? uErr;
    String? bErr;
    final raw = _usernameCtrl.text.trim();
    final username = raw.startsWith('@') ? raw.substring(1) : raw;
    final usernameRegex = RegExp(r'^[A-Za-z0-9_]{3,20}$');
    if (username.isEmpty) {
      uErr = 'Username is required';
    } else if (!usernameRegex.hasMatch(username)) {
      uErr = '3–20 letters, numbers, or _ only';
    }
    final bio = _bioCtrl.text;
    if (bio.length > 160) {
      bErr = 'Bio must be 160 characters or less';
    }
    setState(() {
      _usernameError = uErr;
      _bioError = bErr;
    });
    return uErr == null && bErr == null;
  }

  void _save() {
    if (!_validate()) return;
    final raw = _usernameCtrl.text.trim();
    final sanitized = raw.startsWith('@') ? raw.substring(1) : raw;
    Navigator.pop(context, {
      'username': sanitized,
      'bio': _bioCtrl.text,
      'avatarUrl': _avatarUrl,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: NetworkImage(_avatarUrl),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _changeAvatar,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.edit, color: Colors.blue, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameCtrl,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixText: '@',
                helperText: '3–20 letters, numbers, or _',
                errorText: _usernameError,
              ),
              onChanged: (_) {
                if (_usernameError != null) _validate();
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Bio',
                helperText: 'Up to 160 characters',
                errorText: _bioError,
              ),
              onChanged: (_) {
                if (_bioError != null) _validate();
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
