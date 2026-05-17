// lib/screens/seller/seller_home_screen.dart
//
// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN SYSTEM — defined once, used everywhere.
//  Senior rule: if you hardcode a color/radius/shadow twice, you've already
//  failed. Use SellerTheme constants below throughout.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/seller_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/seller_product_model.dart';
import '../order_tracking_map_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
abstract class ST {
  // Brand palette
  static const primary    = Color(0xFFE8547A); // rose
  static const primaryDim = Color(0xFFF28FAA); // rose tint
  static const primaryBg  = Color(0xFFFFF0F3); // rose ultra-light
  static const accent     = Color(0xFFFF8C42); // warm orange — flash sale only
  static const surface    = Color(0xFFFFFFFF);
  static const bg         = Color(0xFFF7F8FA);
  static const ink        = Color(0xFF1A1D26);
  static const inkMid     = Color(0xFF6B7280);
  static const inkLight   = Color(0xFFB0B7C3);
  static const success    = Color(0xFF22C55E);
  static const warning    = Color(0xFFF59E0B);
  static const danger     = Color(0xFFEF4444);
  static const info       = Color(0xFF3B82F6);

  // Gradients
  static const brandGrad = LinearGradient(
    colors: [Color(0xFFE8547A), Color(0xFFB5385C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const cardGrad = LinearGradient(
    colors: [Color(0xFFFFEEF2), Color(0xFFFFF5F7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Radius scale — 4-point system, no freelancing
  static const r4  = Radius.circular(4);
  static const r8  = Radius.circular(8);
  static const r12 = Radius.circular(12);
  static const r16 = Radius.circular(16);
  static const r24 = Radius.circular(24);

  static const br4  = BorderRadius.all(r4);
  static const br8  = BorderRadius.all(r8);
  static const br12 = BorderRadius.all(r12);
  static const br16 = BorderRadius.all(r16);
  static const br24 = BorderRadius.all(r24);

  // Shadows — one source of truth
  static List<BoxShadow> get shadowSm => [
    BoxShadow(color: primary.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
  ];
  static List<BoxShadow> get shadowMd => [
    BoxShadow(color: ink.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4)),
    BoxShadow(color: ink.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 1)),
  ];
  static List<BoxShadow> get shadowBrand => [
    BoxShadow(color: primary.withValues(alpha: 0.30), blurRadius: 20, offset: const Offset(0, 8)),
  ];

  // Spacing — 8pt grid
  static const s4  = SizedBox(height: 4);
  static const s8  = SizedBox(height: 8);
  static const s12 = SizedBox(height: 12);
  static const s16 = SizedBox(height: 16);
  static const s20 = SizedBox(height: 20);
  static const s24 = SizedBox(height: 24);
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

Widget buildProductImage(
    String imageUrl, {
      double? width,
      double? height,
      BoxFit fit = BoxFit.cover,
    }) {
  if (imageUrl.startsWith('assets/')) {
    return Image.asset(imageUrl, width: width, height: height, fit: fit);
  }
  return Image.network(
    imageUrl,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) => Container(
      color: ST.primaryBg,
      child: const Icon(Icons.image_not_supported_outlined, color: ST.primaryDim),
    ),
  );
}

// Reusable chip
Widget _statusChip(String label, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.12),
    borderRadius: ST.br8,
  ),
  child: Text(
    label,
    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.4),
  ),
);

// Reusable section header
Widget _sectionHeader(String title, {VoidCallback? onViewAll}) => Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ST.ink)),
    if (onViewAll != null)
      GestureDetector(
        onTap: onViewAll,
        child: const Text('View all',
            style: TextStyle(fontSize: 13, color: ST.primary, fontWeight: FontWeight.w600)),
      ),
  ],
);

