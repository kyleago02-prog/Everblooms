// lib/screens/search/search_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/search_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/kai_ai_bot.dart';


class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _currentIndex = 1;
  String _selectedFilter = 'All';
  String _sortBy = 'Relevance';

  final List<String> _filterOptions = [
    'All', 'Bouquets', 'Plants', 'Sympathy', 'Romance', 'Valentine'
  ];
  final List<String> _sortOptions = [
    'Relevance', 'Price: Low to High', 'Price: High to Low', 'Rating', 'Newest'
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    switch (index) {
      case 0: Navigator.pushReplacementNamed(context, '/home'); break;
      case 1: break;
      case 2: Navigator.pushReplacementNamed(context, '/orders'); break;
      case 3: Navigator.pushReplacementNamed(context, '/profile'); break;
    }
  }

  List<Product> _searchProducts(List<Product> allProducts, String query) {
    if (query.isEmpty) return allProducts;
    final lowerQuery = query.toLowerCase();
    return allProducts.where((product) {
      return product.name.toLowerCase().contains(lowerQuery) ||
          product.floristName.toLowerCase().contains(lowerQuery) ||
          product.category.toLowerCase().contains(lowerQuery) ||
          product.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  List<Product> _getFilteredAndSorted(List<Product> allProducts, String query) {
    List<Product> products = _searchProducts(allProducts, query);
    if (_selectedFilter != 'All') {
      products = products.where((p) => p.category == _selectedFilter || p.tags.any((t) => t.toLowerCase() == _selectedFilter.toLowerCase())).toList();
    }
    switch (_sortBy) {
      case 'Price: Low to High': products.sort((a,b) => a.price.compareTo(b.price)); break;
      case 'Price: High to Low': products.sort((a,b) => b.price.compareTo(a.price)); break;
      case 'Rating': products.sort((a,b) => b.rating.compareTo(a.rating)); break;
      case 'Newest': products.sort((a,b) => b.id.compareTo(a.id)); break;
    }
    return products;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.05),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: theme.textTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: 'Search flowers, florists...',
                        hintStyle: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFFBBBBBB)),
                        border: InputBorder.none,
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(icon: Icon(LucideIcons.x, color: theme.colorScheme.onSurfaceVariant), onPressed: () => setState(() => _searchController.clear()))
                            : IconButton(icon: Icon(LucideIcons.search, color: primary), onPressed: () {}),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ..._filterOptions.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = filter),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? primary : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            filter,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.arrowDownUp, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _sortBy,
                              icon: Icon(LucideIcons.chevronDown, size: 16, color: theme.colorScheme.onSurfaceVariant),
                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              onChanged: (v) => setState(() => _sortBy = v!),
                              items: _sortOptions.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Consumer2<SearchProvider, ProductProvider>(
                builder: (context, searchProvider, productProvider, child) {
                  final displayed = _getFilteredAndSorted(productProvider.products, _searchController.text);
                  if (_searchController.text.isEmpty && displayed.isEmpty) {
                    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(LucideIcons.search, size: 64, color: theme.colorScheme.surfaceContainerHighest),
                      const SizedBox(height: 16),
                      Text('Search for flowers, florists, or occasions', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Text('Try: "Roses", "Valentine", "Blossom"', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ]));
                  }
                  if (_searchController.text.isNotEmpty && displayed.isEmpty) {
                    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(LucideIcons.frown, size: 64, color: theme.colorScheme.surfaceContainerHighest),
                      const SizedBox(height: 16),
                      Text('No results found', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Try different keywords or filters', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 24),
                      ElevatedButton(onPressed: () => setState(() { _searchController.clear(); _selectedFilter = 'All'; _sortBy = 'Relevance'; }), child: const Text('Clear Filters')),
                    ]));
                  }
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('${displayed.length} products found', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            if (_searchController.text.isNotEmpty) Text('Search: "${_searchController.text}"', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                          ]),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: displayed.length,
                          itemBuilder: (_, i) => ProductCard(product: displayed[i], variant: 'modern'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const KaiAiBot(),
      bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex, onTap: _onNavBarTap),
    );
  }
}