// lib/screens/order/place_order_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../data/florist_data.dart';
import '../order_tracking_map_screen.dart';

enum DeliveryMethod { delivery, pickup }

class PlaceOrderScreen extends StatefulWidget {
  final Product product;
  const PlaceOrderScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends State<PlaceOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final int _quantity = 1;
  late TextEditingController _addressController;
  late TextEditingController _messageController;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  DeliveryMethod _deliveryMethod = DeliveryMethod.delivery;

  final List<String> _addressOptions = [
    'Select Address',
    'Digos City Proper', 'Zone I, Digos City', 'Zone II, Digos City', 'Zone III, Digos City',
    'Aplaya, Digos City', 'Davao del Sur, Digos City', 'Goma, Digos City', 'Igpit, Digos City',
    'Kapatagan, Digos City', 'Matti, Digos City', 'San Miguel, Digos City', 'Sulop Road, Digos City',
    'Roxas Street, Digos City', 'Quezon Avenue, Digos City', 'Rizal Avenue, Digos City',
  ];

  String _selectedAddress = '';
  FloristLocation? _storeFlorist;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _storeFlorist = FloristData.getByName(widget.product.floristName);
    if (_storeFlorist == null && FloristData.florists.isNotEmpty) {
      _storeFlorist = FloristData.florists.first;
    }
    final userAddress = authProvider.currentUser?.address ?? '';
    _selectedAddress = _addressOptions.contains(userAddress) ? userAddress : _addressOptions[0];
    _addressController = TextEditingController(text: userAddress);
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: Colors.pink.shade400, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) setState(() => _selectedDate = picked);
  }

  void _navigateToStore() {
    if (_storeFlorist == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store location not available.')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderTrackingMapScreen(
          customerName: 'Current Location',
          customerAddress: _storeFlorist!.name,
          customerLatLng: _storeFlorist!.point,
          orderId: 'PICKUP',
          productName: widget.product.name,
        ),
      ),
    );
  }

  Future<LatLng?> _geocodeAddress(String address) async {
    final hint = address.toLowerCase().contains('philippines') ? address : '$address, Digos City, Philippines';
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {'q': hint, 'format': 'json', 'limit': '1'});
    final resp = await http.get(uri, headers: {'User-Agent': 'EverbloomFloristApp/1.0'});
    if (resp.statusCode == 200) {
      final list = json.decode(resp.body) as List<dynamic>;
      if (list.isNotEmpty) {
        return LatLng(
          double.parse(list[0]['lat'] as String),
          double.parse(list[0]['lon'] as String),
        );
      }
    }
    return null;
  }

  Future<void> _placeOrder() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    String deliveryAddress;
    double deliveryFee = 0.0;
    LatLng? customerLatLng;

    if (_deliveryMethod == DeliveryMethod.delivery) {
      deliveryAddress = _selectedAddress != _addressOptions[0]
          ? _selectedAddress
          : _addressController.text;
      deliveryFee = 50.0;

      customerLatLng = await _geocodeAddress(deliveryAddress);
      if (customerLatLng == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not locate your address. Please try again.'), backgroundColor: Colors.red),
        );
        return;
      }
    } else {
      deliveryAddress = 'Pickup at ${widget.product.floristName}';
      deliveryFee = 0.0;
      customerLatLng = _storeFlorist?.point;
    }

    // Create Order object
    final newOrder = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: authProvider.currentUser!.id,
      userName: authProvider.currentUser!.name,
      productId: widget.product.id,
      productName: widget.product.name,
      productImage: widget.product.imageUrl,
      floristId: widget.product.floristId,
      floristName: widget.product.floristName,
      quantity: _quantity,
      price: widget.product.price,
      totalAmount: widget.product.price * _quantity + deliveryFee,
      deliveryAddress: deliveryAddress,
      deliveryDate: _selectedDate,
      orderDate: DateTime.now(),
      cardMessage: _messageController.text.isEmpty ? null : _messageController.text,
      status: OrderStatus.pending,
      customerLatLng: customerLatLng,
    );

    orderProvider.addOrder(newOrder);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Placed!'),
        content: const Text('Your order has been placed successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // back to product
              Navigator.pop(context); // back to previous
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = widget.product.price * _quantity;
    final deliveryFee = _deliveryMethod == DeliveryMethod.delivery ? 50.0 : 0.0;
    final finalTotal = totalPrice + deliveryFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Order'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.pink.shade400),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12), // reduced from 16
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Summary (smaller)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.pink.shade50, Colors.purple.shade50]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 6)],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 55, height: 55,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.pink.shade200, Colors.purple.shade200]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_florist, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.store, size: 11, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(widget.product.floristName, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₱${widget.product.price.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.pink.shade700)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                          child: Text('In Stock', style: TextStyle(fontSize: 9, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Delivery Method Toggle
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 6)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Delivery Method', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildMethodCard(title: 'Delivery', icon: Icons.delivery_dining, method: DeliveryMethod.delivery, isSelected: _deliveryMethod == DeliveryMethod.delivery, onTap: () => setState(() => _deliveryMethod = DeliveryMethod.delivery))),
                        const SizedBox(width: 10),
                        Expanded(child: _buildMethodCard(title: 'Pickup', icon: Icons.storefront, method: DeliveryMethod.pickup, isSelected: _deliveryMethod == DeliveryMethod.pickup, onTap: () => setState(() => _deliveryMethod = DeliveryMethod.pickup))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_deliveryMethod == DeliveryMethod.delivery) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 6)]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Delivery Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedAddress,
                          decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                          icon: Icon(Icons.arrow_drop_down, color: Colors.pink.shade400),
                          dropdownColor: Colors.white,
                          items: _addressOptions.map((address) => DropdownMenuItem(value: address, child: Text(address, style: TextStyle(color: address == _addressOptions[0] ? Colors.grey.shade500 : const Color(0xFF2D3142), fontSize: 13)))).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedAddress = newValue!;
                              if (newValue != _addressOptions[0]) _addressController.text = newValue;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Or enter custom address',
                          labelStyle: const TextStyle(fontSize: 12),
                          prefixIcon: Icon(Icons.edit_location_alt_outlined, color: Colors.pink.shade400, size: 18),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          filled: true, fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (_selectedAddress == _addressOptions[0] && (value == null || value.isEmpty)) return 'Please select or enter delivery address';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 6)]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pickup Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.pink.shade50, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            Icon(Icons.store, color: Colors.pink.shade400, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.product.floristName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text(_storeFlorist != null ? '${_storeFlorist!.point.latitude.toStringAsFixed(4)}°N, ${_storeFlorist!.point.longitude.toStringAsFixed(4)}°E' : 'Location not available', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _navigateToStore,
                              icon: const Icon(Icons.navigation_rounded, size: 16),
                              label: const Text('Direction', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink.shade400, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 6)]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Delivery Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: Colors.pink.shade400),
                            const SizedBox(width: 10),
                            Expanded(child: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                            Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: Colors.pink.shade50, shape: BoxShape.circle), child: Icon(Icons.arrow_forward_ios, size: 12, color: Colors.pink.shade400)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 6)]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [const Text('Card Message', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)), child: Text('Optional', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)))]),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Other message...',
                        hintStyle: const TextStyle(fontSize: 12),
                        prefixIcon: Icon(Icons.message_outlined, color: Colors.pink.shade400, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        filled: true, fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.pink.shade50, Colors.purple.shade50]), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Subtotal', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                      Text('₱${widget.product.price.toStringAsFixed(2)} × $_quantity', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800, fontSize: 12)),
                    ]),
                    if (_deliveryMethod == DeliveryMethod.delivery) ...[
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('Delivery Fee', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                        Text('₱50.00', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade800, fontSize: 12)),
                      ]),
                    ],
                    const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(thickness: 1, height: 1)),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('₱${finalTotal.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.pink.shade700)),
                    ]),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50, // reduced from 60
                child: ElevatedButton(
                  onPressed: _placeOrder,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 0),
                  child: const Text('Place Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodCard({required String title, required IconData icon, required DeliveryMethod method, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8), // reduced from 12
        decoration: BoxDecoration(
          color: isSelected ? Colors.pink.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.pink.shade400 : Colors.grey.shade300, width: 1.2),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.pink.shade700 : Colors.grey.shade600, size: 24), // reduced from 28
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.pink.shade700 : Colors.grey.shade700, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}