// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/login_popup.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/kai_ai_bot.dart';
import '../../widgets/seller_bottom_nav_bar.dart';

import '../../models/user_model.dart';
import '../../models/order_model.dart';
import '../home/home_screen.dart';
import '../order/orders_screen.dart';
import '../search/search_screen.dart';
import '../seller/seller_home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  bool _isEditing = false;
  int _currentIndex = 3;
  String _gender = 'male';
  DateTime? _birthdate;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      _nameController = TextEditingController(text: authProvider.currentUser!.name);
      _phoneController = TextEditingController(text: authProvider.currentUser!.phoneNumber);
      _addressController = TextEditingController(text: authProvider.currentUser!.address);
      _emailController = TextEditingController(text: authProvider.currentUser!.email);
      _gender = authProvider.currentUser!.gender;
      _birthdate = DateTime(1995, 5, 15);
    } else {
      _nameController = TextEditingController();
      _phoneController = TextEditingController();
      _addressController = TextEditingController();
      _emailController = TextEditingController();
      _birthdate = DateTime(1995, 1, 1);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.currentUser != null) {
      _nameController.text = authProvider.currentUser!.name;
      _phoneController.text = authProvider.currentUser!.phoneNumber;
      _addressController.text = authProvider.currentUser!.address;
      _emailController.text = authProvider.currentUser!.email;
      _gender = authProvider.currentUser!.gender;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isSeller = authProvider.isSeller;
    switch (index) {
      case 0:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => isSeller ? const SellerHomeScreen() : const HomeScreen()));
        break;
      case 1:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
        break;
      case 2:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
        break;
      case 3: break;
    }
  }

  Future<void> _saveChanges() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.updateProfile(
      name: _nameController.text,
      phoneNumber: _phoneController.text,
      address: _addressController.text,
    );
    if (!mounted) return;
    if (success) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [Icon(LucideIcons.checkCircle2, color: Colors.green.shade400), const SizedBox(width: 8), const Text('Profile updated successfully')]), backgroundColor: Colors.green.shade50, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    }
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 60, height: 4, decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: theme.colorScheme.errorContainer, shape: BoxShape.circle), child: Icon(LucideIcons.logOut, size: 40, color: theme.colorScheme.error)),
            const SizedBox(height: 16),
            Text('Logout', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Are you sure you want to logout?', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: () async { Navigator.pop(dialogContext); await authProvider.logout(); if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [Icon(LucideIcons.info, color: Colors.blue.shade400), const SizedBox(width: 8), const Text('Logged out successfully')]), backgroundColor: Colors.blue.shade50, behavior: SnackBarBehavior.floating)); setState(() {}); }, style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.error, foregroundColor: theme.colorScheme.onError), child: const Text('Logout'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginPopup() => LoginPopup.show(context: context, onLoginSuccess: () => setState(() {}));

  String _getProfileImagePath() => _gender == 'female' ? 'assets/images/girlprofile.jpg' : 'assets/images/boyprofile.jpg';
  String _formatBirthdate(DateTime? date) => date == null ? 'Not provided' : '${date.month}/${date.day}/${date.year}';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        body: SafeArea(
          child: Consumer2<AuthProvider, OrderProvider>(
            builder: (context, authProvider, orderProvider, _) {
              final isGuest = authProvider.currentUser?.id == 'guest';
              final user = authProvider.currentUser;
              final isSeller = authProvider.isSeller;

              List<Order> userOrders = [];
              if (user != null && !isGuest) {
                userOrders = orderProvider.getUserOrders(user.id);
              }

              return Column(
                children: [
                  _buildAppBar(isGuest, user != null && !isGuest, isSeller),
                  Expanded(
                    child: isGuest || user == null
                        ? _buildGuestView()
                        : _buildUserView(user, userOrders, isSeller),
                  ),
                ],
              );
            },
          ),
        ),
        floatingActionButton: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.isSeller) return const SizedBox.shrink();
            return const KaiAiBot();
          },
        ),
        bottomNavigationBar: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return authProvider.isSeller
                ? SellerBottomNavBar(currentIndex: _currentIndex, onTap: _onNavBarTap)
                : BottomNavBar(currentIndex: _currentIndex, onTap: _onNavBarTap);
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isGuest, bool isLoggedIn, bool isSeller) {
    final theme = Theme.of(context);
    final activeColor = isSeller ? theme.colorScheme.secondary : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: theme.colorScheme.surface, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), spreadRadius: 0, blurRadius: 10, offset: const Offset(0, 2))]),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => isSeller ? const SellerHomeScreen() : const HomeScreen()));
              }
            },
            child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)), child: Icon(LucideIcons.chevronLeft, size: 20, color: theme.colorScheme.onSurface)),
          ),
          const SizedBox(width: 12),
          ClipOval(child: Image.asset(_getProfileImagePath(), width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 40, height: 40, color: activeColor.withValues(alpha: 0.2), child: Icon(LucideIcons.user, size: 20, color: activeColor)))),
          const SizedBox(width: 12),
          Text('My Profile', style: theme.textTheme.titleMedium),
          const Spacer(),
          if (isLoggedIn && !_isEditing)
            GestureDetector(
              onTap: () => setState(() => _isEditing = true),
              child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: activeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(LucideIcons.edit2, color: activeColor, size: 18)),
            ),
          if (isSeller)
            Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: activeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(LucideIcons.store, color: activeColor, size: 14), const SizedBox(width: 4), Text('Seller', style: TextStyle(color: activeColor, fontSize: 11, fontWeight: FontWeight.w600))])),
        ],
      ),
    );
  }

  Widget _buildGuestView() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(LucideIcons.userCircle2, size: 80, color: primary.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text('Sign in to access all features', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 32),
          _buildFeatureItem(icon: LucideIcons.shoppingBag, title: 'Track Orders', description: 'View your order history and status'),
          const SizedBox(height: 12),
          _buildFeatureItem(icon: LucideIcons.flower2, title: 'Place Order', description: 'Purchase your favorite flowers'),
          const SizedBox(height: 12),
          _buildFeatureItem(icon: LucideIcons.tag, title: 'Exclusive Offers', description: 'Get personalized discounts'),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: _showLoginPopup, child: const Text('Login'))),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Don't have an account? ", style: theme.textTheme.bodyMedium), GestureDetector(onTap: _showLoginPopup, child: Text('Sign Up', style: TextStyle(color: primary, fontWeight: FontWeight.bold)))]),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String title, required String description}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.colorScheme.surfaceContainerHighest)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: theme.colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: theme.colorScheme.primary, size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: theme.textTheme.titleSmall), const SizedBox(height: 4), Text(description, style: theme.textTheme.bodySmall)])),
        ],
      ),
    );
  }

  Widget _buildUserView(UserModel user, List<Order> userOrders, bool isSeller) {
    final theme = Theme.of(context);
    final activeColor = isSeller ? theme.colorScheme.secondary : theme.colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                ),
              ),
              Positioned(
                top: 50, left: 0, right: 0,
                child: Column(
                  children: [
                    Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.surface, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), spreadRadius: 0, blurRadius: 20, offset: const Offset(0, 5))]),
                      child: ClipOval(child: Image.asset(_getProfileImagePath(), width: 110, height: 110, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: activeColor.withValues(alpha: 0.2), child: Icon(LucideIcons.user, size: 40, color: activeColor)))),
                    ),
                    const SizedBox(height: 16),
                    Text(user.name, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: activeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Text(isSeller ? 'Seller' : 'Buyer', style: TextStyle(fontSize: 12, color: activeColor, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.colorScheme.surfaceContainerHighest)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Personal Information', style: theme.textTheme.titleMedium),
                const SizedBox(height: 20),
                if (!_isEditing)
                  Column(
                    children: [
                      Row(children: [Expanded(child: _buildInfoGridItem(LucideIcons.mail, 'Email', user.email, isSeller)), const SizedBox(width: 12), Expanded(child: _buildInfoGridItem(LucideIcons.phone, 'Phone', user.phoneNumber.isEmpty ? 'Not provided' : user.phoneNumber, isSeller))]),
                      const SizedBox(height: 12),
                      _buildInfoGridItem(LucideIcons.mapPin, 'Address', user.address.isEmpty ? 'Not provided' : user.address, isSeller, isAddress: true),
                      const SizedBox(height: 12),
                      Row(children: [Expanded(child: _buildInfoGridItem(LucideIcons.userSquare2, 'Gender', _gender == 'female' ? 'Female' : 'Male', isSeller)), const SizedBox(width: 12), Expanded(child: _buildInfoGridItem(LucideIcons.calendar, 'Birthdate', _formatBirthdate(_birthdate), isSeller))]),
                      const SizedBox(height: 12),
                      _buildInfoGridItem(LucideIcons.clock, 'Member Since', userOrders.isNotEmpty ? '${userOrders.last.orderDate.month}/${userOrders.last.orderDate.day}/${userOrders.last.orderDate.year}' : '${DateTime.now().month}/${DateTime.now().day}/${DateTime.now().year}', isSeller),
                    ],
                  ),
                if (_isEditing) ...[
                  _buildEditableField(controller: _nameController, icon: LucideIcons.user, label: 'Full Name', enabled: true, isSeller: isSeller),
                  _buildEditableField(controller: _emailController, icon: LucideIcons.mail, label: 'Email', enabled: false, isSeller: isSeller),
                  _buildEditableField(controller: _phoneController, icon: LucideIcons.phone, label: 'Phone Number', keyboardType: TextInputType.phone, enabled: true, isSeller: isSeller),
                  _buildEditableField(controller: _addressController, icon: LucideIcons.mapPin, label: 'Delivery Address', maxLines: 2, enabled: true, isSeller: isSeller),
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _gender,
                        isExpanded: true,
                        icon: Icon(LucideIcons.chevronDown, color: theme.colorScheme.onSurfaceVariant),
                        items: [
                          DropdownMenuItem(value: 'male', child: Row(children: [Icon(LucideIcons.userSquare2, size: 18, color: Colors.blue.shade400), const SizedBox(width: 8), const Text('Male')])),
                          DropdownMenuItem(value: 'female', child: Row(children: [Icon(LucideIcons.userSquare2, size: 18, color: theme.colorScheme.primary), const SizedBox(width: 8), const Text('Female')])),
                        ],
                        onChanged: null,
                        hint: const Text('Gender'),
                      ),
                    ),
                  ),
                  _buildEditableField(controller: TextEditingController(text: _formatBirthdate(_birthdate)), icon: LucideIcons.calendar, label: 'Birthdate', enabled: false, isSeller: isSeller),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () { setState(() { _isEditing = false; _nameController.text = user.name; _phoneController.text = user.phoneNumber; _addressController.text = user.address; }); }, child: const Text('Cancel'))),
                    const SizedBox(width: 12),
                    Expanded(child: Consumer<AuthProvider>(builder: (context, authProvider, child) => ElevatedButton(onPressed: authProvider.isLoading ? null : _saveChanges, style: ElevatedButton.styleFrom(backgroundColor: activeColor), child: authProvider.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Text('Save Changes')))),
                  ]),
                ],
              ],
            ),
          ),
          if (!isSeller && userOrders.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: theme.colorScheme.surfaceContainerHighest)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Recent Orders', style: theme.textTheme.titleMedium), TextButton(onPressed: () => _onNavBarTap(2), child: Text('View All', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)))]),
                const SizedBox(height: 12),
                ...userOrders.take(2).map((order) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Container(width: 50, height: 50, decoration: BoxDecoration(color: order.status.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(LucideIcons.package, color: order.status.color, size: 24)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(order.productName, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 2), Text('₱${order.totalAmount.toStringAsFixed(2)} • ${order.status.displayName}', style: theme.textTheme.bodySmall)]))]))),
              ]),
            ),
          ],
          const SizedBox(height: 32),
          Center(
            child: SizedBox(
              height: 50, width: double.infinity,
              child: OutlinedButton(onPressed: _logout, style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error, side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5), width: 1.5)), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(LucideIcons.logOut, size: 18), SizedBox(width: 8), Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))])),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoGridItem(IconData icon, String label, String value, bool isSeller, {bool isAddress = false}) {
    final theme = Theme.of(context);
    final activeColor = isSeller ? theme.colorScheme.secondary : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: activeColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: isAddress ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 16, color: activeColor)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)), const SizedBox(height: 2), Text(value, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600), maxLines: isAddress ? 2 : 1, overflow: TextOverflow.ellipsis)])),
        ],
      ),
    );
  }

  Widget _buildEditableField({required TextEditingController controller, required IconData icon, required String label, bool enabled = true, bool isSeller = false, int maxLines = 1, TextInputType? keyboardType}) {
    final theme = Theme.of(context);
    final activeColor = isSeller ? theme.colorScheme.secondary : theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller, enabled: enabled, maxLines: maxLines, keyboardType: keyboardType,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20, color: enabled ? activeColor : theme.colorScheme.onSurfaceVariant),
          filled: true,
          fillColor: enabled ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.surfaceContainerHighest)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.colorScheme.surfaceContainerHighest)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: activeColor, width: 2)),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}