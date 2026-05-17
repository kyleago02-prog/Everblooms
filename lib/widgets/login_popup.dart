// lib/widgets/login_popup.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginPopup extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginPopup({Key? key, required this.onLoginSuccess}) : super(key: key);

  static void show({
    required BuildContext context,
    required VoidCallback onLoginSuccess,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LoginPopup(onLoginSuccess: onLoginSuccess),
    );
  }

  @override
  State<LoginPopup> createState() => _LoginPopupState();
}

class _LoginPopupState extends State<LoginPopup> {
  String selectedUserType = 'buyer';

  void _showRegisterPopup(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RegisterPopup(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final sellerColor = theme.colorScheme.secondary;
    
    final activeColor = selectedUserType == 'seller' ? sellerColor : primary;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Login Required',
                        style: theme.textTheme.headlineLarge,
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please login or create an account to continue',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: activeColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(LucideIcons.flower2, color: activeColor, size: 40);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // BUYER / SELLER TOGGLE
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedUserType = 'buyer'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: selectedUserType == 'buyer' ? primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.user,
                                    color: selectedUserType == 'buyer' ? Colors.white : primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Buyer',
                                    style: TextStyle(
                                      color: selectedUserType == 'buyer' ? Colors.white : primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => selectedUserType = 'seller'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: selectedUserType == 'seller' ? sellerColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.store,
                                    color: selectedUserType == 'seller' ? Colors.white : sellerColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Seller',
                                    style: TextStyle(
                                      color: selectedUserType == 'seller' ? Colors.white : sellerColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return Form(
                        key: authProvider.loginFormKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: authProvider.emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(LucideIcons.mail, color: activeColor.withValues(alpha: 0.6)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: activeColor, width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: authProvider.passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(LucideIcons.lock, color: activeColor.withValues(alpha: 0.6)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: activeColor, width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () async {
                                  String email = authProvider.emailController.text.trim();
                                  if (email.isNotEmpty && !email.contains('@')) {
                                    email = '$email@gmail.com';
                                  }

                                  final success = await authProvider.login(
                                    email,
                                    authProvider.passwordController.text,
                                    userType: selectedUserType,
                                  );

                                  if (success && context.mounted) {
                                    Navigator.pop(context);
                                    if (authProvider.isSeller) {
                                      Navigator.pushReplacementNamed(context, '/seller-home');
                                    } else {
                                      Navigator.pushReplacementNamed(context, '/home');
                                    }
                                  } else if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Invalid credentials'),
                                        backgroundColor: theme.colorScheme.error,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: activeColor,
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        height: 24, width: 24,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(
                                  selectedUserType == 'seller' ? 'Login as Seller' : 'Login',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OR', style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFF94A3B8))),
                      ),
                      const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => _showRegisterPopup(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: activeColor,
                        side: BorderSide(color: activeColor.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: const Text('Create New Account'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Continue as Guest',
                        style: theme.textTheme.labelLarge?.copyWith(color: const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RegisterPopup extends StatefulWidget {
  const RegisterPopup({Key? key}) : super(key: key);

  @override
  State<RegisterPopup> createState() => _RegisterPopupState();
}

class _RegisterPopupState extends State<RegisterPopup> {
  final List<String> _addressOptions = [
    'Select Address',
    'Digos City Proper',
    'Zone I, Digos City',
    'Zone II, Digos City',
    'Zone III, Digos City',
    'Aplaya, Digos City',
    'Davao del Sur, Digos City',
    'Goma, Digos City',
    'Igpit, Digos City',
    'Kapatagan, Digos City',
    'Matti, Digos City',
    'San Miguel, Digos City',
    'Sulop Road, Digos City',
    'Roxas Street, Digos City',
    'Quezon Avenue, Digos City',
    'Rizal Avenue, Digos City',
    'Other (Specify)',
  ];

  String _selectedGender = 'male';
  String _selectedUserType = 'buyer';
  String _selectedAddress = 'Select Address';
  bool _showCustomAddress = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final sellerColor = theme.colorScheme.secondary;
    final activeColor = _selectedUserType == 'seller' ? sellerColor : primary;
    final bool isSeller = _selectedUserType == 'seller';

    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create Account',
                        style: theme.textTheme.headlineLarge,
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign up to get started',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedUserType = 'buyer';
                              _selectedAddress = 'Select Address';
                              _showCustomAddress = false;
                              Provider.of<AuthProvider>(context, listen: false).addressController.clear();
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: !isSeller ? primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.user, color: !isSeller ? Colors.white : primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Buyer',
                                    style: TextStyle(
                                      color: !isSeller ? Colors.white : primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _selectedUserType = 'seller';
                              _selectedAddress = 'Select Address';
                              _showCustomAddress = false;
                              Provider.of<AuthProvider>(context, listen: false).addressController.clear();
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: isSeller ? sellerColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.store, color: isSeller ? Colors.white : sellerColor, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Seller',
                                    style: TextStyle(
                                      color: isSeller ? Colors.white : sellerColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Consumer<AuthProvider>(
                    builder: (context, authProvider, child) {
                      return Form(
                        key: authProvider.registerFormKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: authProvider.nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(LucideIcons.user, color: activeColor.withValues(alpha: 0.6)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: activeColor, width: 2),
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? 'Please enter your name' : null,
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: authProvider.emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(LucideIcons.mail, color: activeColor.withValues(alpha: 0.6)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: activeColor, width: 2),
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? 'Please enter your email' : null,
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: authProvider.phoneController,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: Icon(LucideIcons.phone, color: activeColor.withValues(alpha: 0.6)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: activeColor, width: 2),
                                ),
                              ),
                              validator: (v) => (v == null || v.isEmpty) ? 'Please enter your phone number' : null,
                            ),
                            const SizedBox(height: 16),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedGender,
                                decoration: const InputDecoration(
                                  labelText: 'Gender',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                                icon: Icon(LucideIcons.chevronDown, color: activeColor.withValues(alpha: 0.6)),
                                dropdownColor: Colors.white,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'male',
                                    child: Row(
                                      children: [
                                        Icon(LucideIcons.userSquare2, size: 20, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text('Male'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'female',
                                    child: Row(
                                      children: [
                                        Icon(LucideIcons.userSquare2, size: 20, color: Colors.pink),
                                        SizedBox(width: 8),
                                        Text('Female'),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (v) => setState(() => _selectedGender = v!),
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (isSeller) ...[
                              TextFormField(
                                controller: authProvider.storeNameController,
                                decoration: InputDecoration(
                                  labelText: 'Store Name',
                                  prefixIcon: Icon(LucideIcons.store, color: activeColor.withValues(alpha: 0.6)),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: activeColor, width: 2),
                                  ),
                                ),
                                validator: (v) => (v == null || v.isEmpty) ? 'Please enter your store name' : null,
                              ),
                              const SizedBox(height: 16),
                            ],

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedAddress,
                                decoration: InputDecoration(
                                  labelText: 'Address',
                                  prefixIcon: Icon(LucideIcons.mapPin, color: activeColor.withValues(alpha: 0.6)),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                ),
                                icon: Icon(LucideIcons.chevronDown, color: activeColor.withValues(alpha: 0.6)),
                                dropdownColor: Colors.white,
                                items: _addressOptions.map((addr) {
                                  return DropdownMenuItem<String>(
                                    value: addr,
                                    child: Text(
                                      addr,
                                      style: TextStyle(
                                        color: addr == 'Select Address' ? const Color(0xFF94A3B8) : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() {
                                      _selectedAddress = v;
                                      _showCustomAddress = v == 'Other (Specify)';
                                      if (_showCustomAddress) {
                                        authProvider.addressController.clear();
                                      } else {
                                        authProvider.addressController.text = v;
                                      }
                                    });
                                  }
                                },
                                validator: (v) => (v == null || v == 'Select Address') ? 'Please select your address' : null,
                              ),
                            ),

                            if (_showCustomAddress)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: TextFormField(
                                  controller: authProvider.addressController,
                                  decoration: InputDecoration(
                                    labelText: 'Specify Address',
                                    hintText: 'Enter your complete address',
                                    prefixIcon: Icon(LucideIcons.edit, color: activeColor.withValues(alpha: 0.6)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: activeColor, width: 2),
                                    ),
                                  ),
                                  validator: (v) => (_showCustomAddress && (v == null || v.isEmpty))
                                      ? 'Please specify your address'
                                      : null,
                                ),
                              ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: authProvider.passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(LucideIcons.lock, color: activeColor.withValues(alpha: 0.6)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: activeColor, width: 2),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Please enter a password';
                                if (v.length < 6) return 'Password must be at least 6 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon: Icon(LucideIcons.lock, color: activeColor.withValues(alpha: 0.6)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: activeColor, width: 2),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Please confirm your password';
                                if (v != authProvider.passwordController.text) return 'Passwords do not match';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading
                                    ? null
                                    : () async {
                                  String email = authProvider.emailController.text.trim();
                                  if (email.isNotEmpty && !email.contains('@')) {
                                    email = '$email@gmail.com';
                                  }

                                  final address = _showCustomAddress
                                      ? authProvider.addressController.text
                                      : _selectedAddress;

                                  final success = await authProvider.register(
                                    name: authProvider.nameController.text,
                                    email: email,
                                    password: authProvider.passwordController.text,
                                    phoneNumber: authProvider.phoneController.text,
                                    address: address,
                                    gender: _selectedGender,
                                    userType: _selectedUserType,
                                    storeName: isSeller ? authProvider.storeNameController.text : null,
                                  );

                                  if (success && context.mounted) {
                                    Navigator.pop(context);
                                    if (_selectedUserType == 'seller') {
                                      Navigator.pushReplacementNamed(context, '/seller-home');
                                    } else {
                                      Navigator.pushReplacementNamed(context, '/home');
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Registration successful as $_selectedUserType!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } else if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Registration failed. Please try again.'),
                                        backgroundColor: theme.colorScheme.error,
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: activeColor,
                                ),
                                child: authProvider.isLoading
                                    ? const SizedBox(
                                        height: 24, width: 24,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : Text(
                                  isSeller ? 'Register as Seller' : 'Register',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Already have an account? Login',
                        style: TextStyle(color: activeColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}