import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../member/supabase_service.dart';
import 'promotion_add.dart';

class PromotionDetail extends StatefulWidget {
  final Map<String, dynamic> promo;
  final int adminId;

  const PromotionDetail({
    super.key,
    required this.promo,
    required this.adminId,
  });

  @override
  State<PromotionDetail> createState() => _PromotionDetailState();
}

class _PromotionDetailState extends State<PromotionDetail> {
  late Map<String, dynamic> _promo;
  @override
  void initState() {
    super.initState();
    _promo = Map<String, dynamic>.from(widget.promo);
  }
  String _fmtDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}   ';
  }
  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFCF0000),
      behavior: SnackBarBehavior.floating,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
  Future<void> _handleDiscontinue() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Dialog(
          backgroundColor: const Color(0xFFF5F5F7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Discontinue Promotion',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This will IMMEDIATELY DEACTIVATE the promo code!\n\nYou can re-edit to REACTIVATE it.',
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.black)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50)),
                          elevation: 0,
                        ),
                        child: const Text('Discontinue',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    final String? error = await SupabaseService.discontinuePromotion(
        _promo['promotion_id'] as int, widget.adminId);
    if (!mounted) return;
    if (error != null) {
      _showSnackBar('Error: $error');
    } else {
      Navigator.pop(context, true);
    }
  }
  Future<void> _handleDelete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Dialog(
          backgroundColor: const Color(0xFFF5F5F7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Delete Promotion',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'DELETE "${_promo['promotion_code']}"? This cannot be undone.',
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.black)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCF0000),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50)),
                          elevation: 0,
                        ),
                        child: const Text('Delete',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    final String? error = await SupabaseService.deletePromotion(
        _promo['promotion_id'] as int, widget.adminId);
    if (!mounted) return;
    if (error != null) {
      _showSnackBar('Error: $error');
    } else {
      Navigator.pop(context);
    }
  }
  @override
  Widget build(BuildContext context) {
    final bool isActive = _promo['is_active'] as bool;
    final String code = _promo['promotion_code'] ?? '';
    final String name = _promo['promotion_name'] ?? '';
    final double minSpent = (_promo['min_spent'] as num).toDouble();
    final String discountType = _promo['discount_type'] ?? 'percentage';
    final double discountValue =
    (_promo['discount_value'] as num).toDouble();
    final DateTime startDate =
    DateTime.parse(_promo['start_date']).toLocal();
    final DateTime endDate =
    DateTime.parse(_promo['end_date']).toLocal();
    final DateTime createdAt =
    DateTime.parse(_promo['created_at']).toLocal();
    final String discountLabel = discountType == 'percentage'
        ? '${discountValue.toStringAsFixed(0)}%'
        : 'RM ${discountValue.toStringAsFixed(2)}';
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFCF0000),
        foregroundColor: Colors.white,
        title: const Text('Promotion Details',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive
                      ? Colors.green.withOpacity(0.35)
                      : Colors.grey.withOpacity(0.25),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Unavailable',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? Colors.green[700]
                            : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        color: Color(0xFFCF0000),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFCF0000)
                              .withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$discountLabel OFF',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFCF0000),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.grey.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Details',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  const SizedBox(height: 16),
                  _detailRow('Discount Type',
                      discountType == 'percentage'
                          ? 'Percentage (%)'
                          : 'Fixed Amount (RM)'),
                  _divider(),
                  _detailRow('Discount Value', discountLabel),
                  _divider(),
                  _detailRow('Minimum Spent',
                      'RM ${minSpent.toStringAsFixed(2)}'),
                  _divider(),
                  _detailRow('Start Date', _fmtDate(startDate)),
                  _divider(),
                  _detailRow('End Date', _fmtDate(endDate)),
                  _divider(),
                  _detailRow('Created At', _fmtDate(createdAt)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PromotionAdd(existing: _promo, adminId: widget.adminId),
                  ),
                );
                final updated = await SupabaseService.getAllPromotions();
                if (!mounted) return;
                final refreshed = updated.firstWhere(
                      (p) => p['promotion_id'] == _promo['promotion_id'],
                  orElse: () => _promo,
                );
                setState(() => _promo = refreshed);
                Navigator.pop(context, true);
              },
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              label: const Text('Edit Promotion',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCF0000),
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
            ),
            const SizedBox(height: 12),
            if (isActive)
              OutlinedButton.icon(
                onPressed: _handleDiscontinue,
                icon: const Icon(Icons.pause_circle_outline, size: 18),
                label: const Text('Discontinue',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange[700],
                  minimumSize: const Size(double.infinity, 54),
                  side: BorderSide(color: Colors.orange.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                ),
              ),
            if (isActive) const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _handleDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Delete Promotion',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFCF0000),
                minimumSize: const Size(double.infinity, 54),
                side: BorderSide(color: const Color(0xFFCF0000).withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
          ),
        ],
      ),
    );
  }
  Widget _divider() => Divider(height: 1, color: Colors.grey.withOpacity(0.15));
}