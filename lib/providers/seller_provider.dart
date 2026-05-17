// lib/providers/seller_provider.dart
import 'package:flutter/material.dart';
import '../models/seller_product_model.dart';

class SellerProvider with ChangeNotifier {
  final List<SellerProduct> _allSellerProducts = [];

  SellerProvider() {
    addMockSellerProducts();
  }

  List<SellerProduct> getAllProducts() {
    return _allSellerProducts.where((p) => p.isAvailable).toList();
  }

  List<SellerProduct> getProductsBySeller(String sellerId) {
    return _allSellerProducts
        .where((p) => p.sellerId == sellerId)
        .toList();
  }

  // Get flash sale products
  List<SellerProduct> getFlashSaleProducts() {
    return _allSellerProducts
        .where((p) => p.isFlashSale && p.isAvailable)
        .toList();
  }

  // Toggle flash sale status
  Future<void> toggleFlashSale(String productId, {double? discount, DateTime? endTime}) async {
    final index = _allSellerProducts.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final product = _allSellerProducts[index];
      _allSellerProducts[index] = SellerProduct(
        id: product.id,
        sellerId: product.sellerId,
        sellerName: product.sellerName,
        storeName: product.storeName, // preserve store name
        name: product.name,
        price: product.price,
        description: product.description,
        category: product.category,
        imageUrl: product.imageUrl,
        quantity: product.quantity,
        isAvailable: product.isAvailable,
        createdAt: product.createdAt,
        isFlashSale: !product.isFlashSale,
        discountPercent: discount ?? product.discountPercent,
        flashSaleEnds: endTime ?? product.flashSaleEnds,
      );
      notifyListeners();
    }
  }

  Future<bool> addProduct({
    required String sellerId,
    required String sellerName,
    required String storeName,   // NEW
    required String name,
    required double price,
    required String description,
    required String category,
    required String imageUrl,
    required int quantity,
    bool isFlashSale = false,
    double? discountPercent,
    DateTime? flashSaleEnds,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final newProduct = SellerProduct(
      id: 'seller_prod_${DateTime.now().millisecondsSinceEpoch}',
      sellerId: sellerId,
      sellerName: sellerName,
      storeName: storeName,       // NEW
      name: name,
      price: price,
      description: description,
      category: category,
      imageUrl: imageUrl,
      quantity: quantity,
      isAvailable: quantity > 0,
      createdAt: DateTime.now(),
      isFlashSale: isFlashSale,
      discountPercent: discountPercent,
      flashSaleEnds: flashSaleEnds,
    );

    _allSellerProducts.add(newProduct);
    notifyListeners();
    return true;
  }

  Future<bool> updateProduct({
    required String productId,
    required String name,
    required double price,
    required String description,
    required String category,
    required String imageUrl,
    required int quantity,
    required bool isAvailable,
    bool? isFlashSale,
    double? discountPercent,
    DateTime? flashSaleEnds,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _allSellerProducts.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final oldProduct = _allSellerProducts[index];
      final updatedProduct = SellerProduct(
        id: productId,
        sellerId: oldProduct.sellerId,
        sellerName: oldProduct.sellerName,
        storeName: oldProduct.storeName, // preserve store name
        name: name,
        price: price,
        description: description,
        category: category,
        imageUrl: imageUrl,
        quantity: quantity,
        isAvailable: isAvailable,
        createdAt: oldProduct.createdAt,
        isFlashSale: isFlashSale ?? oldProduct.isFlashSale,
        discountPercent: discountPercent ?? oldProduct.discountPercent,
        flashSaleEnds: flashSaleEnds ?? oldProduct.flashSaleEnds,
      );

      _allSellerProducts[index] = updatedProduct;
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> deleteProduct(String productId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _allSellerProducts.removeWhere((p) => p.id == productId);
    notifyListeners();
    return true;
  }

  void addMockSellerProducts() {
    if (_allSellerProducts.isEmpty) {
      _allSellerProducts.addAll([
        SellerProduct(
          id: 'sp1',
          sellerId: 'f1',
          sellerName: 'Carri and Wynne Flower Shop',
          storeName: 'Carri and Wynne Flower Shop', // store name same as seller name for mock
          name: 'Handmade Paper Flowers',
          price: 350.00,
          description: 'Beautiful handmade paper flowers',
          category: 'Bouquets',
          imageUrl: 'assets/images/r1.jpg',
          quantity: 10,
          isAvailable: true,
          createdAt: DateTime.now(),
          isFlashSale: true,
          discountPercent: 20,
        ),
        SellerProduct(
          id: 'sp2',
          sellerId: 'f1',
          sellerName: 'Carri and Wynne Flower Shop',
          storeName: 'Carri and Wynne Flower Shop',
          name: 'Dried Lavender Bundle',
          price: 250.00,
          description: 'Fragrant dried lavender',
          category: 'Plants',
          imageUrl: 'assets/images/r2.jpg',
          quantity: 15,
          isAvailable: true,
          createdAt: DateTime.now(),
        ),
      ]);
      notifyListeners();
    }
  }
}