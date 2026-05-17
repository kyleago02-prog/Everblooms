// lib/providers/search_provider.dart
import 'package:flutter/material.dart';
import 'product_provider.dart';
import '../models/product_model.dart';
import '../models/florist_model.dart';

class SearchProvider with ChangeNotifier {
  String _searchQuery = '';
  List<Product> _productResults = [];
  List<Florist> _floristResults = [];
  bool _isSearching = false;

  String get searchQuery => _searchQuery;
  List<Product> get productResults => _productResults;
  List<Florist> get floristResults => _floristResults;
  bool get isSearching => _isSearching;
  bool get hasResults => _productResults.isNotEmpty || _floristResults.isNotEmpty;

  void search(String query, ProductProvider productProvider) {
    _searchQuery = query;
    _isSearching = true;
    notifyListeners();

    if (query.isEmpty) {
      clearSearch();
      return;
    }

    final lowerQuery = query.toLowerCase();

    _productResults = productProvider.products.where((product) {
      return product.name.toLowerCase().contains(lowerQuery) ||
          product.category.toLowerCase().contains(lowerQuery) ||
          product.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();

    _floristResults = productProvider.florists.where((florist) {
      return florist.shopName.toLowerCase().contains(lowerQuery) ||
          florist.categories.any((cat) => cat.toLowerCase().contains(lowerQuery));
    }).toList();

    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _productResults = [];
    _floristResults = [];
    _isSearching = false;
    notifyListeners();
  }
}