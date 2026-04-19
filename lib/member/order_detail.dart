import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderDetail extends StatefulWidget {
  final int orderId;

  //True -> payment page show view my orders button
  //False -> myorders page
  final bool fromPayment;

  const OrderDetail({
    super.key,
    required this.orderId,
    this.fromPayment = false,
  });

  @override
  State<OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
  final _cleint = Supabase.instance.client;

  //Store the order data
  Map<String, dynamic>? _order;

  //Store the list of food items in this order
  List<Map<String, dynamic>> _items = [];

  bool _isLoading = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // TODO: replace with real Supabase fetch later
    // For now use dummy data to test UI
    _isLoading = false;
    _order = {
      'order_id': 1,
      'table_number': 5,
      'order_type': 'dine_in',
      'created_at': '2026-04-17T23:00:00+08:00',
      'gross_total': 60.60,
    };
    _items = [
      {'name': 'Lu Rou Fan', 'quantity': 1, 'subtotal': 13.90},
      {'name': 'Taiwanese Sticky Rice', 'quantity': 2, 'subtotal': 32.80},
      {'name': 'Braised Pork Rice', 'quantity': 1, 'subtotal': 13.90},
    ];
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

  // Helper method to build each bill row
  Widget _buildBillRow(String label, String amount) {
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(amount, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
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
              padding: const EdgeInsetsGeometry.all(16),
              child: Stack(
                alignment: .center,
                children: [
                  //Close button - only shows when from MyOrders page
                  if (!widget.fromPayment)
                    Align(
                      alignment: .centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          //Close and go back to MyOrders page
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
                              child: const Icon(
                                Icons.close,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const Center(
                    child: Text(
                      'Order Details',
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
            Expanded(
              child: _isLoading
              // Show spinner while loading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFCF0000),
                ),
              )
                  : _order == null
              // Order not found
                  ? const Center(
                child: Text(
                  'Order not found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              )
              // Show full order details
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    //Calculte SST and Service Charge from gross total
    final grossTotal = (_order!['gross_total'] as num?)?.toDouble() ?? 0.0;
    final discount = 0.0; // TODO: fetch from promotion later
    final sst = grossTotal * 0.06;
    final serviceCharge = grossTotal * 0.10;
    final total = grossTotal - discount + sst + serviceCharge;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          const SizedBox(height: 8),

          //Order Info
          ClipRRect(
            borderRadius: .circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: double.infinity,
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
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      'Order #${_order!['order_id']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: .bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),

                    //Table number + Order type
                    Row(
                      children: [
                        Text(
                          'Table ${_order!['table_number'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),

                        Text(
                          _order!['order_type'] ?? '-',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    //Date and time
                    Text(
                      _formatDate(_order!['created_at']),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          //Item and Bill
          ClipRRect(
            borderRadius: .circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: double.infinity,
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
                  crossAxisAlignment: .start,
                  children: [
                    //Food Item List
                    ..._items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Quantity x Name on left
                            Text(
                              '${item['quantity']}x  ${item['name']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                            // Subtotal on right
                            Text(
                              'RM ${(item['subtotal'] as num).toStringAsFixed(
                                  2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    const Divider(height: 24, color: Color(0xFFEEEEEE)),

                    _buildBillRow(
                      'Gross Total',
                      'RM ${grossTotal.toStringAsFixed(2)}',
                    ),

                    const SizedBox(height: 6),

                    _buildBillRow(
                      'Discount',
                      '- RM ${discount.toStringAsFixed(2)}',
                    ),

                    const SizedBox(height: 6),

                    _buildBillRow(
                      'SST (6%)',
                      'RM ${sst.toStringAsFixed(2)}',
                    ),

                    const SizedBox(height: 6),

                    _buildBillRow(
                      'Service Charge (10%)',
                      'RM ${serviceCharge.toStringAsFixed(2)}',
                    ),

                    const Divider(height: 24, color: Color(0xFFEEEEEE)),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'RM ${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFCF0000),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Only shows when coming from payment page
          if (widget.fromPayment)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: navigate to My Orders page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCF0000),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: const Text(
                  'View My Orders',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
