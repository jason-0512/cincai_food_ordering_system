import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'address_selection.dart';

final supabase = Supabase.instance.client;

final userId = 1;

class CartItem {
  final int cartItemId;
  final int productId;
  final int quantity;
  final double subtotal;
  final String productName;

  CartItem({
    required this.cartItemId,
    required this.productId,
    required this.quantity,
    required this.subtotal,
    required this.productName,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartItemId: json['cart_item_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      productName: json['product']?['name'] ?? 'Product',
    );
  }
}

class Payment extends StatefulWidget {
  const Payment({super.key});

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  String _orderType = 'dine_in';
  String _paymentMethod = 'Credit / Debit Card';

  // Delivery options: 'standard' or 'priority'
  String _deliveryOption = 'standard';

  // Selected delivery address
  AddressItem? _selectedAddress;

  List<CartItem> _cartItems = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  double _grossTotal = 0.0;

  static const double _priorityFee = 3.00;
  static const double _standardFee = 0.00;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchCartItems() async {
    try {
      final data = await supabase
          .from('cart_item')
          .select('*, product(*)')
          .eq('cart_id', 1);

      if (mounted) {
        setState(() {
          _cartItems = (data as List)
              .map((item) => CartItem.fromJson(item))
              .toList();
          _grossTotal = _cartItems.fold(0, (sum, item) => sum + item.subtotal);
        });
      }
    } catch (e) {
      debugPrint('Error fetching cart: $e');
    }
  }

  Future<void> _fetchDefaultAddress() async {
    try {
      final data = await supabase
          .from('address')
          .select()
          .eq('user_id', userId)
          .eq('is_default', true)
          .maybeSingle();

      if (mounted && data != null) {
        setState(() => _selectedAddress = AddressItem.fromJson(data));
      }
    } catch (e) {
      debugPrint('Error fetching default address: $e');
    }
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _fetchCartItems(),
      _fetchDefaultAddress(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  double get _sst => _grossTotal * 0.06;
  double get _serviceCharge => _grossTotal * 0.10;
  double get _deliveryFee =>
      _orderType == 'delivery'
          ? (_deliveryOption == 'priority' ? _priorityFee : _standardFee)
          : 0.0;
  double get _totalPayable =>
      _grossTotal + _sst + _serviceCharge + _deliveryFee;

  Future<void> _openAddressSelection() async {
    final result = await Navigator.push<AddressItem>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressSelectionScreen(
          userId: userId,
          currentSelected: _selectedAddress,
        ),
      ),
    );
    if (result != null) {
      setState(() => _selectedAddress = result);
    }
  }

