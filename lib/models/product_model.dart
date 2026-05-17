// lib/models/product_model.dart
class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final String floristId;
  final String floristName;
  final String category;
  final List<String> imageUrls; // list of asset or network URLs
  final double rating;
  final int totalReviews;
  final bool isAvailable;
  final int stockQuantity;
  final List<String> tags;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.floristId,
    required this.floristName,
    required this.category,
    required this.imageUrls,
    required this.rating,
    required this.totalReviews,
    required this.isAvailable,
    required this.stockQuantity,
    required this.tags,
  });

  // Convenience getter for the first image URL
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : 'assets/images/placeholder.jpg';

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'].toDouble(),
      description: json['description'],
      floristId: json['floristId'],
      floristName: json['floristName'],
      category: json['category'],
      imageUrls: List<String>.from(json['imageUrls']),
      rating: json['rating'].toDouble(),
      totalReviews: json['totalReviews'],
      isAvailable: json['isAvailable'],
      stockQuantity: json['stockQuantity'],
      tags: List<String>.from(json['tags']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'floristId': floristId,
      'floristName': floristName,
      'category': category,
      'imageUrls': imageUrls,
      'rating': rating,
      'totalReviews': totalReviews,
      'isAvailable': isAvailable,
      'stockQuantity': stockQuantity,
      'tags': tags,
    };
  }
}