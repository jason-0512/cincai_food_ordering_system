import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_detail.dart';

class Order extends StatefulWidget {
  //Pass the logged-in user's email from account page
  final String email;

  const Order({super.key, required this.email});

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  final _client = Supabase.instance.client;

  //Store all orders for this user
  List<Map<String, dynamic>> _orders = [];

  bool _isLoading = true;

  //Hold the realtime connection
  RealtimeChannel? _subscription;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //When pager opens, 2 things:
    //1. Fetch orders from Supabase
    //2. Start listening for realtime status change
    _fetchOrders();
    // _subscribeToOrders(); // uncomment later
  }

  @override
  void dispose() {
    // TODO: implement dispose
    //When page close, cancel realtime connection
    _subscription?.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    // TODO: replace with real Supabase fetch
    setState(() {
      _orders = [
        {
          'order_id': 1,
          'table_number': 5,
          'order_type': 'dine_in',
          'created_at': '2026-04-17T23:00:00+08:00',
          'status': 'Pending',
          'items': [
            {'name': 'Lu Rou Fan', 'quantity': 1},
            {'name': 'Taiwanese Sticky Rice', 'quantity': 2},
            {'name': 'Braised Pork Rice', 'quantity': 1},
          ],
        },
      ];
      _isLoading = false;
    });
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFA000);
      case 'preparing':
        return const Color(0xFFFF6F00);
      case 'ready':
        return const Color(0xFF2E7D32);
      case 'served':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Formats date from Supabase into readable string
  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final hour = date.hour.toString().padLeft(2, '0');
      final min = date.minute.toString().padLeft(2, '0');
      return '${date.day} ${months[date.month - 1]} ${date.year}  $hour:$min';
    } catch (_) {
      return '';
    }
  }

  //Calculate the total order food item quantity
  int _totalFoodQuantity(List items) {
    int total = 0;
    for (final item in items) {
      total += (item['quantity'] as int);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                alignment: .center,
                children: [
                  //Close button
                  Align(
                    alignment: .centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        //Close button and back to account page
                        Navigator.pop(context);
                      },
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                                width: 1,
                              ),
                            ),
                            child: const Icon(Icons.close, color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'My Orders',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: .bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ===== CONTENT =====
            Expanded(
              child: _isLoading
                  // Show spinner while fetching
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFCF0000),
                      ),
                    )
                  : _orders.isEmpty
                  // No orders → show empty state
                  ? _buildEmptyState()
                  // Has orders → show list
                  : _buildOrderList(),
            ),
          ],
        ),
      ),
    );
  }

  //Show when user has no order
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: .center,
        children: [
          const Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: .bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          const Text(
            'Place an order and it will show here.',
            textAlign: .center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      //How many order card to buid
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        //Get current order
        final order = _orders[index];

        //Get status e.g., Pending, Preparing, Ready, Served
        final status = order['status'] as String?;

        //Get color for this status
        final statusColor = _statusColor(status);

        //Get item list for this order
        final items = order['items'] as List;

        //Calculate total order food item quantity
        final totalQty = _totalFoodQuantity(items);

        return Padding(
          padding: const EdgeInsetsGeometry.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              //Navigate to OrderDetail page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetail(
                    orderId: order['order_id'],
                    fromPayment: false,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: .circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20,sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: .circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      //Order ID + Status
                      Row(
                        mainAxisAlignment: .spaceBetween,
                        children: [
                          Text(
                            'Order #${order['order_id']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: .bold,
                              color: Colors.black,
                            ),
                          ),

                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10,vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: .circular(50),
                            ),
                            child: Text(
                              status ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: .w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      //Table No + Order Type
                      Row(
                        children: [
                          Text(
                            'Table No: ${order['table_number']}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            order['order_type'] ?? '-',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      //Date and Time
                      Text(
                        _formatDate(order['created_at']),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      const SizedBox(height: 10),

                      //Food Item List
                      ...items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${item['quantity']}x  ${item['name']}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black,
                            ),
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 15),

                      Text(
                        'Total $totalQty item(s)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
