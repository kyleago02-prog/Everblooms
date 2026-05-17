// lib/models/order_model.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum OrderStatus {
  pending,
  preparing,
  outForDelivery,
  delivered,
}

extension OrderStatusExtension on OrderStatus {
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.preparing:
        return Colors.blue;
      case OrderStatus.outForDelivery:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
    }
  }

  int get index {
    switch (this) {
      case OrderStatus.pending: return 0;
      case OrderStatus.preparing: return 1;
      case OrderStatus.outForDelivery: return 2;
      case OrderStatus.delivered: return 3;
    }
  }
}

class Order {
  final String id;
  final String userId;
  final String userName;
  final String productId;
  final String productName;
  final String productImage;
  final String floristId;
  final String floristName;
  final int quantity;
  final double price;
  final double totalAmount;
  final String deliveryAddress;
  final DateTime deliveryDate;
  final DateTime orderDate;
  final String? cardMessage;
  OrderStatus status;
  final LatLng? customerLatLng;

  Order({
    required this.id,
    required this.userId,
    required this.userName,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.floristId,
    required this.floristName,
    required this.quantity,
    required this.price,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.deliveryDate,
    required this.orderDate,
    this.cardMessage,
    required this.status,
    this.customerLatLng,
  });
}