  Widget _summaryRow(String label, String amount, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _paymentOption(String label) {
    final bool isSelected = _paymentMethod == label;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: () => setState(() => _paymentMethod = label),
        splashColor: Colors.grey.withOpacity(0.2),
        leading: Icon(
          isSelected
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          color: isSelected ? const Color(0xFFCF0000) : Colors.grey,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _deliveryOptionTile({
    required String value,
    required String label,
    required String subtitle,
    required String fee,
  }) {
    final bool isSelected = _deliveryOption == value;
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: () => setState(() => _deliveryOption = value),
        splashColor: Colors.grey.withOpacity(0.2),
        leading: Icon(
          isSelected
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
          color: isSelected ? const Color(0xFFCF0000) : Colors.grey,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Text(
          fee,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFFCF0000) : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.8),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                              sigmaX: 20, sigmaY: 20),
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
                              Icons.arrow_back,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'Checkout',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Order Summary ──────────────────────────────
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _glassCard(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_orderType == 'dine_in')
                              const Text(
                                'Table No: 1',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            if (_orderType == 'dine_in')
                              const SizedBox(height: 12),

                            ..._cartItems.map((item) {
                              return Padding(
                                padding:
                                const EdgeInsets.only(bottom: 8.0),
                                child: _summaryRow(
                                  '${item.quantity}x  ${item.productName}',
                                  'RM ${item.subtotal.toStringAsFixed(2)}',
                                  bold: true,
                                ),
                              );
                            }),

                            const Divider(
                                color: Colors.grey, thickness: 0.5),
                            const SizedBox(height: 8),
                            _summaryRow(
                              'Gross Total',
                              'RM ${_grossTotal.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 8),
                            _summaryRow('Discount', 'RM 0.00'),
                            const SizedBox(height: 8),
                            _summaryRow(
                              'SST (6%)',
                              'RM ${_sst.toStringAsFixed(2)}',
                            ),
                            const SizedBox(height: 8),
                            _summaryRow(
                              'Service Charge (10%)',
                              'RM ${_serviceCharge.toStringAsFixed(2)}',
                            ),
                            if (_orderType == 'delivery') ...[
                              const SizedBox(height: 8),
                              _summaryRow(
                                'Delivery Fee',
                                _deliveryFee == 0.00
                                    ? 'Free'
                                    : 'RM ${_deliveryFee.toStringAsFixed(2)}',
                              ),
                            ],
                            const Divider(
                                color: Colors.grey, thickness: 0.5),
                            const SizedBox(height: 8),
                            _summaryRow(
                              'Total Payable',
                              'RM ${_totalPayable.toStringAsFixed(2)}',
                              bold: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Order Type Toggle ──────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _orderType = 'dine_in'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              decoration: BoxDecoration(
                                color: _orderType == 'dine_in'
                                    ? const Color(0xFFCF0000)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: _orderType == 'dine_in'
                                      ? const Color(0xFFCF0000)
                                      : Colors.grey.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Dine-in',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _orderType == 'dine_in'
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _orderType = 'delivery';
                              if (_paymentMethod == 'Pay at Counter') {
                                _paymentMethod = 'Credit / Debit Card';
                              }
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12),
                              decoration: BoxDecoration(
                                color: _orderType == 'delivery'
                                    ? const Color(0xFFCF0000)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: _orderType == 'delivery'
                                      ? const Color(0xFFCF0000)
                                      : Colors.grey.withOpacity(0.4),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Delivery',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: _orderType == 'delivery'
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Delivery Sections (only when delivery) ─────
                    if (_orderType == 'delivery') ...[

                      // Delivery Address
                      const Text(
                        'Delivery Address',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _glassCard(
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            onTap: _openAddressSelection,
                            splashColor: Colors.grey.withOpacity(0.2),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            title: Text(
                              _selectedAddress?.shortAddress ??
                                  'Select an address',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _selectedAddress != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                            subtitle: _selectedAddress != null
                                ? Text(
                              _selectedAddress!.fullSubtitle,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            )
                                : null,
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Delivery Option
                      const Text(
                        'Delivery Option',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _glassCard(
                        child: Column(
                          children: [
                            _deliveryOptionTile(
                              value: 'standard',
                              label: 'Standard',
                              subtitle: '~45 minutes',
                              fee: 'Free',
                            ),
                            Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: Colors.grey.withOpacity(0.3),
                            ),
                            _deliveryOptionTile(
                              value: 'priority',
                              label: 'Priority',
                              subtitle: '~25 minutes',
                              fee: 'RM 3.00',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],

                    // ── Payment Methods ────────────────────────────
                    const Text(
                      'Payment Methods',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _glassCard(
                      child: Column(
                        children: [
                          _paymentOption('Credit / Debit Card'),
                          if (_orderType == 'dine_in') ...[
                            Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: Colors.grey.withOpacity(0.3),
                            ),
                            _paymentOption('Pay at Counter'),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Pay Button ─────────────────────────────────
                    ElevatedButton(
                      onPressed: _isProcessing
                          ? null
                          : () async {
                        // Validate address selected for delivery
                        if (_orderType == 'delivery' &&
                            _selectedAddress == null) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Please select a delivery address.'),
                            ),
                          );
                          return;
                        }
                        if (_paymentMethod ==
                            'Credit / Debit Card') {
                          await _stripePayment();
                        } else if (_paymentMethod ==
                            'Pay at Counter') {
                          await _payAtCounter();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCF0000),
                        disabledBackgroundColor:
                        Colors.grey.withOpacity(0.4),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        'Pay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processOrder({
    required bool paid,
    required String paymentMethod,
    String? stripeIntentId,
  }) async {
    if (_cartItems.isEmpty) throw Exception('Cart is empty');

    final orderRes = await supabase.from('orders').insert({
      'user_id': userId,
      'cart_id': 1,
      'table_number': _orderType == 'dine_in' ? 1 : null,
      'delivery_option': _orderType == 'delivery' ? _deliveryOption : null,
      'address_id': _orderType == 'delivery' ? _selectedAddress?.addressId : null,
      'gross_total': double.parse(_grossTotal.toStringAsFixed(2)),
      'total_amount': double.parse(_totalPayable.toStringAsFixed(2)),
      'status': paid ? 'success' : 'pending',
      'order_type': _orderType,
      'delivery_fee': _deliveryFee,
    }).select().single();

    final orderId = orderRes['order_id'];

    await supabase.from('payment').insert({
      'order_id': orderId,
      'method': paymentMethod,
      'stripe_intent_id': stripeIntentId,
      'amount': double.parse(_totalPayable.toStringAsFixed(2)),
      'status': paid ? 'success' : 'pending',
      'paid_at': paid ? DateTime.now().toIso8601String() : null,
    });

    for (final item in _cartItems) {
      await supabase.from('order_item').insert({
        'order_id': orderId,
        'product_id': item.productId,
        'qty': item.quantity,
        'subtotal': double.parse(item.subtotal.toStringAsFixed(2)),
      });
    }

    await supabase
        .from('cart')
        .update({'cart_status': 'checked_out'})
        .eq('cart_id', 1);
  }

  Future<void> _payAtCounter() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await _processOrder(paid: false, paymentMethod: 'pay_at_counter');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order received. Please pay at counter.')),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Order error: $e');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _stripePayment() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'create-payment-intent',
        body: {
          'amount': (double.parse(_totalPayable.toStringAsFixed(2)) * 100).round(),
          'currency': 'myr',
        },
      );

      final clientSecret = res.data['clientSecret'];
      final intentId = res.data['intentId'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Cincai Food Ordering',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      await _processOrder(
        paid: true,
        paymentMethod: 'card',
        stripeIntentId: intentId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful')),
      );
      Navigator.pop(context);
    } on StripeException catch (e) {
      debugPrint('Stripe exception: $e');
      setState(() => _isProcessing = false);
    } catch (e) {
      debugPrint('Stripe error: $e');
      setState(() => _isProcessing = false);
    }
  }
}