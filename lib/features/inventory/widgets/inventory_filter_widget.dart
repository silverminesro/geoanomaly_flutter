import 'package:flutter/material.dart';

class InventoryFilterWidget extends StatelessWidget {
  final String? currentFilter;
  final ValueChanged<String?> onFilterChanged;

  const InventoryFilterWidget({
    Key? key,
    this.currentFilter,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Filter: '),
          const SizedBox(width: 8),

          // All items
          _buildFilterChip(
            label: 'All',
            isSelected: currentFilter == null,
            onTap: () => onFilterChanged(null),
          ),

          const SizedBox(width: 8),

          // Artifacts only
          _buildFilterChip(
            label: '💎 Artifacts',
            isSelected: currentFilter == 'artifact',
            onTap: () => onFilterChanged('artifact'),
          ),

          const SizedBox(width: 8),

          // Gear only
          _buildFilterChip(
            label: '⚔️ Gear',
            isSelected: currentFilter == 'gear',
            onTap: () => onFilterChanged('gear'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
