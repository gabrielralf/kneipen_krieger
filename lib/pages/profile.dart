import 'package:flutter/material.dart';
import 'dart:math';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/my_button.dart';

class _UserProfileData {
  const _UserProfileData({required this.username, this.avatarUrl});

  final String username;
  final String? avatarUrl;
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.refreshSignal});

  final int refreshSignal;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<int> _suggestionsCountFuture;
  late Future<_UserProfileData?> _profileFuture;

  final _picker = ImagePicker();
  bool _isUpdatingProfile = false;

  @override
  void initState() {
    super.initState();
    _suggestionsCountFuture = _fetchSuggestionsCount();
    _profileFuture = _fetchOrCreateProfile();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _suggestionsCountFuture = _fetchSuggestionsCount();
      _profileFuture = _fetchOrCreateProfile();
    }
  }

  String _randomUsername() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    final suffix = List.generate(
      8,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
    return 'user_$suffix';
  }

  bool _isUniqueViolation(Object error) {
    if (error is PostgrestException) {
      return error.code == '23505';
    }
    return error.toString().contains('23505') ||
        error.toString().toLowerCase().contains('duplicate key');
  }

  bool _isValidUsername(String username) {
    // Keep it simple & DB-friendly.
    final re = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    return re.hasMatch(username);
  }

  Future<_UserProfileData?> _fetchOrCreateProfile() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;

    final rows = await client
        .from('profiles')
        .select('username, avatar_url')
        .eq('user_id', user.id);

    final list = rows as List;
    if (list.isEmpty) {
      for (int attempt = 0; attempt < 5; attempt++) {
        final username = _randomUsername();
        try {
          await client.from('profiles').insert({
            'user_id': user.id,
            'username': username,
          });
          return _UserProfileData(username: username);
        } catch (e) {
          if (_isUniqueViolation(e)) continue;
          rethrow;
        }
      }

      throw Exception('Could not allocate a unique username. Please try again.');
    }

    final map = list.first as Map;
    final username = (map['username'] as String?)?.trim();
    final avatarUrl = (map['avatar_url'] as String?)?.trim();

    if (username == null || username.isEmpty) {
      for (int attempt = 0; attempt < 5; attempt++) {
        final generated = _randomUsername();
        try {
          await client
              .from('profiles')
              .update({'username': generated})
              .eq('user_id', user.id);
          return _UserProfileData(username: generated, avatarUrl: avatarUrl);
        } catch (e) {
          if (_isUniqueViolation(e)) continue;
          rethrow;
        }
      }

      throw Exception('Could not allocate a unique username. Please try again.');
    }

    return _UserProfileData(username: username, avatarUrl: avatarUrl);
  }

  Future<void> _editUsername(String current) async {
    final controller = TextEditingController(text: current);
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Username'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter username'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newValue == null) return;
    final username = newValue.trim();
    if (username.isEmpty) return;

    if (!_isValidUsername(username)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username must be 3–20 chars: letters, numbers, _.')),
      );
      return;
    }

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    setState(() => _isUpdatingProfile = true);
    try {
      await client
          .from('profiles')
          .update({'username': username})
          .eq('user_id', user.id);
      setState(() => _profileFuture = _fetchOrCreateProfile());
    } catch (e) {
      if (!mounted) return;
      if (_isUniqueViolation(e)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username already taken.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Username update failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingProfile = false);
    }
  }

  Future<void> _showAvatarPicker() async {
    if (_isUpdatingProfile) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take selfie'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final file = await _picker.pickImage(
                    source: ImageSource.camera,
                    preferredCameraDevice: CameraDevice.front,
                    imageQuality: 85,
                  );
                  if (file == null) return;
                  await _uploadAvatar(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final file = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (file == null) return;
                  await _uploadAvatar(file);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadAvatar(XFile file) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    setState(() => _isUpdatingProfile = true);
    try {
      final bytes = await file.readAsBytes();
      final name = file.name;
      final ext = (name.contains('.') ? name.split('.').last : 'jpg')
          .toLowerCase();
      final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
      final path = '${user.id}/avatar.$ext';

      final bucket = client.storage.from('avatars');
      await bucket.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: contentType, upsert: true),
      );

      final publicUrl = bucket.getPublicUrl(path);
      await client
          .from('profiles')
          .update({'avatar_path': path, 'avatar_url': publicUrl})
          .eq('user_id', user.id);

      setState(() => _profileFuture = _fetchOrCreateProfile());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Avatar upload failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingProfile = false);
    }
  }

  Future<int> _fetchSuggestionsCount() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return 0;

    final rows = await client
        .from('price_suggestions')
        .select('id')
        .eq('user_id', user.id);

    return (rows as List).length;
  }

  ({
    int level,
    int progressSuggestions,
    int neededSuggestions,
    int progressPoints,
    int neededPoints,
    int totalPoints,
    double fraction,
  })
  _computeLevel(int totalSuggestions) {
    // Each suggestion gives +5 points.
    // Total suggestions required to reach level L is triangular(L) = L*(L+1)/2.
    // Examples: L2 => 3 suggestions => 15 points; L3 => 6 suggestions => 30 points.
    int level = 0;
    while ((level + 1) * (level + 2) ~/ 2 <= totalSuggestions) {
      level++;
    }

    final int suggestionsBeforeThisLevel = level * (level + 1) ~/ 2;
    final int progressSuggestions =
        totalSuggestions - suggestionsBeforeThisLevel;
    final int neededSuggestions = level + 1;

    final int progressPoints = progressSuggestions * 5;
    final int neededPoints = neededSuggestions * 5;
    final int totalPoints = totalSuggestions * 5;

    final double fraction = neededSuggestions == 0
        ? 0
        : (progressSuggestions / neededSuggestions).clamp(0.0, 1.0);

    return (
      level: level,
      progressSuggestions: progressSuggestions,
      neededSuggestions: neededSuggestions,
      progressPoints: progressPoints,
      neededPoints: neededPoints,
      totalPoints: totalPoints,
      fraction: fraction,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profile',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              FutureBuilder<_UserProfileData?>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  final username = profile?.username ?? 'guest';
                  final avatarUrl = profile?.avatarUrl;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: profile == null ? null : _showAvatarPicker,
                          child: CircleAvatar(
                            radius: 46,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: avatarUrl == null
                                ? null
                                : NetworkImage(avatarUrl),
                            child: avatarUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 46,
                                    color: Colors.grey.shade700,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: GestureDetector(
                          onTap: profile == null || _isUpdatingProfile
                              ? null
                              : () => _editUsername(username),
                          child: Text(
                            username,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<int>(
                future: _suggestionsCountFuture,
                builder: (context, snapshot) {
                  final total = snapshot.data ?? 0;
                  final stats = _computeLevel(total);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Level ${stats.level}'),
                          Text('Level ${stats.level + 1}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: stats.fraction,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.amber,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${stats.progressPoints}/${stats.neededPoints} points',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              MyButton(
                text: 'Logout',
                onTap: _isUpdatingProfile
                    ? null
                    : () async {
                        try {
                          await Supabase.instance.client.auth.signOut();
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Logout failed: ${e.toString()}'),
                            ),
                          );
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
