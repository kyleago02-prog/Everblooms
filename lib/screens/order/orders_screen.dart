// lib/screens/orders/orders_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/kai_ai_bot.dart';
import '../home/home_screen.dart';

import '../search/search_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/login_popup.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({Key? key}) : super(key: key);

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 2;
  late TabController _tabController;
  String _selectedFilter = 'All';

  final List<String> _filterOptions = [
    'All',
    'Pending',
    'Preparing',
    'Out for Delivery',
    'Delivered',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onNavBarTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        break;
      case 1:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SearchScreen()));
        break;
      case 2:
        break;
      case 3:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        break;
    }
  }

  void _showLoginPopup() {
    LoginPopup.show(context: context, onLoginSuccess: () => setState(() {}));
  }

  List<Order> _getFilteredOrders(List<Order> orders) {
    if (_selectedFilter == 'All') return orders;
    final statusIndex = _filterOptions.indexOf(_selectedFilter) - 1;
    if (statusIndex >= 0) return orders.where((o) => o.status.index == statusIndex).toList();
    return orders;
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return Icons.pending_outlined;
      case OrderStatus.preparing: return Icons.inventory;
      case OrderStatus.outForDelivery: return Icons.local_shipping;
      case OrderStatus.delivered: return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Consumer2<AuthProvider, OrderProvider>(
            builder: (context, authProvider, orderProvider, _) {
              final isGuest = authProvider.currentUser?.id == 'guest';
              final user = authProvider.currentUser;

              List<Order> allOrders = [];
              if (user != null && !isGuest) {
                allOrders = orderProvider.getUserOrders(user.id);
              }
              final filteredOrders = _getFilteredOrders(allOrders);

              return Column(
                children: [
                  _buildAppBar(isGuest, allOrders.isNotEmpty),
                  if (isGuest) _buildGuestWarning(),
                  if (!isGuest && allOrders.isNotEmpty) _buildTabBar(),
                  Expanded(
                    child: isGuest
                        ? _buildGuestView()
                        : allOrders.isEmpty
                            ? _buildEmptyOrders()
                            : _buildOrdersList(filteredOrders),
                  ),
                ],
              );
            },
          ),
        ),
        floatingActionButton: const KaiAiBot(),
        bottomNavigationBar: BottomNavBar(currentIndex: _currentIndex, onTap: _onNavBarTap),
      ),
    );
  }

  Widget _buildAppBar(bool isGuest, bool hasOrders) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.05), spreadRadius: 1, blurRadius: 10)],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.pink.shade400),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.pink.shade100, Colors.purple.shade100]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.shopping_bag, color: Colors.pink.shade600, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('My Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400)),
          const Spacer(),
          if (!isGuest && hasOrders)
            GestureDetector(
              onTap: _showFilterBottomSheet,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.filter_list, color: Colors.pink.shade400, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(30)),
      child: TabBar(
        controller: _tabController,
        indicator: const BoxDecoration(),
        labelColor: Colors.pink.shade400,
        unselectedLabelColor: Colors.grey.shade700,
        tabs: const [Tab(text: 'Active'), Tab(text: 'History')],
      ),
    );
  }

  Widget _buildGuestWarning() => const SizedBox.shrink();

  Widget _buildGuestView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.pink.shade50, Colors.purple.shade50]),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 100, color: Colors.pink.shade200.withValues(alpha: 0.3)),
                Positioned(
                  top: 40, right: 60,
                  child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.pink.withValues(alpha: 0.2), spreadRadius: 2, blurRadius: 10)]), child: Icon(Icons.local_shipping, color: Colors.pink.shade400, size: 30)),
                ),
                Positioned(
                  bottom: 40, left: 60,
                  child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.purple.withValues(alpha: 0.2), spreadRadius: 2, blurRadius: 10)]), child: Icon(Icons.check_circle, color: Colors.purple.shade400, size: 30)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('Login to view your order history\nand track your deliveries', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5)),
          const SizedBox(height: 32),
          SizedBox(width: 200, height: 55, child: ElevatedButton(onPressed: _showLoginPopup, style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 0), child: const Text('Login Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))),
          const SizedBox(height: 16),
          TextButton(onPressed: () => _onNavBarTap(0), child: Text('Continue Browsing', style: TextStyle(color: Colors.pink.shade400, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildEmptyOrders() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(height: 200, width: 200, decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.pink.shade50, Colors.purple.shade50]), shape: BoxShape.circle), child: Center(child: Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.pink.shade200))),
          const SizedBox(height: 32),
          const Text('No Orders Yet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          const Text('Looks like you haven\'t placed any orders yet.\nStart shopping to see your orders here!', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5)),
          const SizedBox(height: 32),
          SizedBox(width: 200, height: 55, child: ElevatedButton(onPressed: () => _onNavBarTap(0), style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))), child: const Text('Browse Flowers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filterOptions.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedFilter = filter),
                      backgroundColor: Colors.grey.shade100,
                      selectedColor: Colors.pink.shade100,
                      checkmarkColor: Colors.pink,
                      labelStyle: TextStyle(color: isSelected ? Colors.pink.shade700 : Colors.grey.shade700, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide.none),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final order = orders[index];
                final isActive = order.status.index < 3;
                if (_tabController.index == 0 && !isActive) return const SizedBox.shrink();
                if (_tabController.index == 1 && isActive) return const SizedBox.shrink();
                return _buildModernOrderCard(order);
              },
              childCount: orders.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildModernOrderCard(Order order) {
    final isActive = order.status.index < 3;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 2, blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: isActive ? [order.status.color.withValues(alpha: 0.1), Colors.transparent] : [Colors.grey.shade50, Colors.transparent]),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: order.status.color.withValues(alpha: 0.2), shape: BoxShape.circle), child: Icon(_getStatusIcon(order.status), size: 14, color: order.status.color)),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Order #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  Text('Placed on ${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: order.status.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: order.status.color.withValues(alpha: 0.3))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (isActive) SizedBox(width: 8, height: 8, child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation<Color>(order.status.color))),
                    if (isActive) const SizedBox(width: 4),
                    Text(order.status.displayName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: order.status.color)),
                  ]),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 1, blurRadius: 5)]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: order.productImage.startsWith('assets/')
                        ? Image.asset(order.productImage, fit: BoxFit.cover)
                        : Image.network(order.productImage, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.pink.shade100, child: const Icon(Icons.broken_image, color: Colors.white, size: 30))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(children: [Icon(Icons.store, size: 12, color: Colors.grey.shade500), const SizedBox(width: 4), Expanded(child: Text(order.floristName, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis))]),
                      const SizedBox(height: 4),
                      Row(children: [Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500), const SizedBox(width: 4), Text('Delivery: ${order.deliveryDate.day}/${order.deliveryDate.month}/${order.deliveryDate.year}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600))]),
                    ],
                  ),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('₱${order.totalAmount.toStringAsFixed(2)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pink.shade700)),
                  const SizedBox(height: 4),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Text('Qty: ${order.quantity}', style: TextStyle(fontSize: 10, color: Colors.grey.shade600))),
                ]),
              ],
            ),
          ),
          if (order.cardMessage != null && order.cardMessage!.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.pink.shade100.withValues(alpha: 0.3))),
              child: Row(children: [Icon(Icons.message_outlined, size: 16, color: Colors.pink.shade400), const SizedBox(width: 8), Expanded(child: Text('"${order.cardMessage}"', style: TextStyle(fontSize: 12, color: Colors.pink.shade700, fontStyle: FontStyle.italic)))]),
            ),
          if (isActive)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
              child: Row(children: [
                Expanded(child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: Colors.pink.shade400, side: BorderSide(color: Colors.pink.shade200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(vertical: 12)), child: const Text('Track Order'))),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0), child: const Text('Help'))),
              ]),
            ),
          if (order.status.index == 3)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200))),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (index) => IconButton(onPressed: () {}, icon: Icon(Icons.star_border, color: Colors.grey.shade400, size: 24)))),
            ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          const Text('Filter Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ..._filterOptions.map((filter) => ListTile(
            title: Text(filter),
            // ignore: deprecated_member_use
            leading: Radio<String>(value: filter, groupValue: _selectedFilter, onChanged: (value) { setState(() => _selectedFilter = value!); Navigator.pop(context); }, activeColor: Colors.pink),
            onTap: () { setState(() => _selectedFilter = filter); Navigator.pop(context); },
          )),
        ]),
      ),
    );
  }
}