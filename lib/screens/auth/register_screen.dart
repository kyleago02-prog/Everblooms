// lib/screens/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedGender = 'male';
  String _selectedUserType = 'buyer';

  final List<String> _addressOptions = const [
    'Select Address',
    'City Proper',
    'Zone I',
    'Zone II',
    'Zone III',
    'Aplaya',
    'Goma',
    'Igpit',
    'Matti',
    'San Miguel',
    'Sulop Road',
    'Roxas Street',
    'Quezon Avenue',
    'Rizal Avenue',
    'Other (Specify)',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _formatEmail(String email) {
    if (email.isEmpty) return email;
    if (!email.contains('@')) return '$email@gmail.com';
    return email;
  }

  Future<void> _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String email = _formatEmail(_emailController.text.trim());

      final success = await authProvider.register(
        name: _nameController.text.trim(),
        email: email,
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        gender: _selectedGender,
        userType: _selectedUserType,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration successful as $_selectedUserType!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Registration failed. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 80,
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.flower2, size: 40, color: primary),
                  ),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  prefixIcon: LucideIcons.user,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your name';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  prefixIcon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  prefixIcon: LucideIcons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedGender,
                      isExpanded: true,
                      icon: Icon(LucideIcons.chevronDown, color: theme.colorScheme.onSurfaceVariant),
                      items: [
                        DropdownMenuItem(
                          value: 'male',
                          child: Row(
                            children: [
                              Icon(LucideIcons.userSquare2, color: Colors.blue.shade400, size: 20),
                              const SizedBox(width: 8),
                              const Text('Male'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'female',
                          child: Row(
                            children: [
                              Icon(LucideIcons.userSquare2, color: primary, size: 20),
                              const SizedBox(width: 8),
                              const Text('Female'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        setState(() => _selectedGender = newValue!);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedUserType,
                      isExpanded: true,
                      icon: Icon(LucideIcons.chevronDown, color: theme.colorScheme.onSurfaceVariant),
                      items: const [
                        DropdownMenuItem(
                          value: 'buyer',
                          child: Row(
                            children: [
                              Icon(LucideIcons.shoppingBag, color: Colors.purple, size: 20),
                              SizedBox(width: 8),
                              Text('Buy Flowers'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'seller',
                          child: Row(
                            children: [
                              Icon(LucideIcons.store, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text('Sell Flowers'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        setState(() => _selectedUserType = newValue!);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _addressController.text.isEmpty
                          ? _addressOptions[0]
                          : (_addressOptions.contains(_addressController.text)
                          ? _addressController.text
                          : _addressOptions[0]),
                      isExpanded: true,
                      icon: Icon(LucideIcons.chevronDown, color: theme.colorScheme.onSurfaceVariant),
                      items: _addressOptions.map((String address) {
                        return DropdownMenuItem<String>(
                          value: address,
                          child: Text(
                            address,
                            style: TextStyle(
                              color: address == _addressOptions[0] ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() => _addressController.text = newValue);
                        }
                      },
                    ),
                  ),
                ),
                if (_addressController.text == 'Other (Specify)')
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: CustomTextField(
                      controller: _addressController,
                      label: 'Specify Address',
                      prefixIcon: LucideIcons.edit,
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty || value == 'Other (Specify)') {
                          return 'Please specify your address';
                        }
                        return null;
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  prefixIcon: LucideIcons.lock,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye, color: theme.colorScheme.onSurfaceVariant),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a password';
                    if (value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  prefixIcon: LucideIcons.lock,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? LucideIcons.eyeOff : LucideIcons.eye, color: theme.colorScheme.onSurfaceVariant),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please confirm your password';
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return CustomButton(
                      text: 'Register',
                      onPressed: _handleRegister,
                      isLoading: authProvider.isLoading,
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? ", style: theme.textTheme.bodyMedium),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                      child: Text(
                        'Login',
                        style: TextStyle(color: primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}