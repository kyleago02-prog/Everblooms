class UserModel {
  final String id;
  String name;
  String email;
  String phoneNumber;
  String address;
  String gender;
  String userType; // 'buyer' or 'seller'

  // New subscription fields
  bool isSubscribed;
  int? productLimit; // null means unlimited (for subscribed sellers)

  // Store name for sellers (optional)
  String? storeName;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.address,
    required this.gender,
    required this.userType,
    this.isSubscribed = false,
    this.productLimit = 5, // default limit for free sellers
    this.storeName,        // new optional field
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'gender': gender,
      'userType': userType,
      'isSubscribed': isSubscribed,
      'productLimit': productLimit,
      'storeName': storeName, // new field
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      address: map['address'] ?? '',
      gender: map['gender'] ?? 'male',
      userType: map['userType'] ?? 'buyer',
      isSubscribed: map['isSubscribed'] ?? false,
      productLimit: map['productLimit'], // can be null
      storeName: map['storeName'],       // new field
    );
  }
}