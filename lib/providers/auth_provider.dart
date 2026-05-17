// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  // Controllers for login
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Controllers for registration
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController storeNameController = TextEditingController();

  // Form keys
  final GlobalKey<FormState> loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> registerFormKey = GlobalKey<FormState>();

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null && _currentUser?.id != 'guest';
  bool get isLoggedIn => _currentUser != null && _currentUser?.id != 'guest';
  bool get isSeller => _currentUser != null && _currentUser?.userType == 'seller';

  AuthProvider() {
    _setGuestUser();
  }

  void _setGuestUser() {
    _currentUser = UserModel(
      id: 'guest',
      name: 'Guest User',
      email: 'guest@example.com',
      phoneNumber: '',
      address: '',
      gender: 'male',
      userType: 'buyer',
      isSubscribed: false,
      productLimit: null,
      storeName: null,
    );
    notifyListeners();
  }

  // UPDATED: login now accepts an optional userType parameter
  Future<bool> login(String email, String password, {String? userType}) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    if (email.isNotEmpty && password.isNotEmpty) {
      // Simple gender detection (demo)
      String gender = 'male';
      final emailLower = email.toLowerCase();
      if (emailLower.contains('maria') || emailLower.contains('jane') ||
          emailLower.contains('sarah') || emailLower.contains('emily') ||
          emailLower.contains('anna') || emailLower.contains('lisa')) {
        gender = 'female';
      }

      final String finalUserType = userType ?? 'buyer'; // Use selected type or default

      _currentUser = UserModel(
        id: finalUserType == 'seller' ? 'f1' : 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: finalUserType == 'seller' ? 'Carri and Wynne' : email.split('@')[0],
        email: email,
        phoneNumber: '+1234567890',
        address: '123 Main St, City, State 12345',
        gender: gender,
        userType: finalUserType,
        isSubscribed: false,
        productLimit: finalUserType == 'seller' ? 20 : null,
        storeName: finalUserType == 'seller' ? 'Carri and Wynne Flower Shop' : null,
      );

      emailController.clear();
      passwordController.clear();

      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String address,
    required String gender,
    required String userType,
    String? storeName,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    if (name.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
      _currentUser = UserModel(
        id: userType == 'seller' ? 'f1' : 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        phoneNumber: phoneNumber.isEmpty ? '+1234567890' : phoneNumber,
        address: address.isEmpty ? '123 Main St' : address,
        gender: gender,
        userType: userType,
        isSubscribed: false,
        productLimit: userType == 'seller' ? 5 : null,
        storeName: storeName,
      );

      // Clear controllers
      nameController.clear();
      emailController.clear();
      passwordController.clear();
      phoneController.clear();
      addressController.clear();
      storeNameController.clear();

      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _currentUser = UserModel(
      id: 'guest',
      name: 'Guest User',
      email: 'guest@example.com',
      phoneNumber: '',
      address: '',
      gender: 'male',
      userType: 'buyer',
      isSubscribed: false,
      productLimit: null,
      storeName: null,
    );

    // Clear all controllers
    emailController.clear();
    passwordController.clear();
    nameController.clear();
    phoneController.clear();
    addressController.clear();
    storeNameController.clear();

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String name,
    required String phoneNumber,
    required String address,
  }) async {
    if (_currentUser == null || _currentUser?.id == 'guest') return false;

    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    _currentUser = UserModel(
      id: _currentUser!.id,
      name: name,
      email: _currentUser!.email,
      phoneNumber: phoneNumber,
      address: address,
      gender: _currentUser!.gender,
      userType: _currentUser!.userType,
      isSubscribed: _currentUser!.isSubscribed,
      productLimit: _currentUser!.productLimit,
      storeName: _currentUser!.storeName,
    );

    _isLoading = false;
    notifyListeners();
    return true;
  }

  void setSubscriptionStatus(bool subscribed) {
    if (_currentUser == null) return;
    _currentUser = UserModel(
      id: _currentUser!.id,
      name: _currentUser!.name,
      email: _currentUser!.email,
      phoneNumber: _currentUser!.phoneNumber,
      address: _currentUser!.address,
      gender: _currentUser!.gender,
      userType: _currentUser!.userType,
      isSubscribed: subscribed,
      productLimit: subscribed ? null : 100,
      storeName: _currentUser!.storeName,
    );
    notifyListeners();
  }
}