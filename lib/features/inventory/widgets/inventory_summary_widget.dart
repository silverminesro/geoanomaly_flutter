import 'package:flutter/material.dart';
import '../models/inventory_summary_model.dart';

class InventorySummaryWidget extends StatelessWidget {
  final InventorySummary summary;

  const InventorySummaryWidget({
    Key? key,
    required this.summary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Total stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  '📦 Total',
                  summary.totalItems.toString(),
                  Colors.blue,
                ),
                _buildStatCard(
                  '💎 Artifacts',
                  summary.totalArtifacts.toString(),
                  Colors.purple,
                ),
                _buildStatCard(
                  '⚔️ Gear',
                  summary.totalGear.toString(),
                  Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Rarity breakdown
            if (summary.byRarity.isNotEmpty) ...[
              Text(
                'By Rarity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRarityChip('Common', summary.commonCount, Colors.grey),
                  _buildRarityChip('Rare', summary.rareCount, Colors.blue),
                  _buildRarityChip('Epic', summary.epicCount, Colors.purple),
                  _buildRarityChip(
                      'Legendary', summary.legendaryCount, Colors.orange),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRarityChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
