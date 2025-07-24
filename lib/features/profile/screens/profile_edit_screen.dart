import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_providers.dart';
import '../models/user_profile_model.dart';
import '../widgets/emoji_avatar_picker.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _hasChanges = false;
  String? _selectedEmoji;
  bool? _useGravatar;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    final profile = ref.read(currentUserProvider);
    if (profile != null) {
      _usernameController.text = profile.username;
      _emailController.text = profile.email;
      _selectedEmoji = profile.avatarEmoji;
      _useGravatar = profile.useGravatar;
    }

    // Listen for changes
    _usernameController.addListener(_onFormChanged);
    _emailController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    final profile = ref.read(currentUserProvider);
    if (profile == null) return;

    final hasUsernameChanged = _usernameController.text != profile.username;
    final hasEmailChanged = _emailController.text != profile.email;
    final hasAvatarChanged = _selectedEmoji != profile.avatarEmoji;
    final hasGravatarChanged = _useGravatar != profile.useGravatar;

    final newHasChanges = hasUsernameChanged ||
        hasEmailChanged ||
        hasAvatarChanged ||
        hasGravatarChanged;

    if (newHasChanges != _hasChanges) {
      setState(() {
        _hasChanges = newHasChanges;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(
          child: Text('Profile not loaded'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        actions: [
          if (_hasChanges && !_isLoading)
            TextButton(
              onPressed: _saveChanges,
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Avatar section
              _AvatarSection(
                currentAvatar: _selectedEmoji ?? profile.avatarEmoji,
                useGravatar: _useGravatar ?? profile.useGravatar,
                gravatarUrl: profile.gravatarUrl,
                onEmojiChanged: (emoji) {
                  setState(() {
                    _selectedEmoji = emoji;
                    _useGravatar = false;
                  });
                  _onFormChanged();
                },
                onGravatarToggled: (useGravatar) {
                  setState(() {
                    _useGravatar = useGravatar;
                  });
                  _onFormChanged();
                },
              ),

              const SizedBox(height: 32),

              // ✅ Basic info section
              _SectionHeader(
                title: 'Basic Information',
                icon: Icons.person,
              ),

              const SizedBox(height: 16),

              // Username field
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter your username',
                  prefixIcon: const Icon(Icons.account_circle),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  counterText: '${_usernameController.text.length}/50',
                ),
                maxLength: 50,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username is required';
                  }
                  if (value.length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
                    return 'Username can only contain letters, numbers, _ and -';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Email field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email address',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                      .hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // ✅ Account info section (read-only)
              _SectionHeader(
                title: 'Account Information',
                icon: Icons.info_outline,
              ),

              const SizedBox(height: 16),

              _ReadOnlyInfoCard(profile: profile),

              const SizedBox(height: 32),

              // ✅ Danger zone
              _DangerZone(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _hasChanges
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _discardChanges,
                      child: const Text('Discard'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final profile = ref.read(currentUserProvider)!;
      final notifier = ref.read(profileProvider.notifier);

      // Handle avatar changes first (separate API call)
      if (_selectedEmoji != profile.avatarEmoji ||
          _useGravatar != profile.useGravatar) {
        if (_useGravatar == true) {
          await notifier.toggleGravatar(true);
        } else if (_selectedEmoji != profile.avatarEmoji) {
          await notifier.updateAvatarEmoji(_selectedEmoji!);
        }
      }

      // Handle username/email changes
      bool profileUpdateNeeded = false;
      String? newUsername;
      String? newEmail;

      if (_usernameController.text != profile.username) {
        newUsername = _usernameController.text;
        profileUpdateNeeded = true;
      }

      if (_emailController.text != profile.email) {
        newEmail = _emailController.text;
        profileUpdateNeeded = true;
      }

      if (profileUpdateNeeded) {
        final request = UpdateProfileRequest(
          username: newUsername,
          email: newEmail,
        );

        final success = await notifier.updateProfile(request);

        if (!success) {
          throw Exception('Failed to update profile');
        }
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Go back after successful save
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Profile update error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _saveChanges,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _discardChanges() {
    final profile = ref.read(currentUserProvider);
    if (profile != null) {
      setState(() {
        _usernameController.text = profile.username;
        _emailController.text = profile.email;
        _selectedEmoji = profile.avatarEmoji;
        _useGravatar = profile.useGravatar;
        _hasChanges = false;
      });
    }
  }
}

// ✅ Avatar section widget
class _AvatarSection extends StatelessWidget {
  final String currentAvatar;
  final bool useGravatar;
  final String gravatarUrl;
  final Function(String) onEmojiChanged;
  final Function(bool) onGravatarToggled;

  const _AvatarSection({
    required this.currentAvatar,
    required this.useGravatar,
    required this.gravatarUrl,
    required this.onEmojiChanged,
    required this.onGravatarToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeader(
          title: 'Avatar',
          icon: Icons.face,
        ),

        const SizedBox(height: 16),

        // Current avatar display
        Center(
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.blue,
                width: 3,
              ),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[100],
              child: useGravatar
                  ? ClipOval(
                      child: Image.network(
                        gravatarUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Text(
                          currentAvatar,
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                    )
                  : Text(
                      currentAvatar,
                      style: const TextStyle(fontSize: 40),
                    ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Avatar options
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showEmojiPicker(context),
                icon: const Icon(Icons.emoji_emotions),
                label: const Text('Choose Emoji'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: useGravatar ? null : Colors.blue,
                  foregroundColor: useGravatar ? null : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => onGravatarToggled(!useGravatar),
                icon: const Icon(Icons.account_circle),
                label: const Text('Use Gravatar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: useGravatar ? Colors.blue : null,
                  foregroundColor: useGravatar ? Colors.white : null,
                ),
              ),
            ),
          ],
        ),

        if (useGravatar) ...[
          const SizedBox(height: 8),
          Text(
            'Gravatar is linked to your email address',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  void _showEmojiPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EmojiAvatarPicker(
        currentEmoji: currentAvatar,
        onEmojiSelected: (emoji) {
          onEmojiChanged(emoji);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

// ✅ Section header widget
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.blue[600],
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
        ),
      ],
    );
  }
}

// ✅ Read-only info card
class _ReadOnlyInfoCard extends StatelessWidget {
  final UserProfile profile;

  const _ReadOnlyInfoCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _InfoRow(
            label: 'User ID',
            value: profile.id.substring(0, 8) + '...',
            icon: Icons.fingerprint,
          ),
          const Divider(),
          _InfoRow(
            label: 'Level',
            value: '${profile.level} (${profile.xp} XP)',
            icon: Icons.trending_up,
          ),
          const Divider(),
          _InfoRow(
            label: 'Tier',
            value: '${profile.tierEmoji} ${profile.tierDisplayName}',
            icon: Icons.star,
          ),
          const Divider(),
          _InfoRow(
            label: 'Member Since',
            value: profile.accountAgeFormatted,
            icon: Icons.cake,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// ✅ Danger zone
class _DangerZone extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Danger Zone',
          icon: Icons.warning,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.security, color: Colors.red[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Change Password',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Update your account password for security.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[600],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Navigate to change password screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Change password coming soon!')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[600],
                    side: BorderSide(color: Colors.red[300]!),
                  ),
                  child: const Text('Change Password'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
