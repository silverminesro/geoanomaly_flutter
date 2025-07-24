import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_providers.dart';

class StatsCards extends ConsumerWidget {
  const StatsCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileStats = ref.watch(profileStatsProvider);

    if (profileStats == null) {
      return const _StatsCardsSkeleton();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // ✅ Collection Stats Row
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Items',
                value: profileStats['total_items'].toString(),
                icon: Icons.inventory,
                color: Colors.blue,
                subtitle: 'Collected',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Artifacts',
                value: profileStats['total_artifacts'].toString(),
                icon: Icons.diamond,
                color: Colors.purple,
                subtitle: 'Found',
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ✅ Second Row
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Gear Items',
                value: profileStats['total_gear'].toString(),
                icon: Icons.shield,
                color: Colors.orange,
                subtitle: 'Equipped',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Zones',
                value: profileStats['zones_discovered'].toString(),
                icon: Icons.map,
                color: Colors.green,
                subtitle: 'Discovered',
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ✅ FIXED: Progress Card with proper data access
        _ProgressCard(
          profileStats: profileStats,
        ),

        const SizedBox(height: 16),

        // ✅ Account Info Card
        _AccountInfoCard(
          accountAge: profileStats['account_age_formatted'] ?? '1 week',
          activityStatus:
              profileStats['activity']?['activity_status'] ?? 'Active today',
          isActive: profileStats['activity']?['is_active'] ?? true,
          tierInfo: profileStats['tier_info'] ?? {},
        ),
      ],
    );
  }
}

// ✅ Individual stat card
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and title row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Value
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ COMPLETELY REWRITTEN: XP Progress card with smart data extraction
class _ProgressCard extends StatelessWidget {
  final Map<String, dynamic> profileStats;

  const _ProgressCard({
    required this.profileStats,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ SMART DATA EXTRACTION: Try multiple sources
    final currentLevel = _extractLevel();
    final currentXp = _extractXp();
    final xpToNext = _calculateXpToNext(currentLevel, currentXp);
    final progress = _calculateProgress(currentLevel, currentXp);

    // ✅ DEBUG LOGGING
    print('🔍 Progress Card Data:');
    print('📊 Level: $currentLevel, XP: $currentXp');
    print('📊 XP to next: $xpToNext, Progress: ${(progress * 100).toInt()}%');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.indigo.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.indigo.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.indigo,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Level Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Level info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Level',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  Text(
                    '$currentLevel',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'XP to Level ${currentLevel + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  Text(
                    '$xpToNext XP',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level $currentLevel',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    'Level ${currentLevel + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.indigo,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '$currentXp XP',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(progress * 100).toInt()}% complete',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ SMART LEVEL EXTRACTION
  int _extractLevel() {
    // Try multiple sources for level data
    final sources = [
      profileStats['level'],
      profileStats['current_level'],
      profileStats['user_level'],
      profileStats['player_level'],
    ];

    for (final source in sources) {
      if (source != null && source is int && source > 0) {
        return source;
      }
    }

    // Fallback to 1 if nothing found
    return 1;
  }

  // ✅ SMART XP EXTRACTION
  int _extractXp() {
    // Try multiple sources for XP data
    final sources = [
      profileStats['xp'],
      profileStats['current_xp'],
      profileStats['user_xp'],
      profileStats['player_xp'],
    ];

    for (final source in sources) {
      if (source != null && source is int && source >= 0) {
        return source;
      }
    }

    // Fallback to 0 if nothing found
    return 0;
  }

  // ✅ XP CALCULATION (same formula as UserProfile model)
  int _calculateXpToNext(int currentLevel, int currentXp) {
    final nextLevelXp = _calculateXPForLevel(currentLevel + 1);
    return (nextLevelXp - currentXp).clamp(0, nextLevelXp);
  }

  // ✅ PROGRESS CALCULATION
  double _calculateProgress(int currentLevel, int currentXp) {
    final currentLevelXp = _calculateXPForLevel(currentLevel);
    final nextLevelXp = _calculateXPForLevel(currentLevel + 1);
    final progressXp = currentXp - currentLevelXp;
    final levelRange = nextLevelXp - currentLevelXp;

    if (levelRange <= 0) return 1.0;
    return (progressXp / levelRange).clamp(0.0, 1.0);
  }

  // ✅ XP FORMULA (matches backend)
  int _calculateXPForLevel(int targetLevel) {
    if (targetLevel <= 1) return 0;
    return (targetLevel * targetLevel * 100);
  }
}

// ✅ Account info card
class _AccountInfoCard extends StatelessWidget {
  final String accountAge;
  final String activityStatus;
  final bool isActive;
  final Map<String, dynamic> tierInfo;

  const _AccountInfoCard({
    required this.accountAge,
    required this.activityStatus,
    required this.isActive,
    required this.tierInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_circle,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Info rows
          _InfoRow(
            icon: Icons.cake,
            label: 'Member for',
            value: accountAge,
          ),

          const SizedBox(height: 12),

          _InfoRow(
            icon: isActive ? Icons.circle : Icons.circle_outlined,
            iconColor: isActive ? Colors.green : Colors.grey,
            label: 'Status',
            value: activityStatus,
          ),

          const SizedBox(height: 12),

          _InfoRow(
            icon: Icons.star,
            label: 'Subscription',
            value:
                '${tierInfo['tier_emoji'] ?? '🗺️'} ${tierInfo['tier_name'] ?? 'Explorer'}',
            valueColor: _getTierColor(tierInfo['current_tier'] ?? 1),
          ),
        ],
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
}

// ✅ Info row widget
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: iconColor ?? Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: valueColor ?? Colors.grey[800],
          ),
        ),
      ],
    );
  }
}

// ✅ Loading skeleton
class _StatsCardsSkeleton extends StatelessWidget {
  const _StatsCardsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title skeleton
        Container(
          width: 150,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        ),

        const SizedBox(height: 16),

        // Stats cards skeleton
        Row(
          children: [
            Expanded(child: _StatCardSkeleton()),
            const SizedBox(width: 12),
            Expanded(child: _StatCardSkeleton()),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(child: _StatCardSkeleton()),
            const SizedBox(width: 12),
            Expanded(child: _StatCardSkeleton()),
          ],
        ),

        const SizedBox(height: 16),

        // Progress card skeleton
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
        ),

        const SizedBox(height: 16),

        // Account info skeleton
        Container(
          width: double.infinity,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
