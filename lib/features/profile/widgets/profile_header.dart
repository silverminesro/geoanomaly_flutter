import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/profile_providers.dart';
import 'tier_badge.dart';

class ProfileHeader extends ConsumerWidget {
  final VoidCallback? onEditPressed;
  final VoidCallback? onAvatarPressed;

  const ProfileHeader({
    super.key,
    this.onEditPressed,
    this.onAvatarPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    final profile = profileState.profile;

    if (profile == null) {
      return const _ProfileHeaderSkeleton();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getTierColor(profile.tier).withOpacity(0.1),
            _getTierColor(profile.tier).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getTierColor(profile.tier).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ✅ Avatar and basic info row
            Row(
              children: [
                // Avatar
                GestureDetector(
                  onTap: onAvatarPressed,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _getTierColor(profile.tier),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _getTierColor(profile.tier).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.grey[100],
                      child: profile.useGravatar
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: profile.gravatarUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _getTierColor(profile.tier),
                                ),
                                errorWidget: (context, url, error) => Text(
                                  profile.avatarEmoji,
                                  style: const TextStyle(fontSize: 32),
                                ),
                              ),
                            )
                          : Text(
                              profile.avatarEmoji,
                              style: const TextStyle(fontSize: 32),
                            ),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Username
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              profile.username,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Tier badge
                          TierBadge(tier: profile.tier),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Level and XP
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Level ${profile.level}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${profile.xp} XP',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // XP Progress Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Level ${profile.level}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'Level ${profile.level + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: profile.levelProgress,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getTierColor(profile.tier),
                              ),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${profile.xpToNextLevel} XP to next level',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Edit button
                if (onEditPressed != null)
                  IconButton(
                    onPressed: onEditPressed,
                    icon: const Icon(Icons.edit),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          _getTierColor(profile.tier).withOpacity(0.1),
                      foregroundColor: _getTierColor(profile.tier),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // ✅ Statistics row
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.inventory,
                    label: 'Items',
                    value: profile.totalItems.toString(),
                    color: _getTierColor(profile.tier),
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.diamond,
                    label: 'Artifacts',
                    value: profile.totalArtifacts.toString(),
                    color: Colors.purple,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.shield,
                    label: 'Gear',
                    value: profile.totalGear.toString(),
                    color: Colors.orange,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    icon: Icons.map,
                    label: 'Zones',
                    value: profile.zonesDiscovered.toString(),
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            // ✅ Account info
            if (profileState.isOffline || profileState.lastUpdated != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    if (profileState.isOffline) ...[
                      Icon(
                        Icons.cloud_off,
                        size: 14,
                        color: Colors.orange[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Offline Mode',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[600],
                        ),
                      ),
                    ] else if (profileState.lastUpdated != null) ...[
                      Icon(
                        Icons.refresh,
                        size: 14,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Updated ${_formatLastUpdated(profileState.lastUpdated!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      'Member for ${profile.accountAgeFormatted}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getTierColor(int tier) {
    switch (tier) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.purple;
      case 4:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatLastUpdated(DateTime lastUpdated) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

// ✅ Stat item widget
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

// ✅ Loading skeleton
class _ProfileHeaderSkeleton extends StatelessWidget {
  const _ProfileHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar skeleton
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                ),

                const SizedBox(width: 16),

                // Info skeleton
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 150,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Stats skeleton
            Row(
              children: List.generate(4, (index) {
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 30,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 40,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
