import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventory_provider.dart';
import '../widgets/inventory_item_card.dart';
import '../models/inventory_item_model.dart';
import '../widgets/inventory_summary_widget.dart';
import '../widgets/inventory_filter_widget.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  String? _currentFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryProvider.notifier).loadInventory();
      ref.read(inventorySummaryProvider.notifier).loadSummary();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreItems();
    }
  }

  Future<void> _loadMoreItems() async {
    final state = ref.read(inventoryProvider);
    if (state.isLoading || state.pagination == null) return;

    if (state.pagination!.hasNextPage) {
      _currentPage++;
      await ref.read(inventoryProvider.notifier).loadInventory(
            page: _currentPage,
            itemType: _currentFilter,
          );
    }
  }

  Future<void> _onRefresh() async {
    _currentPage = 1;
    await ref.read(inventoryProvider.notifier).refresh();
    await ref.read(inventorySummaryProvider.notifier).loadSummary();
  }

  void _onFilterChanged(String? filter) {
    setState(() {
      _currentFilter = filter;
      _currentPage = 1;
    });

    ref.read(inventoryProvider.notifier).loadInventory(
          itemType: filter,
          isRefresh: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryState = ref.watch(inventoryProvider);
    final summaryState = ref.watch(inventorySummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎒 Inventory'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Column(
          children: [
            // Summary widget
            if (summaryState.summary != null)
              InventorySummaryWidget(summary: summaryState.summary!),

            // Filter widget
            InventoryFilterWidget(
              currentFilter: _currentFilter,
              onFilterChanged: _onFilterChanged,
            ),

            // Items list
            Expanded(
              child: _buildItemsList(inventoryState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(InventoryState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(inventoryProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Your inventory is empty',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Explore zones and collect items!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: state.items.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.items.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final item = state.items[index];
        return InventoryItemCard(
          item: item,
          onDelete: () => _showDeleteDialog(item),
          onTap: () => _showItemDetails(item),
        );
      },
    );
  }

  Future<void> _showDeleteDialog(InventoryItem item) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref.read(inventoryProvider.notifier).deleteItem(item.id);
      await ref.read(inventorySummaryProvider.notifier).loadSummary();
    }
  }

  void _showItemDetails(InventoryItem item) {
    Navigator.of(context).pushNamed(
      '/inventory/detail',
      arguments: item,
    );
  }
}
