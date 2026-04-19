import 'dart:math';
import 'package:flutter/material.dart';
import '../member/supabase_service.dart';

class PromotionAdd extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const PromotionAdd({super.key, this.existing});

  @override
  State<PromotionAdd> createState() => _PromotionAddState();
}

class _PromotionAddState extends State<PromotionAdd> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _discountValueController =
  TextEditingController();

  String _promoCode = '';
  double _minSpent = 10;
  String _discountType = 'percentage';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isLoading = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      final e = widget.existing!;
      _promoCode = e['promotion_code'] ?? '';
      _nameController.text = e['promotion_name'] ?? '';
      _minSpent = (e['min_spent'] ?? 10).toDouble();
      _discountType = e['discount_type'] ?? 'percentage';
      _discountValueController.text =
          (e['discount_value'] ?? 0).toString();
      _startDate = DateTime.parse(e['start_date']).toLocal();
      _endDate = DateTime.parse(e['end_date']).toLocal();
    } else {
      _promoCode = _generateCode();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _discountValueController.dispose();
    super.dispose();
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random();
    return List.generate(10, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  Future<DateTime?> _pickDate(DateTime initial) async {
    final now = DateTime.now();

    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFFCF0000),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (date == null) return null;

    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Please enter promotion name');
      return;
    }

    final double? discountValue =
    double.tryParse(_discountValueController.text.trim());

    if (discountValue == null || discountValue <= 0) {
      _showSnackBar('Enter valid discount value');
      return;
    }

    if (_discountType == 'percentage' && discountValue > 100) {
      _showSnackBar('Percentage cannot exceed 100%');
      return;
    }

    if (_discountType == 'fixed' && discountValue <= 0) {
      _showSnackBar('Fixed discount must be greater than 0');
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      _showSnackBar('End date must be after start date');
      return;
    }

    setState(() => _isLoading = true);

    String? error;

    if (_isEditing) {
      error = await SupabaseService.updatePromotion(
        promotionId: widget.existing!['promotion_id'],
        promotionName: _nameController.text,
        minSpent: _minSpent,
        discountType: _discountType,
        discountValue: discountValue,
        startDate: _startDate,
        endDate: _endDate,
      );
    } else {
      error = await SupabaseService.createPromotion(
        promotionCode: _promoCode,
        promotionName: _nameController.text,
        minSpent: _minSpent,
        discountType: _discountType,
        discountValue: discountValue,
        startDate: _startDate,
        endDate: _endDate,
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (error != null) {
      _showSnackBar(error);
    } else {
      Navigator.pop(context, true);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFCF0000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFCF0000),
        title: Text(_isEditing ? 'Edit Promotion' : 'Add Promotion'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Promo Code'),
            const SizedBox(height: 8),
            Text(_promoCode,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),

            _sectionLabel('Promotion Name'),
            _textField(_nameController),

            const SizedBox(height: 20),

            _sectionLabel('Minimum Spent (RM)'),
            Row(
              children: [10.0, 50.0, 100.0].map((amount) {
                final selected = _minSpent == amount;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _minSpent = amount),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFCF0000)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'RM ${amount.toInt()}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: selected
                                ? Colors.white
                                : Colors.black),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            _sectionLabel('Discount Type'),
            Row(
              children: [
                _typeButton('percentage', 'Percentage (%)'),
                const SizedBox(width: 10),
                _typeButton('fixed', 'Fixed RM'),
              ],
            ),

            const SizedBox(height: 20),

            _sectionLabel('Discount Value'),
            _textField(_discountValueController,
                number: true),

            const SizedBox(height: 20),

            _sectionLabel('Start Date'),
            _dateButton(_startDate, () async {
              final picked = await _pickDate(_startDate);
              if (picked != null) setState(() => _startDate = picked);
            }),

            const SizedBox(height: 10),

            _sectionLabel('End Date'),
            _dateButton(_endDate, () async {
              final picked = await _pickDate(_endDate);
              if (picked != null) setState(() => _endDate = picked);
            }),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCF0000),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                    color: Colors.white)
                    : const Text('SAVE',
                    style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style:
    const TextStyle(fontWeight: FontWeight.bold),
  );

  Widget _textField(TextEditingController c,
      {bool number = false}) {
    return TextField(
      controller: c,
      keyboardType:
      number ? TextInputType.number : TextInputType.text,
      decoration: const InputDecoration(
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _typeButton(String type, String label) {
    final selected = _discountType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _discountType = type),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFCF0000)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _dateButton(DateTime date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        color: Colors.white,
        child: Text(
          '${date.day}/${date.month}/${date.year}',
        ),
      ),
    );
  }
}