// ─────────────────────────────────────────────────────────────────────────────
//  SELLER HOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({Key? key}) : super(key: key);

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  String _selectedCategory = 'All';
  String _selectedOrderFilter = 'All';

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  static const _categories = ['All', 'Bouquets', 'Plants', 'Birthday', 'Anniversary', 'Sympathy', 'Romance'];
  static const _orderStatuses = ['All', 'Pending', 'Accepted', 'Rejected', 'Delivered'];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────────────────────────────
  int _currentCount() {
    final sp = Provider.of<SellerProvider>(context, listen: false);
    final ap = Provider.of<AuthProvider>(context, listen: false);
    return sp.getProductsBySeller(ap.currentUser?.id ?? '').length;
  }

  int? _limit() => Provider.of<AuthProvider>(context, listen: false).currentUser?.productLimit;
  bool _canAdd() { final l = _limit(); return l == null || _currentCount() < l; }

  void _toggleSubscription() {
    final ap = Provider.of<AuthProvider>(context, listen: false);
    final next = !ap.currentUser!.isSubscribed;
    ap.setSubscriptionStatus(next);
    setState(() {});
    _showSnack(next ? 'Welcome to Premium' : 'Subscription cancelled.', next ? ST.success : ST.inkMid);
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: const RoundedRectangleBorder(borderRadius: ST.br12),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _onNavTap(int index) {
    final ap = Provider.of<AuthProvider>(context, listen: false);
    if (index == 2 && !ap.currentUser!.isSubscribed) {
      _showSubscribeDialog(); return;
    }
    HapticFeedback.selectionClick();
    _fadeCtrl.forward(from: 0);
    setState(() => _selectedIndex = index);
  }

  // ── dialogs ──────────────────────────────────────────────────────────────
  void _showSubscribeDialog() => showDialog(
    context: context,
    builder: (ctx) => _SubscribeDialog(onSubscribe: () { Navigator.pop(ctx); _toggleSubscription(); }),
  );

  void _showAddProductDialog() => showDialog(
    context: context,
    builder: (ctx) => const Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: AddProductDialog(),
    ),
  );

  void _showEditProductDialog(SellerProduct p) => showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: EditProductDialog(product: p),
    ),
  );

  void _showDeleteDialog(SellerProduct p) => showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: ST.br16),
      title: const Text('Delete Product', style: TextStyle(fontWeight: FontWeight.w700)),
      content: RichText(
        text: TextSpan(
          style: const TextStyle(color: ST.inkMid, fontSize: 14),
          children: [
            const TextSpan(text: 'Remove '),
            TextSpan(text: '"${p.name}"', style: const TextStyle(fontWeight: FontWeight.w600, color: ST.ink)),
            const TextSpan(text: ' from your shop? This cannot be undone.'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            await Provider.of<SellerProvider>(context, listen: false).deleteProduct(p.id);
            if (context.mounted) { Navigator.pop(ctx); _showSnack('Product removed.', ST.danger); }
          },
          style: FilledButton.styleFrom(backgroundColor: ST.danger),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  Future<void> _logout() async {
    final ap = Provider.of<AuthProvider>(context, listen: false);
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
            shape: const RoundedRectangleBorder(borderRadius: ST.br16),
            title: const Text('Log out', style: TextStyle(fontWeight: FontWeight.w700)),
            content: const Text('You ll need to sign in again to access your shop.'),
            actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(
    onPressed: () => Navigator.pop(ctx, true),
    style: FilledButton.styleFrom(backgroundColor: ST.danger),
    child: const Text('Log out'),
    ),
    ],
    ),
    );
    if (confirm == true) {
      await ap.logout();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  // ── analytics helpers ────────────────────────────────────────────────────
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  int _totalSold(List<SellerOrder> orders) =>
      orders.where((o) => o.status == 'Accepted' || o.status == 'Delivered').fold(0, (s, o) => s + o.quantity);

  double _monthlySales(List<SellerOrder> orders) {
    final now = DateTime.now();
    return orders
        .where((o) =>
    (o.status == 'Accepted' || o.status == 'Delivered') &&
        o.orderDate.month == now.month &&
        o.orderDate.year == now.year)
        .fold(0.0, (s, o) => s + o.totalAmount);
  }

  int _pendingCount(List<SellerOrder> orders) => orders.where((o) => o.status == 'Pending').length;

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final ap = Provider.of<AuthProvider>(context, listen: false);

    if (ap.currentUser?.userType != 'seller') {
      WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) Navigator.pushReplacementNamed(context, '/home'); });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ST.bg,
        extendBodyBehindAppBar: false,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Consumer2<AuthProvider, OrderProvider>(
            builder: (context, auth, orderProv, _) {
              final sellerOrders = orderProv.orders.where((o) => o.floristId == auth.currentUser!.id).toList();
              final pending = _pendingCount(sellerOrders);
              return _buildAppBar(auth, pending);
            },
          ),
        ),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: Consumer3<AuthProvider, SellerProvider, OrderProvider>(
            builder: (context, auth, sellerProv, orderProv, _) {
              final orders = orderProv.orders.where((o) => o.floristId == auth.currentUser!.id).toList();
              final sellerProducts = sellerProv.getProductsBySeller(auth.currentUser!.id);
              final flashProducts = sellerProducts.where((p) => p.isFlashSale).toList();
              final regularProducts = sellerProducts.where((p) => !p.isFlashSale).toList();

              return IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildShopTab(flashProducts, regularProducts, sellerProducts, orders, auth),
                  _buildProductsTab([...regularProducts, ...flashProducts]),
                  auth.currentUser!.isSubscribed
                      ? _buildAnalyticsTab(sellerProducts, orders)
                      : _buildPremiumLocked(),
                  _buildOrdersTab(orders),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: Consumer2<AuthProvider, OrderProvider>(
          builder: (context, auth, orderProv, _) {
            return _buildBottomNav(_pendingCount(orderProv.orders));
          },
        ),
      ),
    );
  }

  // =========================================================================
  //  APP BAR
  // =========================================================================
  PreferredSizeWidget _buildAppBar(AuthProvider ap, int pending) {
    return AppBar(
      backgroundColor: ST.primary,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ap.currentUser?.storeName ?? 'My Shop',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.3),
          ),
          Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(color: ST.success, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              const Text('Online', style: TextStyle(color: Colors.white60, fontSize: 11)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 22),
          tooltip: 'Add product',
          onPressed: _showAddProductDialog,
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
          tooltip: 'Log out',
          onPressed: _logout,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // =========================================================================
  //  BOTTOM NAV
  // =========================================================================
  Widget _buildBottomNav(int pending) {
    return Container(
      decoration: BoxDecoration(
        color: ST.surface,
        boxShadow: [
          BoxShadow(color: ST.ink.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _navItem(0, Icons.storefront_rounded, Icons.storefront_outlined, 'Shop'),
              _navItem(1, Icons.inventory_2_rounded, Icons.inventory_2_outlined, 'Products'),
              _navItem(2, Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Analytics'),
              _navItemBadged(3, Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Orders', pending),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData activeIcon, IconData inactiveIcon, String label) {
    final sel = _selectedIndex == idx;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onNavTap(idx),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: sel ? ST.primaryBg : Colors.transparent,
                borderRadius: ST.br24,
              ),
              child: Icon(sel ? activeIcon : inactiveIcon,
                  size: 22, color: sel ? ST.primary : ST.inkLight),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                  color: sel ? ST.primary : ST.inkLight,
                )),
          ],
        ),
      ),
    );
  }

  Widget _navItemBadged(int idx, IconData activeIcon, IconData inactiveIcon, String label, int badge) {
    final sel = _selectedIndex == idx;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onNavTap(idx),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: sel ? ST.primaryBg : Colors.transparent,
                borderRadius: ST.br24,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(sel ? activeIcon : inactiveIcon,
                      size: 22, color: sel ? ST.primary : ST.inkLight),
                  if (badge > 0)
                    Positioned(
                      top: -6, right: -8,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: ST.danger, shape: BoxShape.circle),
                        child: Text('$badge',
                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                  color: sel ? ST.primary : ST.inkLight,
                )),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  //  PREMIUM LOCKED
  // =========================================================================
  Widget _buildPremiumLocked() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C42)]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFF8C42).withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8)),
                ],
              ),
              child: const Icon(Icons.workspace_premium_rounded, size: 48, color: Colors.white),
            ),
            ST.s24,
            const Text('Analytics is a\nPremium Feature',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: ST.ink, height: 1.2)),
            ST.s12,
            const Text(
              'Unlock sales insights, revenue charts, and customer data to grow your shop faster.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: ST.inkMid, height: 1.5),
            ),
            ST.s12,
            _PrimaryButton(
              label: '✦  Unlock Premium',
              onTap: _toggleSubscription,
              gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C42)]),
            ),
            ST.s12,
            const TextButton(
              onPressed: null,
              child: Text('Starting at ₱199/month',
                  style: TextStyle(color: ST.inkLight, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  //  SHOP TAB
  // =========================================================================
  Widget _buildShopTab(
      List<SellerProduct> flash,
      List<SellerProduct> regular,
      List<SellerProduct> all,
      List<SellerOrder> orders,
      AuthProvider ap,
      ) {
    final pending = _pendingCount(orders);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero greeting card ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: ST.brandGrad,
              borderRadius: ST.br16,
              boxShadow: ST.shadowBrand,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting(),
                          style: const TextStyle(color: Colors.white60, fontSize: 12, letterSpacing: 0.3)),
                      ST.s4,
                      Text(ap.currentUser?.name ?? 'Seller',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.1)),
                      ST.s8,
                      if (pending > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: ST.br24,
                          ),
                          child: Text('$pending order${pending > 1 ? 's' : ''} awaiting review',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        )
                      else
                        const Text('No pending orders', style: TextStyle(color: Colors.white60, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 30),
                ),
              ],
            ),
          ),
          ST.s16,
          // ── Stats row ───────────────────────────────────────────────────
          Row(
            children: [
              Expanded(child: _buildStatCard('Products', all.length.toString(), Icons.inventory_2_outlined, ST.primary)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Flash Sales', flash.length.toString(), Icons.local_fire_department_rounded, ST.accent)),
            ],
          ),
          ST.s16,
          // ── Plan banner ─────────────────────────────────────────────────
          _buildPlanBanner(ap),
          ST.s24,
          // ── Flash sale section ──────────────────────────────────────────
          if (flash.isNotEmpty) ...[
            _sectionHeader('🔥 Flash Sales', onViewAll: () => setState(() => _selectedIndex = 1)),
            ST.s12,
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: flash.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _buildFlashCard(flash[i]),
              ),
            ),
            ST.s24,
          ],
          // ── Products preview ────────────────────────────────────────────
          _sectionHeader('All Products', onViewAll: () => setState(() => _selectedIndex = 1)),
          ST.s12,
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: regular.length > 4 ? 4 : regular.length,
            itemBuilder: (_, i) => _buildProductGridCard(regular[i]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ST.surface,
        borderRadius: ST.br12,
        boxShadow: ST.shadowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: ST.br8),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: const TextStyle(fontSize: 11, color: ST.inkMid)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanBanner(AuthProvider ap) {
    final subscribed = ap.currentUser!.isSubscribed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: subscribed ? const Color(0xFFFFF8E7) : ST.surface,
        borderRadius: ST.br12,
        border: Border.all(color: subscribed ? const Color(0xFFFFD700) : const Color(0xFFEEEEEE)),
        boxShadow: ST.shadowSm,
      ),
      child: Row(
        children: [
          Icon(
            subscribed ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
            color: subscribed ? const Color(0xFFFFB800) : ST.inkMid,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subscribed ? 'Premium Plan' : 'Free Plan',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: subscribed ? const Color(0xFFB8860B) : ST.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subscribed
                      ? 'Unlimited products · Priority listing · Analytics'
                      : '${_currentCount()}/${_limit()} products used',
                  style: const TextStyle(fontSize: 11, color: ST.inkMid),
                ),
              ],
            ),
          ),
          if (!subscribed)
            _PillButton(label: 'Upgrade', onTap: _toggleSubscription),
        ],
      ),
    );
  }

  Widget _buildFlashCard(SellerProduct product) {
    return Container(
      width: 148,
      decoration: BoxDecoration(
        color: ST.surface,
        borderRadius: ST.br12,
        boxShadow: ST.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: ST.r12),
                child: buildProductImage(product.imageUrl, height: 96, width: 148),
              ),
              Positioned(
                top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: const BoxDecoration(color: ST.accent, borderRadius: ST.br8),
                  child: Text(
                    '${product.discountPercent?.toInt() ?? 0}% OFF',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: ST.ink)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('₱${product.discountedPrice.toStringAsFixed(0)}',
                        style: const TextStyle(color: ST.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                    const SizedBox(width: 4),
                    Text('₱${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: ST.inkLight, fontSize: 10, decoration: TextDecoration.lineThrough)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGridCard(SellerProduct product) {
    return Container(
      decoration: BoxDecoration(
        color: ST.surface,
        borderRadius: ST.br12,
        boxShadow: ST.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: ST.r12),
                child: buildProductImage(product.imageUrl, height: 108, width: double.infinity),
              ),
              if (!product.isAvailable)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: ST.r12),
                    child: Container(
                      color: const Color(0xFF1A1A2E).withValues(alpha: 0.55),
                      child: const Center(
                        child: Text('OUT OF STOCK',
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                      ),
                    ),
                  ),
                ),
              if (product.isFlashSale)
                Positioned(top: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: ST.accent, borderRadius: ST.br8),
                      child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 12),
                    )),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ST.ink)),
                const SizedBox(height: 4),
                if (product.isFlashSale && product.discountPercent != null)
                  Row(
                    children: [
                      Text('₱${product.discountedPrice.toStringAsFixed(0)}',
                          style: const TextStyle(color: ST.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(width: 4),
                      Text('₱${product.price.toStringAsFixed(0)}',
                          style: const TextStyle(color: ST.inkLight, fontSize: 10, decoration: TextDecoration.lineThrough)),
                    ],
                  )
                else
                  Text('₱${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(color: ST.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                Text('Qty: ${product.quantity}',
                    style: const TextStyle(fontSize: 10, color: ST.inkMid)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  //  PRODUCTS TAB
  // =========================================================================
  Widget _buildProductsTab(List<SellerProduct> all) {
    final filtered = _selectedCategory == 'All'
        ? all
        : all.where((p) => p.category == _selectedCategory).toList();

    return Column(
      children: [
        Container(
          color: ST.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final sel = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedCategory = cat); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? ST.primary : ST.bg,
                      borderRadius: ST.br24,
                    ),
                    child: Text(cat,
                        style: TextStyle(
                          color: sel ? Colors.white : ST.inkMid,
                          fontSize: 12,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        )),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (!_canAdd())
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: ST.primaryBg,
              borderRadius: ST.br12,
              border: Border.all(color: ST.primaryDim),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: ST.primary, size: 16),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Product limit reached. Upgrade to add unlimited products.',
                      style: TextStyle(fontSize: 12, color: ST.primary)),
                ),
                _PillButton(label: 'Upgrade', onTap: _toggleSubscription),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${filtered.length} products',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ST.ink)),
                  if (_limit() != null)
                    Text('${_currentCount()}/${_limit()} slots used',
                        style: const TextStyle(fontSize: 11, color: ST.inkMid)),
                ],
              ),
              _PrimaryButton(
                label: '+ Add Product',
                onTap: _canAdd() ? _showAddProductDialog : null,
                compact: true,
              ),
            ],
          ),
        ),
        ST.s12,
        Expanded(
          child: filtered.isEmpty
              ? _emptyState(Icons.inventory_2_outlined, 'No products yet', 'Add your first product above')
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => ST.s8,
            itemBuilder: (_, i) => _buildProductListCard(filtered[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildProductListCard(SellerProduct p) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ST.surface,
        borderRadius: ST.br12,
        boxShadow: ST.shadowSm,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: ST.br8,
            child: buildProductImage(p.imageUrl, width: 64, height: 64),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: ST.ink)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (p.isFlashSale && p.discountPercent != null) ...[
                      Text('₱${p.discountedPrice.toStringAsFixed(0)}',
                          style: const TextStyle(color: ST.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                      const SizedBox(width: 4),
                      Text('₱${p.price.toStringAsFixed(0)}',
                          style: const TextStyle(color: ST.inkLight, fontSize: 10, decoration: TextDecoration.lineThrough)),
                    ] else
                      Text('₱${p.price.toStringAsFixed(0)}',
                          style: const TextStyle(color: ST.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _statusChip(p.isAvailable ? 'In stock' : 'Out of stock', p.isAvailable ? ST.success : ST.danger),
                    if (p.isFlashSale) ...[
                      const SizedBox(width: 6),
                      _statusChip('Flash', ST.accent),
                    ],
                    const Spacer(),
                    Text('Qty ${p.quantity}',
                        style: const TextStyle(fontSize: 10, color: ST.inkMid)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              _IconAction(icon: Icons.edit_outlined, color: ST.primary, onTap: () => _showEditProductDialog(p)),
              const SizedBox(height: 4),
              _IconAction(icon: Icons.delete_outline_rounded, color: ST.danger, onTap: () => _showDeleteDialog(p)),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  //  ANALYTICS TAB
  // =========================================================================
  Widget _buildAnalyticsTab(List<SellerProduct> products, List<SellerOrder> orders) {
    final totalStock = products.fold(0, (s, p) => s + p.quantity);
    final totalSold = _totalSold(orders);
    final totalSales = _monthlySales(orders);
    final pending = _pendingCount(orders);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI grid ─────────────────────────────────────────────────
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _buildKPI('Total Products', products.length.toString(), Icons.inventory_2_outlined, ST.primary),
              _buildKPI('In Stock', totalStock.toString(), Icons.storage_rounded, const Color(0xFF6366F1)),
              _buildKPI('Sold This Month', totalSold.toString(), Icons.shopping_bag_outlined, ST.success),
              _buildKPI('Monthly Revenue', '₱${totalSales.toStringAsFixed(0)}', Icons.payments_outlined, ST.accent),
            ],
          ),
          ST.s20,
          // ── Pending highlight ─────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _selectedIndex = 3),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: ST.brandGrad,
                borderRadius: ST.br16,
                boxShadow: ST.shadowBrand,
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pending Orders',
                          style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 0.3)),
                      ST.s4,
                      Text('$pending',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, height: 1)),
                      ST.s4,
                      const Text('Tap to manage →',
                          style: TextStyle(color: Colors.white60, fontSize: 11)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: ST.br12,
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
          ),
          ST.s20,
          // ── Category breakdown ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: ST.surface,
              borderRadius: ST.br16,
              boxShadow: ST.shadowMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category Breakdown',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ST.ink)),
                ST.s16,
                ...(_categories.skip(1).map((cat) {
                  final count = products.where((p) => p.category == cat).length;
                  final ratio = products.isEmpty ? 0.0 : count / products.length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Text(cat,
                                    style: const TextStyle(fontSize: 13, color: ST.ink, fontWeight: FontWeight.w500))),
                            Text('$count',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ST.primary)),
                          ],
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: ST.br24,
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            backgroundColor: ST.bg,
                            color: ST.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                })).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPI(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ST.surface,
        borderRadius: ST.br12,
        boxShadow: ST.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: ST.br8),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color, height: 1)),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 10, color: ST.inkMid)),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  //  ORDERS TAB
  // =========================================================================
  Widget _buildOrdersTab(List<SellerOrder> orders) {
    final filtered = _selectedOrderFilter == 'All'
        ? orders
        : orders.where((o) => o.status == _selectedOrderFilter).toList();

    return Column(
      children: [
        Container(
          color: ST.surface,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _orderStatuses.map((s) {
                final sel = _selectedOrderFilter == s;
                final count = s == 'All' ? orders.length : orders.where((o) => o.status == s).length;
                return GestureDetector(
                  onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedOrderFilter = s); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? ST.primary : ST.bg,
                      borderRadius: ST.br24,
                    ),
                    child: Row(
                      children: [
                        Text(s,
                            style: TextStyle(
                                color: sel ? Colors.white : ST.inkMid,
                                fontSize: 12,
                                fontWeight: sel ? FontWeight.w700 : FontWeight.w500)),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: sel ? Colors.white.withValues(alpha: 0.25) : ST.inkLight.withValues(alpha: 0.2),
                            borderRadius: ST.br8,
                          ),
                          child: Text('$count',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: sel ? Colors.white : ST.inkMid)),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _emptyState(Icons.receipt_long_outlined, 'No orders', 'Orders will appear here once customers place them')
              : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => ST.s12,
            itemBuilder: (_, i) => _buildOrderCard(filtered[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(SellerOrder order) {
    final (Color statusColor, IconData statusIcon, String statusLabel) = switch (order.status) {
      'Pending'   => (ST.warning,  Icons.schedule_rounded,      'Pending'),
      'Accepted'  => (ST.success,  Icons.check_circle_rounded,  'Accepted'),
      'Rejected'  => (ST.danger,   Icons.cancel_rounded,        'Rejected'),
      'Delivered' => (ST.info,     Icons.local_shipping_rounded,'Delivered'),
      _           => (ST.inkMid,   Icons.info_rounded,          order.status),
    };

    return Container(
      decoration: BoxDecoration(
        color: ST.surface,
        borderRadius: ST.br16,
        boxShadow: ST.shadowSm,
      ),
      child: Column(
        children: [
          // ── header bar ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: ST.r16),
            ),
            child: Row(
              children: [
                Icon(statusIcon, size: 14, color: statusColor),
                const SizedBox(width: 6),
                Text(statusLabel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: statusColor)),
                const Spacer(),
                Text(
                  '${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}',
                  style: const TextStyle(fontSize: 11, color: ST.inkLight),
                ),
              ],
            ),
          ),
          // ── body ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: ST.br8,
                      child: buildProductImage(order.productImage, width: 56, height: 56),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.productName,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: ST.ink)),
                          ST.s4,
                          Text('₱${order.price.toStringAsFixed(0)} × ${order.quantity}',
                              style: const TextStyle(fontSize: 12, color: ST.inkMid)),
                        ],
                      ),
                    ),
                    Text('₱${order.totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ST.ink)),
                  ],
                ),
                ST.s12,
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: ST.bg, borderRadius: ST.br8),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 14, color: ST.inkMid),
                      const SizedBox(width: 6),
                      Text(order.customerName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ST.ink)),
                      const Spacer(),
                      const Icon(Icons.location_on_outlined, size: 14, color: ST.inkMid),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(order.customerAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: ST.inkMid)),
                      ),
                    ],
                  ),
                ),
                ST.s12,
                // ── location button ──────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderTrackingMapScreen(
                          customerName: order.customerName,
                          customerAddress: order.customerAddress,
                          customerLatLng: order.customerLatLng,
                          orderId: order.id,
                          productName: order.productName,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.navigation_rounded, size: 14),
                    label: const Text('View on Map', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ST.primary,
                      side: const BorderSide(color: ST.primaryDim),
                      shape: const RoundedRectangleBorder(borderRadius: ST.br8),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                    ),
                  ),
                ),
                // ── action buttons ───────────────────────────────────
                if (order.status == 'Pending') ...[
                  ST.s8,
                  Row(
                    children: [
                      Expanded(child: _OrderActionButton(
                        label: 'Accept',
                        icon: Icons.check_rounded,
                        color: ST.success,
                        onTap: () => _updateOrder(order.id, 'Accepted', 'Order accepted ✓', ST.success),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _OrderActionButton(
                        label: 'Decline',
                        icon: Icons.close_rounded,
                        color: ST.danger,
                        onTap: () => _updateOrder(order.id, 'Rejected', 'Order declined', ST.danger),
                      )),
                    ],
                  ),
                ],
                if (order.status == 'Accepted') ...[
                  ST.s8,
                  SizedBox(
                    width: double.infinity,
                    child: _OrderActionButton(
                      label: 'Mark as Delivered',
                      icon: Icons.local_shipping_rounded,
                      color: ST.info,
                      onTap: () => _updateOrder(order.id, 'Delivered', 'Marked as delivered 🚚', ST.info),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateOrder(String id, String status, String msg, Color color) {
    Provider.of<OrderProvider>(context, listen: false).updateOrderStatus(id, status);
    _showSnack(msg, color);
  }

  // =========================================================================
  //  SHARED EMPTY STATE
  // =========================================================================
  Widget _emptyState(IconData icon, String title, String sub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(color: ST.primaryBg, shape: BoxShape.circle),
            child: Icon(icon, size: 36, color: ST.primaryDim),
          ),
          ST.s16,
          Text(title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ST.ink)),
          ST.s8,
          Text(sub,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: ST.inkMid)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  REUSABLE BUTTON WIDGETS  (extracted — no more duplicated button styles)
// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool compact;
  final Gradient? gradient;

  const _PrimaryButton({required this.label, this.onTap, this.compact = false, this.gradient});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24, vertical: compact ? 10 : 14),
        decoration: BoxDecoration(
          gradient: onTap != null ? (gradient ?? ST.brandGrad) : null,
          color: onTap == null ? ST.inkLight : null,
          borderRadius: ST.br12,
          boxShadow: onTap != null ? ST.shadowBrand : [],
        ),
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _PillButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: const BoxDecoration(gradient: ST.brandGrad, borderRadius: ST.br24),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconAction({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: ST.br8),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

class _OrderActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _OrderActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: color, borderRadius: ST.br8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SUBSCRIBE DIALOG  (inline, clean)
// ─────────────────────────────────────────────────────────────────────────────

class _SubscribeDialog extends StatelessWidget {
  final VoidCallback onSubscribe;
  const _SubscribeDialog({required this.onSubscribe});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: ST.br24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C42)]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFF8C42).withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6)),
                ],
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 34),
            ),
            ST.s16,
            const Text('Upgrade to Premium',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ST.ink)),
            ST.s8,
            const Text(
              'Analytics, unlimited products,\nand boosted shop visibility.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: ST.inkMid, height: 1.5),
            ),
            ST.s20,
            SizedBox(
              width: double.infinity,
              child: _PrimaryButton(
                label: '✦  Get Premium · ₱199/mo',
                onTap: onSubscribe,
                gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFF8C42)]),
              ),
            ),
            ST.s8,
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe later', style: TextStyle(color: ST.inkMid, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
//  ADD PRODUCT DIALOG
// =============================================================================
class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _priceCtrl    = TextEditingController();
  final _descCtrl     = TextEditingController();
  final _qtyCtrl      = TextEditingController();
  final _discCtrl     = TextEditingController();

  String  _category       = 'Bouquets';
  String? _imagePath;
  bool    _isFlashSale    = false;
  bool    _submitting     = false;

  static const _cats = ['Bouquets', 'Plants', 'Birthday', 'Anniversary', 'Sympathy', 'Romance'];
  final _picker = ImagePicker();

  @override
  void dispose() {
    for (final c in [_nameCtrl, _priceCtrl, _descCtrl, _qtyCtrl, _discCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final f = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
      if (f != null) setState(() => _imagePath = f.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image error: $e'), backgroundColor: ST.danger),
      );
      }
    }
  }

  InputDecoration _field(String label, {IconData? icon}) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: ST.inkMid, fontSize: 13),
    prefixIcon: icon != null ? Icon(icon, color: ST.primaryDim, size: 18) : null,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: const OutlineInputBorder(borderRadius: ST.br12, borderSide: BorderSide(color: Color(0xFFE5E7EB))),
    enabledBorder: const OutlineInputBorder(borderRadius: ST.br12, borderSide: BorderSide(color: Color(0xFFE5E7EB))),
    focusedBorder: const OutlineInputBorder(borderRadius: ST.br12, borderSide: BorderSide(color: ST.primary, width: 1.5)),
    errorBorder: const OutlineInputBorder(borderRadius: ST.br12, borderSide: BorderSide(color: ST.danger)),
    filled: true,
    fillColor: ST.surface,
  );

  @override
  Widget build(BuildContext context) {
    final ap = Provider.of<AuthProvider>(context, listen: false);
    final sp = Provider.of<SellerProvider>(context, listen: false);
    final limit = ap.currentUser!.productLimit;
    final canAdd = limit == null || sp.getProductsBySeller(ap.currentUser!.id).length < limit;

    return Container(
      constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: ST.surface, borderRadius: ST.br24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('New Product',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ST.ink)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: ST.bg, borderRadius: ST.br8),
                      child: const Icon(Icons.close_rounded, size: 18, color: ST.inkMid),
                    ),
                  ),
                ],
              ),
              ST.s20,
              TextFormField(controller: _nameCtrl, decoration: _field('Product name', icon: Icons.shopping_bag_outlined),
                  validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null),
              ST.s12,
              Row(
                children: [
                  Expanded(child: TextFormField(
                      controller: _priceCtrl,
                      decoration: _field('Price (₱)'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null)),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(
                      controller: _qtyCtrl,
                      decoration: _field('Quantity'),
                      keyboardType: TextInputType.number,
                      validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null)),
                ],
              ),
              ST.s12,
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _field('Category', icon: Icons.category_outlined),
                items: _cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              ST.s12,
              // ── image picker ─────────────────────────────────────────
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ST.bg,
                    borderRadius: ST.br12,
                    border: Border.all(
                      color: _imagePath != null ? ST.primary : const Color(0xFFE5E7EB),
                      style: _imagePath == null ? BorderStyle.solid : BorderStyle.solid,
                    ),
                  ),
                  child: _imagePath == null
                      ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 32, color: ST.primaryDim),
                      ST.s8,
                      Text('Tap to add photo',
                          style: TextStyle(fontSize: 12, color: ST.inkMid, fontWeight: FontWeight.w500)),
                    ],
                  )
                      : ClipRRect(
                    borderRadius: ST.br12,
                    child: kIsWeb
                        ? Image.network(_imagePath!, fit: BoxFit.cover, width: double.infinity)
                        : Image.file(File(_imagePath!), fit: BoxFit.cover, width: double.infinity),
                  ),
                ),
              ),
              ST.s12,
              // ── flash sale toggle ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _isFlashSale ? ST.primaryBg : ST.bg,
                  borderRadius: ST.br12,
                  border: Border.all(color: _isFlashSale ? ST.primaryDim : const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department_rounded, color: ST.accent, size: 18),
                        const SizedBox(width: 8),
                        const Text('Flash Sale',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: ST.ink)),
                        const Spacer(),
                        Switch.adaptive(
                          value: _isFlashSale,
                          onChanged: (v) => setState(() => _isFlashSale = v),
                          // ignore: deprecated_member_use
                          activeColor: ST.primary,
                        ),
                      ],
                    ),
                    if (_isFlashSale) ...[
                      ST.s8,
                      TextFormField(
                        controller: _discCtrl,
                        decoration: _field('Discount %'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          final n = double.tryParse(v);
                          if (n == null || n <= 0 || n > 100) return 'Enter 1–100';
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              ),
              ST.s12,
              TextFormField(
                controller: _descCtrl,
                decoration: _field('Description'),
                maxLines: 3,
                validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
              ),
              ST.s20,
              if (!canAdd)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: ST.primaryBg, borderRadius: ST.br8),
                  child: const Text('Product limit reached. Upgrade to continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ST.primary, fontSize: 12, fontWeight: FontWeight.w500)),
                ),
              SizedBox(
                width: double.infinity,
                child: _PrimaryButton(
                  label: _submitting ? 'Adding…' : 'Add Product',
                  onTap: (canAdd && _imagePath != null && !_submitting)
                      ? () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _submitting = true);
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    await Provider.of<SellerProvider>(context, listen: false).addProduct(
                      sellerId: auth.currentUser!.id,
                      sellerName: auth.currentUser!.name,
                      storeName: auth.currentUser!.storeName ?? '',
                      name: _nameCtrl.text,
                      price: double.parse(_priceCtrl.text),
                      description: _descCtrl.text,
                      category: _category,
                      imageUrl: _imagePath!,
                      quantity: int.parse(_qtyCtrl.text),
                      isFlashSale: _isFlashSale,
                      discountPercent: _isFlashSale ? double.parse(_discCtrl.text) : null,
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Product added!'),
                        backgroundColor: ST.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: ST.br12),
                        margin: EdgeInsets.all(16),
                      ));
                    }
                  }
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
//  EDIT PRODUCT DIALOG
// =============================================================================
class EditProductDialog extends StatefulWidget {
  final SellerProduct product;
  const EditProductDialog({Key? key, required this.product}) : super(key: key);

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  late TextEditingController _nameCtrl, _priceCtrl, _descCtrl, _qtyCtrl, _discCtrl;
  late String _category, _imageUrl;
  late bool   _isAvailable, _isFlashSale;

