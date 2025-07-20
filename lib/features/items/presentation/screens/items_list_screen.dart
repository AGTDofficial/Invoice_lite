import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/item_dao.dart';
import '../../data/item_model.dart';

class ItemsListScreen extends ConsumerStatefulWidget {
  static const String routeName = '/items';
  
  const ItemsListScreen({super.key});

  @override
  ConsumerState<ItemsListScreen> createState() => _ItemsListScreenState();
}

class _ItemsListScreenState extends ConsumerState<ItemsListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Item> _filterItems(List<Item> items, String query) {
    if (query.isEmpty) return items;
    
    final lowercaseQuery = query.toLowerCase();
    return items.where((item) {
      return item.name.toLowerCase().contains(lowercaseQuery) ||
          item.itemCode.toLowerCase().contains(lowercaseQuery) ||
          (item.description?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  Widget _buildSearchBar(ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search items...',
          hintStyle: TextStyle(color: theme.hintColor),
          prefixIcon: Icon(Icons.search, color: theme.hintColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: theme.hintColor),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                    FocusScope.of(context).unfocus();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsAsync = ref.watch(itemsProvider);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: _isSearching 
            ? null 
            : const Text('Items', style: TextStyle(fontWeight: FontWeight.w600)),
        elevation: 0,
        centerTitle: false,
        actions: [
          if (_isSearching) ...[
            Expanded(
              child: _buildSearchBar(theme),
            ),
            IconButton(
              icon: const Text('Cancel'),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  FocusScope.of(context).unfocus();
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.search, size: 24),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: RefreshIndicator(
        color: theme.primaryColor,
        onRefresh: () async {
          ref.invalidate(itemsProvider);
        },
        child: itemsAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return _buildEmptyState(theme);
            }
            
            final filteredItems = _filterItems(items, _searchController.text);
            
            if (filteredItems.isEmpty) {
              return _buildNoResultsFound(theme);
            }
            
            return Column(
              children: [
                if (_isSearching || _searchController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          '${filteredItems.length} ${filteredItems.length == 1 ? 'item' : 'items'} found',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                        const Spacer(),
                        if (_searchController.text.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                            child: const Text('Clear'),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filteredItems.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return _buildItemCard(context, item, theme);
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => _buildShimmerLoading(theme),
          error: (error, stack) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Failed to load items',
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(itemsProvider),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to add item screen
          // Navigator.pushNamed(context, AddEditItemScreen.routeName);
        },
        icon: const Icon(Icons.add),
        label: const Text('New Item'),
        elevation: 2,
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, Item item, ThemeData theme) {
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: () {
          // TODO: Navigate to item detail/edit screen
          // Navigator.pushNamed(
          //   context,
          //   AddEditItemScreen.routeName,
          //   arguments: item.id,
          // );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: theme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.itemCode,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${item.currentStock} ${item.unit}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${item.saleRate.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stock: ${item.currentStock} ${item.unit}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: item.currentStock <= item.minStockLevel
                              ? Colors.red
                              : theme.hintColor,
                          fontWeight: item.currentStock <= item.minStockLevel
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (item.description?.isNotEmpty ?? false) ...[
                const SizedBox(height: 12),
                Text(
                  item.description!,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: theme.brightness == Brightness.light
              ? Colors.grey[300]!
              : Colors.grey[800]!,
          highlightColor: theme.brightness == Brightness.light
              ? Colors.grey[100]!
              : Colors.grey[700]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 80,
                            height: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 80,
                          height: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 60,
                          height: 12,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 14,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 72,
              color: theme.hintColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Items Yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first item by tapping the + button below',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsFound(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 72,
              color: theme.hintColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Results Found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No items match your search criteria',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 16),
            if (_searchController.text.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear Search'),
              ),
          ],
        ),
      ),
    );
  }
}
