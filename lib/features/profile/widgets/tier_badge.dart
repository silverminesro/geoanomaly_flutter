import 'package:flutter/material.dart';

class TierBadge extends StatelessWidget {
  final int tier;
  final double? fontSize;
  final bool showLabel;
  final bool compact;

  const TierBadge({
    super.key,
    required this.tier,
    this.fontSize,
    this.showLabel = false,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    final tierInfo = _getTierInfo(tier);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: tierInfo.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tierInfo.color.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tierInfo.emoji,
              style: TextStyle(
                fontSize: fontSize ?? 12,
              ),
            ),
            if (showLabel) ...[
              const SizedBox(width: 4),
              Text(
                tierInfo.shortName,
                style: TextStyle(
                  fontSize: (fontSize ?? 12) - 2,
                  fontWeight: FontWeight.w600,
                  color: tierInfo.color,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Full tier badge
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tierInfo.color.withOpacity(0.8),
            tierInfo.color,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: tierInfo.color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tierInfo.emoji,
            style: TextStyle(
              fontSize: fontSize ?? 16,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tierInfo.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Tier $tier',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _TierInfo _getTierInfo(int tier) {
    switch (tier) {
      case 0:
        return _TierInfo(
          name: 'Free Player',
          shortName: 'Free',
          emoji: '🆓',
          color: Colors.grey,
        );
      case 1:
        return _TierInfo(
          name: 'Explorer',
          shortName: 'Explorer',
          emoji: '🗺️',
          color: Colors.green,
        );
      case 2:
        return _TierInfo(
          name: 'Adventurer',
          shortName: 'Adventurer',
          emoji: '⚔️',
          color: Colors.blue,
        );
      case 3:
        return _TierInfo(
          name: 'Master Explorer',
          shortName: 'Master',
          emoji: '🏆',
          color: Colors.purple,
        );
      case 4:
        return _TierInfo(
          name: 'Legendary Hunter',
          shortName: 'Legendary',
          emoji: '👑',
          color: Colors.orange,
        );
      default:
        return _TierInfo(
          name: 'Unknown Tier',
          shortName: 'Unknown',
          emoji: '❓',
          color: Colors.grey,
        );
    }
  }
}

class _TierInfo {
  final String name;
  final String shortName;
  final String emoji;
  final Color color;

  _TierInfo({
    required this.name,
    required this.shortName,
    required this.emoji,
    required this.color,
  });
}

// ✅ Tier benefits widget
class TierBenefits extends StatelessWidget {
  final int tier;

  const TierBenefits({
    super.key,
    required this.tier,
  });

  @override
  Widget build(BuildContext context) {
    final benefits = _getTierBenefits(tier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TierBadge(tier: tier, showLabel: true, compact: false),
                const Spacer(),
                if (tier < 4)
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to upgrade screen
                    },
                    child: const Text('Upgrade'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Benefits:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...benefits.map((benefit) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(benefit)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  List<String> _getTierBenefits(int tier) {
    switch (tier) {
      case 0:
        return [
          'Access to basic zones',
          '3 zones per scan',
          '60 second collect cooldown',
          '50 inventory slots',
        ];
      case 1:
        return [
          'Access to explorer zones',
          '5 zones per scan',
          '45 second collect cooldown',
          '100 inventory slots',
          'Exclusive explorer items',
        ];
      case 2:
        return [
          'Access to adventurer zones',
          '7 zones per scan',
          '30 second collect cooldown',
          '200 inventory slots',
          'Exclusive adventurer items',
          'Priority support',
        ];
      case 3:
        return [
          'Access to master zones',
          '10 zones per scan',
          '15 second collect cooldown',
          '500 inventory slots',
          'Exclusive master items',
          'Beta features access',
          'Custom profile themes',
        ];
      case 4:
        return [
          'Access to legendary zones',
          'Unlimited zones per scan',
          'No collect cooldown',
          'Unlimited inventory',
          'Exclusive legendary items',
          'Early access to new features',
          'Custom avatars',
          'Developer insights',
        ];
      default:
        return ['Unknown tier benefits'];
    }
  }
}
