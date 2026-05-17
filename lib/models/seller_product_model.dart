class SellerProduct {
  final String id;
  final String sellerId;
  final String sellerName;      // seller's personal name
  final String storeName;       // NEW: florist shop name
  String name;
  double price;
  String description;
  String category;
  String imageUrl;
  int quantity;
  bool isAvailable;
  DateTime createdAt;

  // Flash sale fields
  bool isFlashSale;
  double? discountPercent;
  DateTime? flashSaleEnds;

  SellerProduct({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.storeName,     // NEW: required
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.quantity,
    required this.isAvailable,
    required this.createdAt,
    this.isFlashSale = false,
    this.discountPercent,
    this.flashSaleEnds,
  });

  double get discountedPrice {
    if (isFlashSale && discountPercent != null) {
      return price * (1 - discountPercent! / 100);
    }
    return price;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'storeName': storeName,                 // NEW
      'name': name,
      'price': price,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'isAvailable': isAvailable,
      'createdAt': createdAt.toIso8601String(),
      'isFlashSale': isFlashSale,
      'discountPercent': discountPercent,
      'flashSaleEnds': flashSaleEnds?.toIso8601String(),
    };
  }

  factory SellerProduct.fromMap(Map<String, dynamic> map, String id) {
    return SellerProduct(
      id: id,
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      storeName: map['storeName'] ?? '',      // NEW
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? 'assets/images/r1.jpg',
      quantity: map['quantity'] ?? 0,
      isAvailable: map['isAvailable'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      isFlashSale: map['isFlashSale'] ?? false,
      discountPercent: map['discountPercent']?.toDouble(),
      flashSaleEnds: map['flashSaleEnds'] != null
          ? DateTime.parse(map['flashSaleEnds'])
          : null,
    );
  }
}