import 'package:flutter/material.dart';
import 'dart:ui';

class Payment extends StatefulWidget {
  const Payment({super.key});

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  String _orderType = 'Dine-in';
  String _paymentMethod = 'Credit / Debit Card';
  String _deliveryOption = '';

  // Credit card controllers
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
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

  Widget _cardField({
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.4), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.4), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _paymentOption(String label) {
    final bool isSelected = _paymentMethod == label;
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            onTap: () => setState(() => _paymentMethod = label),
            splashColor: Colors.grey.withOpacity(0.2),
            leading: Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
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
        ),

        // Expand credit card fields when selected
        if (isSelected && label == 'Credit / Debit Card')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _cardField(
                  controller: _cardNumberController,
                  hint: 'Card Number',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _cardField(
                        controller: _expiryController,
                        hint: 'MM/YY',
                        keyboardType: TextInputType.datetime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _cardField(
                        controller: _cvvController,
                        hint: 'CVV',
                        keyboardType: TextInputType.number,
                        obscure: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _cardField(
                  controller: _nameController,
                  hint: 'Name on Card',
                  keyboardType: TextInputType.name,
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Back button
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
                    // Order Summary heading
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Order summary card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(20),
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
                              const Text(
                                'Table No: 1',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _summaryRow('1x  Set A', 'RM 49.90', bold: true),
                              const SizedBox(height: 8),
                              _summaryRow('Gross Total', 'RM 49.90'),
                              const SizedBox(height: 8),
                              _summaryRow('Discount', 'RM 0.00'),
                              const SizedBox(height: 8),
                              _summaryRow('SST (6%)', 'RM 2.99'),
                              const SizedBox(height: 8),
                              _summaryRow('Service Charge (10%)', 'RM 4.99'),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Dine-in / Delivery toggle
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _orderType = 'Dine-in'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _orderType == 'Dine-in'
                                    ? const Color(0xFFCF0000)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: _orderType == 'Dine-in'
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
                                    color: _orderType == 'Dine-in'
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
                              _orderType = 'Delivery';
                              if (_paymentMethod == 'Pay at Counter') {
                                _paymentMethod = 'Credit / Debit Card';
                              }
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _orderType == 'Delivery'
                                    ? const Color(0xFFCF0000)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: _orderType == 'Delivery'
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
                                    color: _orderType == 'Delivery'
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

                    // Show delivery sections only when Delivery is selected
                    if (_orderType == 'Delivery') ...[

                      // Delivery address heading
                      const Text(
                        'Delivery address',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Address card
                      ClipRRect(
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
                            child: Material(
                              color: Colors.transparent,
                              child: ListTile(
                                onTap: () {
                                  // TODO: Navigate to address picker
                                },
                                splashColor: Colors.grey.withOpacity(0.2),
                                title: const Text(
                                  '77  Lorong Lembah Permai 3',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Tanjung Bungah, 11200',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Delivery options heading
                      const Text(
                        'Delivery options',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Delivery options card
                      ClipRRect(
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
                            child: Column(
                              children: [
                                // Priority
                                Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    onTap: () => setState(() => _deliveryOption = 'Priority'),
                                    splashColor: Colors.grey.withOpacity(0.2),
                                    leading: Icon(
                                      _deliveryOption == 'Priority'
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: _deliveryOption == 'Priority'
                                          ? const Color(0xFFCF0000)
                                          : Colors.grey,
                                    ),
                                    title: Row(
                                      children: [
                                        const Text(
                                          'Priority  ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const Text(
                                          '18 mins',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: const Text(
                                      '+ RM 3.00',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),

                                Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.withOpacity(0.3)),

                                // Standard
                                Material(
                                  color: Colors.transparent,
                                  child: ListTile(
                                    onTap: () => setState(() => _deliveryOption = 'Standard'),
                                    splashColor: Colors.grey.withOpacity(0.2),
                                    leading: Icon(
                                      _deliveryOption == 'Standard'
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: _deliveryOption == 'Standard'
                                          ? const Color(0xFFCF0000)
                                          : Colors.grey,
                                    ),
                                    title: Row(
                                      children: [
                                        const Text(
                                          'Standard  ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const Text(
                                          '25-40 mins',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],

                    // Payment methods heading
                    const Text(
                      'Payment Methods',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Payment methods card
                    ClipRRect(
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
                          child: Column(
                            children: [
                              _paymentOption('Credit / Debit Card'),
                              Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.withOpacity(0.3)),
                              _paymentOption('Stripe'),
                              if (_orderType == 'Dine-in') ...[
                                Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.withOpacity(0.3)),
                                _paymentOption('Pay at Counter'),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Pay button inside scroll view
                    ElevatedButton(
                      onPressed: _paymentMethod.isEmpty
                          ? null
                          : () {
                        // TODO: Payment logic here
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCF0000),
                        disabledBackgroundColor: Colors.grey.withOpacity(0.4),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text(
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
}