// lib/models/florist_model.dart
class Florist {
  final String id;
  final String shopName;
  final String ownerName;
  final String email;
  final String phoneNumber;
  final String address;
  final double rating;
  final int totalReviews;
  final bool isOpen;
  final String openingHours;
  final String closingHours;
  final String imageUrl;
  final List<String> categories;

  final String open;

  Florist({
    required this.id,
    required this.shopName,
    required this.ownerName,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.rating,
    required this.totalReviews,
    required this.isOpen,
    required this.openingHours,
    required this.closingHours,
    required this.imageUrl,
    required this.open,
    required this.categories,
  });

  factory Florist.fromMap(Map<String, dynamic> map, String id) {
    return Florist(
      id: id,
      shopName: map['shopName'] ?? '',
      ownerName: map['ownerName'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      isOpen: map['isOpen'] ?? false,
      openingHours: map['openingHours'] ?? '09:00 am',
      closingHours: map['closingHours'] ?? '6:00 pm',
      imageUrl: map['imageUrl'] ?? '',
      categories: List<String>.from(map['categories'] ?? []),
      open: 'Monday-Friday',
    );
  }
}