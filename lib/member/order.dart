import 'package:flutter/material.dart';
import 'dart:async';
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
  bool _isFetching = false;

  //Hold the polling timer
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    //Make every 2 seconds for status updates
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) _fetchOrders(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchOrders({bool silent = false}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (!silent) setState(() => _isLoading = true);
    try {
      //Step 1: Get userId from email
      final userResult = await _client
          .from('users')
          .select('id')
          .eq('email', widget.email.trim())
          .maybeSingle();

      if (userResult == null) {
        _isFetching = false;
        setState(() => _isLoading = false);
        return;
      }

      final userId = userResult['id'] as int;

      // Step 2: Get all active orders, join payment to filter sent+paid
      final rawOrders = await _client
          .from('orders')
          .select('*, payment!left(status)')
          .eq('user_id', userId)
          .inFilter('status', ['pending', 'preparing', 'ready', 'sent'])
          .order('created_at', ascending: false);

      // Hide order when order is 'sent' AND payment is 'success'
      final orderResult = (rawOrders as List).where((order) {
        final orderStatus = order['status'] as String?;
        final payments = order['payment'] as List?;
        final paymentSuccess = payments != null &&
            payments.any((p) => p['status'] == 'success');
        if (orderStatus == 'sent' && paymentSuccess) return false;
        return true;
      }).toList();

      //Step 3: For each order, fetch its items
      final List<Map<String, dynamic>> ordersWithItems = [];

      for (final order in orderResult) {
        //Fetch items for this order and product to get name
        final itemResult = await _client
            .from('order_item')
            .select('*, product(name)')
            .eq('order_id', order['order_id']);

        //Build item list with name and ordered quantity only
        final item = (itemResult as List)
            .map(
              (item) => {
            //Get prod name, fallback to Unknown
            'name': item['product']?['name'] ?? 'Unknown',
            //Get ordered quantity
            'quantity': item['qty'] as int,
          },
        )
            .toList();

        //Combine order data with its item list
        ordersWithItems.add({
          //Spread all order columns
          ...order,
          //Add items list to order map
          'items': item,
        });
      }

      if (!mounted) return;

      //Step 4: Save to state and hide spinner
      setState(() {
        //Store order with item to display
        _orders = ordersWithItems;
        _isLoading = false;
      });
      _isFetching = false;
    } catch (e) {
      print('fetchorders errors: $e');
      _isFetching = false;
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  //Cancel order for Pending order only
  Future<void> _cancelOrder(int orderId) async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: AlertDialog(
          backgroundColor: const Color(0xFFF5F5F7),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Cancel Order?',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          content: const Text(
            'Are you sure you want to cancel this order? This action cannot be undone.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
              const Text('No, Keep it', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCF0000),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              child: const Text('Yes, Cancel',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      // Double-check status is still pending before cancelling
      final latest = await _client
          .from('orders')
          .select('status')
          .eq('order_id', orderId)
          .single();

      if (latest['status'] != 'pending') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Order can no longer be cancelled — it is already being prepared.'),
            backgroundColor: Color(0xFFCF0000),
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }

      // Update status to cancelled in Supabase
      await _client
          .from('orders')
          .update({'status': 'cancelled'})
          .eq('order_id', orderId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Order has been cancelled.'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ));
        // Refresh list immediately
        _fetchOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to cancel order: $e'),
          backgroundColor: const Color(0xFFCF0000),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':   return const Color(0xFFFFA000);
      case 'preparing': return const Color(0xFFFF6F00);
      case 'ready':     return const Color(0xFF2E7D32);
      case 'sent':      return Colors.grey;
      default:          return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':   return 'Pending';
      case 'preparing': return 'Preparing';
      case 'ready':     return 'Ready';
      case 'sent':      return 'Sent';
      default:          return 'Unknown';
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  //Close button
                  Align(
                    alignment: Alignment.centerLeft,
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
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
              // Show spinner while fetching
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFCF0000),
                ),
              )
                  : _orders.isEmpty
              // No orders -> show empty state
                  ? _buildEmptyState()
              // Has orders -> show list
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          const Text(
            'Place an order and it will show here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      //How many order card to build
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

        // Only pending orders can be cancelled
        final isPending = status?.toLowerCase() == 'pending';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
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
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //Order ID + Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order['order_id']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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

                      // otal qty + Cancel button row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total $totalQty item(s)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),

                          //Cancel button
                          if (isPending)
                            GestureDetector(
                              // Stop tap from also triggering the card's onTap
                              onTap: () => _cancelOrder(order['order_id'] as int),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCF0000).withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: const Color(0xFFCF0000).withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'Cancel Order',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFCF0000),
                                  ),
                                ),
                              ),
                            ),
                        ],
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