  static const _cats   = ['Bouquets', 'Plants', 'Birthday', 'Anniversary', 'Sympathy', 'Romance'];
  static final _images = List.generate(8, (i) => i < 6 ? 'assets/images/r${i+1}.jpg' : 'assets/images/r${i+1}.png');

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl  = TextEditingController(text: p.name);
    _priceCtrl = TextEditingController(text: p.price.toString());
    _descCtrl  = TextEditingController(text: p.description);
    _qtyCtrl   = TextEditingController(text: p.quantity.toString());
    _discCtrl  = TextEditingController(text: p.discountPercent?.toString() ?? '');
    _category   = p.category;
    _imageUrl   = p.imageUrl;
    _isAvailable = p.isAvailable;
    _isFlashSale = p.isFlashSale;
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _priceCtrl, _descCtrl, _qtyCtrl, _discCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _field(String label, {IconData? icon}) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: ST.inkMid, fontSize: 13),
    prefixIcon: icon != null ? Icon(icon, color: ST.primaryDim, size: 18) : null,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: const OutlineInputBorder(borderRadius: ST.br12, borderSide: BorderSide(color: Color(0xFFE5E7EB))),
    enabledBorder: const OutlineInputBorder(borderRadius: ST.br12, borderSide: BorderSide(color: Color(0xFFE5E7EB))),
    focusedBorder: const OutlineInputBorder(borderRadius: ST.br12, borderSide: BorderSide(color: ST.primary, width: 1.5)),
    filled: true,
    fillColor: ST.surface,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: ST.surface, borderRadius: ST.br24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Product',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: ST.ink)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: ST.bg, borderRadius: ST.br8),
                    child: const Icon(Icons.close_rounded, size: 18, color: ST.inkMid),
                  ),
                ),
              ],
            ),
            ST.s20,
            TextFormField(controller: _nameCtrl, decoration: _field('Name', icon: Icons.shopping_bag_outlined)),
            ST.s12,
            Row(
              children: [
                Expanded(child: TextFormField(controller: _priceCtrl,
                    decoration: _field('Price', icon: Icons.payments_outlined), keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _qtyCtrl,
                    decoration: _field('Quantity'), keyboardType: TextInputType.number)),
              ],
            ),
            ST.s12,
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: _field('Category', icon: Icons.category_outlined),
              items: _cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            ST.s12,
            // ── availability + flash sale ────────────────────────────
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isAvailable = !_isAvailable),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isAvailable ? const Color(0xFFECFDF5) : ST.bg,
                        borderRadius: ST.br12,
                        border: Border.all(color: _isAvailable ? ST.success : const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: _isAvailable ? ST.success : ST.inkLight),
                          const SizedBox(width: 8),
                          Text(_isAvailable ? 'In Stock' : 'Out of Stock',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isAvailable ? ST.success : ST.inkMid)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isFlashSale = !_isFlashSale),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isFlashSale ? const Color(0xFFFFF7ED) : ST.bg,
                        borderRadius: ST.br12,
                        border: Border.all(color: _isFlashSale ? ST.accent : const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_fire_department_rounded,
                              size: 14, color: _isFlashSale ? ST.accent : ST.inkLight),
                          const SizedBox(width: 6),
                          Text('Flash Sale',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isFlashSale ? ST.accent : ST.inkMid)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isFlashSale) ...[
              ST.s12,
              TextFormField(controller: _discCtrl,
                  decoration: _field('Discount %'), keyboardType: TextInputType.number),
            ],
            ST.s12,
            DropdownButtonFormField<String>(
              initialValue: _imageUrl,
              decoration: _field('Image', icon: Icons.image_outlined),
              items: _images.map((img) => DropdownMenuItem(
                value: img,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: ST.br4,
                      child: Image.asset(img, width: 28, height: 28, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 8),
                    Text('Image ${_images.indexOf(img) + 1}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              )).toList(),
              onChanged: (v) => setState(() => _imageUrl = v!),
            ),
            ST.s12,
            TextFormField(controller: _descCtrl, decoration: _field('Description'), maxLines: 3),
            ST.s20,
            SizedBox(
              width: double.infinity,
              child: _PrimaryButton(
                label: 'Save Changes',
                onTap: () async {
                  await Provider.of<SellerProvider>(context, listen: false).updateProduct(
                    productId: widget.product.id,
                    name: _nameCtrl.text,
                    price: double.parse(_priceCtrl.text),
                    description: _descCtrl.text,
                    category: _category,
                    imageUrl: _imageUrl,
                    quantity: int.parse(_qtyCtrl.text),
                    isAvailable: _isAvailable,
                    isFlashSale: _isFlashSale,
                    discountPercent: _discCtrl.text.isEmpty ? null : double.parse(_discCtrl.text),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Product updated'),
                      backgroundColor: ST.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: ST.br12),
                      margin: EdgeInsets.all(16),
                    ));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}