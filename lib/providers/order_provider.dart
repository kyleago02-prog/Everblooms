// lib/providers/order_provider.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/order_model.dart';

// SellerOrder class (for seller's order list)
class SellerOrder {
  final String id;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final String customerName;
  final String customerAddress;
  final LatLng customerLatLng;
  final DateTime orderDate;
  String status; // Pending, Accepted, Rejected, Delivered
  final String floristId;

  SellerOrder({
    required this.id,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.customerName,
    required this.customerAddress,
    required this.customerLatLng,
    required this.orderDate,
    required this.status,
    required this.floristId,
  });

  double get totalAmount => price * quantity;
}

class OrderProvider extends ChangeNotifier {
  // Store both types of orders: buyer orders (Order model) and seller orders (SellerOrder)
  final List<Order> _buyerOrders = [];
  final List<SellerOrder> _sellerOrders = [];

  List<Order> get buyerOrders => List.unmodifiable(_buyerOrders);
  List<SellerOrder> get sellerOrders => List.unmodifiable(_sellerOrders);

  // Add this getter for seller home screen compatibility
  List<SellerOrder> get orders => List.unmodifiable(_sellerOrders);

  // For backward compatibility – returns all buyer orders as List<Order>
  List<Order> getUserOrders(String userId) {
    return _buyerOrders.where((order) => order.userId == userId).toList();
  }

  // Add a new order from buyer (called by PlaceOrderScreen)
  void addOrder(Order order) {
    _buyerOrders.add(order);
    // Also add to seller orders (convert to SellerOrder)
    final sellerOrder = SellerOrder(
      id: order.id,
      productName: order.productName,
      productImage: order.productImage,
      price: order.totalAmount / order.quantity, // approximate original price
      quantity: order.quantity,
      customerName: order.userName,
      customerAddress: order.deliveryAddress,
      customerLatLng: order.customerLatLng ?? const LatLng(6.7621, 125.2891), // fallback
      orderDate: order.orderDate,
      status: 'Pending',
      floristId: order.floristId,
    );
    _sellerOrders.add(sellerOrder);
    notifyListeners();
  }

  // Add a seller order (for testing or manual addition)
  void addSellerOrder(SellerOrder order) {
    _sellerOrders.add(order);
    notifyListeners();
  }

  // Update order status (used by seller)
  void updateOrderStatus(String orderId, String newStatus) {
    final index = _sellerOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _sellerOrders[index].status = newStatus;
      notifyListeners();
    }
  }

  // Helper method for OrdersScreen to get product image from order
  String getProductImage(String productId) {
    // For demo – map product IDs to asset paths
    const Map<String, String> productImages = {
      'prod1': 'assets/images/r1.jpg',
      'prod2': 'assets/images/r2.jpg',
      'prod3': 'assets/images/r3.jpg',
      'prod4': 'assets/images/r4.jpg',
      'prod5': 'assets/images/r5.png',
      'prod6': 'assets/images/r6.jpg',
    };
    return productImages[productId] ?? 'assets/images/placeholder.jpg';
  }

}