// lib/screens/product/product_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/login_popup.dart';
import '../order/place_order_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  void _handleOrderNow(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.currentUser?.userType == 'seller') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sellers cannot place orders. Switch to a buyer account to shop.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (authProvider.isAuthenticated && authProvider.currentUser?.id != 'guest') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlaceOrderScreen(product: product)),
      );
    } else {
      LoginPopup.show(
        context: context,
        onLoginSuccess: () {
          final updatedAuth = Provider.of<AuthProvider>(context, listen: false);
          if (updatedAuth.currentUser?.userType == 'seller') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sellers cannot place orders.'), backgroundColor: Colors.orange),
            );
            return;
          }
          Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceOrderScreen(product: product)));
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Consumer2<ProductProvider, AuthProvider>(
        builder: (context, productProvider, authProvider, child) {
          final florist = productProvider.getFloristById(product.floristId);
          final isSeller = authProvider.currentUser?.userType == 'seller';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: 350,
                      width: double.infinity,
                      child: Image.asset(
                        product.imageUrl,
                        width: double.infinity,
                        height: 350,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 350,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.pink.shade200, Colors.purple.shade200],
                            ),
                          ),
                          child: Center(
                            child: Icon(Icons.local_florist, size: 150, color: Colors.white.withValues(alpha: 0.2)),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), spreadRadius: 2, blurRadius: 10)]),
                        child: Icon(Icons.favorite_border, color: Colors.pink.shade400, size: 24),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(product.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.pink.shade400, Colors.pink.shade300]),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [BoxShadow(color: Colors.pink.withValues(alpha: 0.3), spreadRadius: 2, blurRadius: 10)],
                            ),
                            child: Text('₱${product.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            if (index < product.rating.floor()) {
                              return Icon(Icons.star, size: 18, color: Colors.amber.shade600);
                            } else if (index < product.rating) {
                              return Icon(Icons.star_half, size: 18, color: Colors.amber.shade600);
                            } else {
                              return Icon(Icons.star_border, size: 18, color: Colors.amber.shade600);
                            }
                          }),
                          const SizedBox(width: 8),
                          Text('${product.rating} (${product.totalReviews} reviews)', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          if (florist != null) Navigator.pushNamed(context, '/florist', arguments: florist);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.pink.shade100.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [Colors.pink.shade200, Colors.purple.shade200]),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.store, size: 24, color: Colors.white.withValues(alpha: 0.8)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product.floristName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.verified, size: 12, color: Colors.blue.shade400),
                                        const SizedBox(width: 4),
                                        Text('Verified Florist', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.pink.shade400),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(product.description, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5)),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: product.tags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(20)),
                          child: Text('#$tag', style: TextStyle(fontSize: 12, color: Colors.pink.shade600)),
                        )).toList(),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: product.isAvailable ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Icon(product.isAvailable ? Icons.check_circle : Icons.cancel, size: 20, color: product.isAvailable ? Colors.green : Colors.red),
                            const SizedBox(width: 8),
                            Text(product.isAvailable ? 'In Stock - Ready to deliver' : 'Out of Stock', style: TextStyle(color: product.isAvailable ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      if (authProvider.currentUser?.id == 'guest')
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text('You are browsing as a guest. Login to place orders.', style: TextStyle(color: Colors.orange.shade700, fontSize: 13))),
                            ],
                          ),
                        ),
                      if (isSeller)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
                          child: Row(
                            children: [
                              Icon(Icons.store, color: Colors.blue.shade700, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text('You are logged in as a seller. Switch to a buyer account to purchase items.', style: TextStyle(color: Colors.blue.shade700, fontSize: 13))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 10, offset: const Offset(0, -5))]),
        child: SafeArea(
          child: SizedBox(
            height: 55,
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final isSeller = authProvider.currentUser?.userType == 'seller';
                final isGuest = authProvider.currentUser?.id == 'guest';
                String buttonText = 'Order Now';
                if (isSeller) {
                  buttonText = 'Sellers Cannot Order';
                } else if (isGuest) {
                  buttonText = 'Login to Order';
                }

                return ElevatedButton(
                  onPressed: product.isAvailable && !isSeller ? () => _handleOrderNow(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSeller ? Colors.grey : Colors.pink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isSeller ? Icons.block : Icons.shopping_bag_outlined),
                      const SizedBox(width: 8),
                      Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}