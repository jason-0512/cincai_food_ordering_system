import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

// ─────────────────────────────────────────────
// PromotionItem — local model
// ─────────────────────────────────────────────
class PromotionItem {
  final int    promotionId;
  final String promotionCode;
  final String promotionName;
  final double minSpent;
  final String discountType;   // 'percentage' | 'fixed'
  final double discountValue;
  final DateTime? startDate;
  final DateTime? endDate;

  const PromotionItem({
    required this.promotionId,
    required this.promotionCode,
    required this.promotionName,
    required this.minSpent,
    required this.discountType,
    required this.discountValue,
    this.startDate,
    this.endDate,
  });

  factory PromotionItem.fromJson(Map<String, dynamic> json) {
    return PromotionItem(
      promotionId:   json['promotion_id']   as int,
      promotionCode: json['promotion_code'] as String,
      promotionName: json['promotion_name'] as String,
      minSpent:      (json['min_spent']     as num?)?.toDouble() ?? 0.0,
      discountType:  json['discount_type']  as String,
      discountValue: (json['discount_value'] as num).toDouble(),
      startDate:     json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      endDate:       json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
    );
  }

  String get discountLabel => discountType == 'percentage'
      ? '${discountValue.toStringAsFixed(0)}% off'
      : 'RM ${discountValue.toStringAsFixed(2)} off';

  double computeDiscount(double grossTotal) {
    if (discountType == 'percentage') {
      return grossTotal * (discountValue / 100);
    }
    return discountValue;
  }
}

// ═══════════════════════════════════════════════════════════════
// PromotionSelectionScreen
// ═══════════════════════════════════════════════════════════════
class PromotionSelectionScreen extends StatefulWidget {
  final int    userId;
  final double grossTotal;
  final PromotionItem? currentSelected;

  const PromotionSelectionScreen({
    super.key,
    required this.userId,
    required this.grossTotal,
    this.currentSelected,
  });

  @override
  State<PromotionSelectionScreen> createState() =>
      _PromotionSelectionScreenState();
}

class _PromotionSelectionScreenState extends State<PromotionSelectionScreen> {
  List<PromotionItem> _promotions = [];
  bool _isLoading = true;
  String? _error;

  // Track the locally highlighted promotion
  PromotionItem? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentSelected;
    _fetchPromotions();
  }

  Future<void> _fetchPromotions() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final now = DateTime.now().toIso8601String();

      final data = await _supabase
          .from('promotion')
          .select()
          .eq('is_active', true)
          .or('start_date.is.null,start_date.lte.$now')
          .or('end_date.is.null,end_date.gte.$now')
          .order('discount_value', ascending: false);

      final all = (data as List)
          .map((e) => PromotionItem.fromJson(e))
          .toList();

      final eligible = all
          .where((p) => widget.grossTotal >= p.minSpent)
          .toList();

      if (mounted) {
        setState(() {
          _promotions = eligible;
          _isLoading  = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error     = 'Failed to load promotions: $e';
          _isLoading = false;
        });
      }
    }
  }

  // ── UI Helpers (Matched to Address Selection) ───────────────────────────────

  Widget _glassWrap({required Widget child, bool highlighted = false}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: highlighted
                ? const Color(0xFFCF0000).withOpacity(0.08)
                : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlighted
                  ? const Color(0xFFCF0000)
                  : Colors.white.withOpacity(0.8),
              width: highlighted ? 1.5 : 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _promoCard(PromotionItem promo) {
    final isSelected = _selected?.promotionId == promo.promotionId;
    final discount = promo.computeDiscount(widget.grossTotal);

    return GestureDetector(
      onTap: () => setState(() => _selected = promo),
      child: _glassWrap(
        highlighted: isSelected,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ── Discount badge ──────────
              Container(
                width: 80,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFCF0000),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  promo.discountLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ── Info ────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promo.promotionName,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Code: ${promo.promotionCode}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'You save: RM ${discount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFCF0000)),
                    ),
                  ],
                ),
              ),

              // ── Selection Icon ──────────
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? const Color(0xFFCF0000) : Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
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
            // ── Header (Glass Design) ──────────────────────────────────────────
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
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            width: 54, height: 54,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.8),
                                  width: 1),
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Center(
                    child: Text(
                      'Promotions',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),

            // ── List ────────────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                  : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  if (_promotions.isEmpty)
                    const Center(
                      child: Text(
                        'No promotions available\nfor your current order.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                    )
                  else ...[
                    // "No Promotion" selection option
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = null),
                        child: _glassWrap(
                          highlighted: _selected == null,
                          child: const ListTile(
                            leading: Icon(Icons.do_not_disturb_alt, color: Colors.grey),
                            title: Text('No promotion', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      ),
                    ),

                    // List of Eligible Promos
                    ..._promotions.map((promo) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _promoCard(promo),
                    )),
                  ],
                ],
              ),
            ),

            // ── Confirm Button (Glass Design) ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCF0000),
                  disabledBackgroundColor: Colors.grey.withOpacity(0.4),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: const Text(
                  'Confirm Promo Code',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}