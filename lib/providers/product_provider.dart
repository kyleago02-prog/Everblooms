// lib/providers/product_provider.dart
import 'package:flutter/material.dart';
import '../models/florist_model.dart';
import '../models/product_model.dart';

class ProductProvider with ChangeNotifier {
  List<Florist> _florists = [];
  List<Product> _products = [];
  bool _isLoading = false;

  List<Florist> get florists => _florists;
  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  ProductProvider() {
    loadMockData();
  }

  void loadMockData() {
    _isLoading = true;
    notifyListeners();

    // Florists (same as before)
    _florists = [
      Florist(
        id: 'f1',
        shopName: 'CARRI AND WYNNE FLOWER SHOP',
        ownerName: 'Sarah Johnson',
        email: 'sarah@blossom.com',
        phoneNumber: '+639705528780',
        address: 'Aurora 3rd St, (1st Block), Purok Rose, San Jose, Digos',
        rating: 4.8,
        totalReviews: 245,
        isOpen: true,
        openingHours: '8:00 am',
        closingHours: '7:00 pm',
        imageUrl: 'assets/images/flower3.jpg',
        categories: ['Sympathy', 'Bouquets', 'Romance'],
        open: 'Monday to Friday',
      ),
      Florist(
        id: 'f2',
        shopName: 'AM Digos Flowershop',
        ownerName: 'Michael Chen',
        email: 'michael@petal.com',
        phoneNumber: '+639705528780',
        address: 'Zone 1 Quezon avenue',
        rating: 4.6,
        totalReviews: 189,
        isOpen: true,
        openingHours: '6:00 am',
        closingHours: '7:00 pm',
        imageUrl: 'assets/images/flower2.jpg',
        categories: ['Bouquets', 'Anniversary', 'Romance'],
        open: 'Monday to Friday',
      ),
      Florist(
        id: 'f3',
        shopName: 'Plantitos Ph - Digos',
        ownerName: 'Emily Davis',
        email: 'emily@rosegarden.com',
        phoneNumber: '+639705528780',
        address: 'Punta Biao, Sitio Owangon, Barangay',
        rating: 4.9,
        totalReviews: 312,
        isOpen: false,
        openingHours: '8:00 am',
        closingHours: '6:00 pm',
        imageUrl: 'assets/images/flower1.png',
        categories: ['Bouquets', 'Plants', 'Romance', 'Sympathy'],
        open: 'Monday to Friday',
      ),
      Florist(
        id: 'f4',
        shopName: 'Bloomfield Flowershop Digos',
        ownerName: 'David Wilson',
        email: 'david@floralfantasy.com',
        phoneNumber: '+639705528780',
        address: 'Beside Camal Eatery, corner 2nd Crumb st, Gallarde Street',
        rating: 4.7,
        totalReviews: 178,
        isOpen: true,
        openingHours: '7:00 am',
        closingHours: '5:00 pm',
        imageUrl: 'assets/images/flower2.jpg',
        categories: ['Bouquets', 'Birthday', 'Anniversary'],
        open: 'Monday to Friday',
      ),
    ];

    // Products with full fields
    _products = [
      Product(
        id: 'p1',
        name: 'Lilium',
        price: 650.99,
        description: 'A stunning plant, perfect for home decoration. This plant is carefully cared for by greenery.',
        floristId: 'f1',
        floristName: 'Carri and Wynne Flower Shop',
        category: 'Plants',
        imageUrls: ['assets/images/p2.jpg'],
        rating: 4.9,
        totalReviews: 128,
        isAvailable: true,
        stockQuantity: 20,
        tags: ['plant', 'home', 'design'],
      ),
      Product(
        id: 'p2',
        name: 'Red Roses',
        price: 439.99,
        description: 'Bright and cheerful red roses that bring sunshine to any room. Perfect for birthdays or just to brighten someone\'s day.',
        floristId: 'f1',
        floristName: 'Carri and Wynne Flower Shop',
        category: 'Bouquets',
        imageUrls: ['assets/images/r1.jpg'],
        rating: 4.7,
        totalReviews: 89,
        isAvailable: true,
        stockQuantity: 15,
        tags: ['red', 'valentines', 'gift', 'anniversary'],
      ),
      Product(
        id: 'p3',
        name: 'White Flower',
        price: 759.99,
        description: 'A sophisticated arrangement of white lilies, perfect for sympathy occasions or elegant events. Arranged in a beautiful ceramic vase.',
        floristId: 'f2',
        floristName: 'AM Digos Flowershop',
        category: 'Sympathy',
        imageUrls: ['assets/images/sym.png'],
        rating: 4.9,
        totalReviews: 56,
        isAvailable: true,
        stockQuantity: 10,
        tags: ['sympathy', 'elegant'],
      ),
      Product(
        id: 'p4',
        name: 'Sunflowers Bouquet',
        price: 600.99,
        description: 'A beautiful peace sunflower. Known for its air-purifying qualities and elegant yellow blooms.',
        floristId: 'f2',
        floristName: 'AM Digos Flowershop',
        category: 'Bouquets',
        imageUrls: ['assets/images/f4.jpg'],
        rating: 4.6,
        totalReviews: 42,
        isAvailable: true,
        stockQuantity: 25,
        tags: ['gift', 'yellow', 'indoor'],
      ),
      Product(
        id: 'p5',
        name: 'Purple Tulips',
        price: 1500.99,
        description: 'A dreamy bouquet of purple tulips, symbolising romance and prosperity. Perfect for anniversaries and special occasions.',
        floristId: 'f3',
        floristName: 'Plantitos Ph - Digos',
        category: 'Bouquets',
        imageUrls: ['assets/images/f5.jpg'],
        rating: 4.9,
        totalReviews: 73,
        isAvailable: true,
        stockQuantity: 8,
        tags: ['valentines', 'romance', 'birthday', 'anniversary'],
      ),
      Product(
        id: 'p6',
        name: 'Lucky Bamboo Plant',
        price: 849.99,
        description: 'Good for home decorations and brings luck.',
        floristId: 'f3',
        floristName: 'Plantitos Ph - Digos',
        category: 'Plants',
        imageUrls: ['assets/images/f6.jpg'],
        rating: 4.8,
        totalReviews: 94,
        isAvailable: true,
        stockQuantity: 30,
        tags: ['plant', 'decorations'],
      ),
      Product(
        id: 'p7',
        name: 'Potted Plant',
        price: 859.99,
        description: 'A beautiful selection of garden ideas perfect for home decorations.',
        floristId: 'f4',
        floristName: 'Bloomfield Flowershop Digos',
        category: 'Plants',
        imageUrls: ['assets/images/f7.jpg'],
        rating: 4.7,
        totalReviews: 67,
        isAvailable: true,
        stockQuantity: 12,
        tags: ['plant', 'garden', 'decorations'],
      ),
      Product(
        id: 'p8',
        name: 'White Lily',
        price: 1250.00,
        description: 'Not for sale – display only.',
        floristId: 'f4',
        floristName: 'Bloomfield Flowershop Digos',
        category: 'Plants',
        imageUrls: ['assets/images/p4.jpg'],
        rating: 4.8,
        totalReviews: 51,
        isAvailable: true,
        stockQuantity: 5,
        tags: ['plant', 'design'],
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }

  List<Product> getProductsByCategory(String category) {
    return _products.where((p) => p.category == category).toList();
  }

  List<Product> getProductsByFlorist(String floristId) {
    return _products.where((p) => p.floristId == floristId).toList();
  }

  Florist? getFloristById(String id) {
    try {
      return _florists.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<String> getCategories() {
    return ['Bouquets', 'Plants', 'Decoration', 'Sympathy', 'Romance'];
  }
}