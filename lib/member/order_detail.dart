import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'order.dart';

class OrderDetail extends StatefulWidget {
  final int orderId;

  //True -> payment page show view my orders button
  //False -> myorders page
  final bool fromPayment;
  final bool showSuccess;
  final String email;

  const OrderDetail({
    super.key,
    required this.orderId,
    this.fromPayment = false,
    this.showSuccess = false,
    this.email='',
  });

  @override
  State<OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
  final _client = Supabase.instance.client;

  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String _email = '';

  @override
  void initState() {
    super.initState();
    _fetchOrder();
    if (widget.showSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful! Your order has been placed.'),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      });
    }
  }

  Future<void> _fetchOrder() async {
    try {
      final orderResult = await _client
          .from('orders')
          .select()
          .eq('order_id', widget.orderId)
          .single();

      final itemsResult = await _client
          .from('order_item')
          .select('*,product(name)')
          .eq('order_id', widget.orderId);

      if (!mounted) return;

      final userResult = await _client
          .from('users')
          .select('email')
          .eq('id', orderResult['user_id'])
          .single();

      setState(() {
        _order = orderResult;
        _email = userResult['email'] as String;
        _items = (itemsResult as List).map((item) {
          return {
            'name':     item['product']?['name'] ?? 'Unknown',
            'quantity': item['qty'] as int,
            'subtotal': (item['subtotal'] as num).toDouble(),
            'is_addon': item['is_addon'] ?? false,
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      final hour = date.hour.toString().padLeft(2, '0');
      final min  = date.minute.toString().padLeft(2, '0');
      return '${date.day} ${months[date.month - 1]} ${date.year}  $hour:$min';
    } catch (_) {
      return '';
    }
  }

  Widget _buildBillRow(String label, String amount, {bool bold = false, Color? amountColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: bold ? Colors.black : Colors.grey)),
        Text(amount,
            style: TextStyle(
                fontSize: 14,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: amountColor ?? (bold ? Colors.black : Colors.grey))),
      ],
    );
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
              padding: const EdgeInsets.all(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!widget.fromPayment)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
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
                      'Order Details',
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
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFCF0000)))
                  : _order == null
                  ? const Center(child: Text('Order not found', style: TextStyle(fontSize: 16, color: Colors.grey)))
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Use values directly from DB — no recalculation
    final grossTotal      = (_order!['gross_total']      as num?)?.toDouble() ?? 0.0;
    final totalAmount     = (_order!['total_amount']     as num?)?.toDouble() ?? 0.0;
    final discountAmount  = (_order!['discounted_amount'] as num?)?.toDouble() ?? 0.0;
    final discountedSub   = (grossTotal - discountAmount).clamp(0.0, double.infinity);
    final sst             = discountedSub * 0.06;
    final serviceCharge   = discountedSub * 0.10;
    final deliveryFee     = (_order!['delivery_fee']     as num?)?.toDouble() ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Order Info card
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${_order!['order_id']}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Table ${_order!['table_number'] ?? '-'}',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _order!['order_type'] ?? '-',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(_order!['created_at']),
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Items + Bill card
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Original items
                    ..._items.where((item) => item['is_addon'] == false).map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item['quantity']}x  ${item['name']}',
                                style: const TextStyle(fontSize: 14, color: Colors.black)),
                            Text('RM ${(item['subtotal'] as num).toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14, color: Colors.black)),
                          ],
                        ),
                      );
                    }),

                    // Add-on items
                    if (_items.any((item) => item['is_addon'] == true)) ...[
                      const Divider(height: 16, color: Color(0xFFEEEEEE)),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFA000).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Text('Add On',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFFFA000))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._items.where((item) => item['is_addon'] == true).map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item['quantity']}x  ${item['name']}',
                                  style: const TextStyle(fontSize: 14, color: Colors.black)),
                              Text('RM ${(item['subtotal'] as num).toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 14, color: Colors.black)),
                            ],
                          ),
                        );
                      }),
                    ],

                    const Divider(height: 24, color: Color(0xFFEEEEEE)),

                    _buildBillRow('Gross Total', 'RM ${grossTotal.toStringAsFixed(2)}'),
                    if (discountAmount > 0) ...[
                      const SizedBox(height: 6),
                      _buildBillRow('Discount', '- RM ${discountAmount.toStringAsFixed(2)}', amountColor: const Color(0xFFCF0000)),
                      const SizedBox(height: 6),
                      _buildBillRow('Subtotal after Discount', 'RM ${discountedSub.toStringAsFixed(2)}'),
                    ],
                    const SizedBox(height: 6),
                    _buildBillRow('SST (6%)', 'RM ${sst.toStringAsFixed(2)}'),
                    const SizedBox(height: 6),
                    _buildBillRow('Service Charge (10%)', 'RM ${serviceCharge.toStringAsFixed(2)}'),
                    if (deliveryFee > 0) ...[
                      const SizedBox(height: 6),
                      _buildBillRow('Delivery Fee', 'RM ${deliveryFee.toStringAsFixed(2)}'),
                    ],

                    const Divider(height: 24, color: Color(0xFFEEEEEE)),

                    _buildBillRow(
                      'Total',
                      'RM ${totalAmount.toStringAsFixed(2)}',
                      bold: true,
                      amountColor: const Color(0xFFCF0000),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (widget.fromPayment)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => Order(email: _email)),
                        (route) => route.isFirst,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCF0000),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                ),
                child: const Text(
                  'View My Orders',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}