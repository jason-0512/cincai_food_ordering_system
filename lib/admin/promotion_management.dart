import 'package:flutter/material.dart';
import '../member/supabase_service.dart';
import 'promotion_detail.dart';
import 'promotion_add.dart';

class PromotionManagement extends StatefulWidget {
  const PromotionManagement({super.key});

  @override
  State<PromotionManagement> createState() =>
      _PromotionManagementState();
}

class _PromotionManagementState extends State<PromotionManagement> {
  List<Map<String, dynamic>> _promotions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPromotions();
  }

  Future<void> _loadPromotions() async {
    setState(() => _isLoading = true);
    final data = await SupabaseService.getAllPromotions();
    if (!mounted) return;
    setState(() {
      _promotions = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFCF0000),
        foregroundColor: Colors.white,
        title: const Text(
          'Promotions',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPromotions,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(
              color: Color(0xFFCF0000)))
          : _promotions.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        color: const Color(0xFFCF0000),
        onRefresh: _loadPromotions,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(
              16, 16, 16, 100),
          itemCount: _promotions.length,
          itemBuilder: (_, i) =>
              _buildPromoCard(_promotions[i]),
        ),
      ),

      // Add new promotion button at the bottom
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const PromotionAdd()),
              );
              // Reload list when returning from add page
              _loadPromotions();
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Add New Promotion',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCF0000),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined,
              size: 72, color: Colors.grey.withOpacity(0.35)),
          const SizedBox(height: 16),
          const Text(
            'No promotions yet',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap "Add New Promotion" below to create one',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ─── Promotion card (clickable → detail page) ──────────────────────────────

  Widget _buildPromoCard(Map<String, dynamic> promo) {
    final bool isActive = promo['is_active'] == true;
    final String code = promo['promotion_code'] ?? '';
    final String name = promo['promotion_name'] ?? '';
    final double minSpent =
    (promo['min_spent'] as num).toDouble();
    final String discountType =
        promo['discount_type'] ?? 'percentage';
    final double discountValue =
    (promo['discount_value'] as num).toDouble();
    final DateTime endDate =
    DateTime.parse(promo['end_date']).toLocal();

    final String discountLabel = discountType == 'percentage'
        ? '${discountValue.toStringAsFixed(0)}% off'
        : 'RM ${discountValue.toStringAsFixed(2)} off';

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PromotionDetail(promo: promo),
          ),
        );

        if (result == true) {
          _loadPromotions();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? Colors.green.withOpacity(0.35)
                : Colors.grey.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFCF0000).withOpacity(0.08)
                      : Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      discountType == 'percentage'
                          ? '${discountValue.toStringAsFixed(0)}%'
                          : 'RM${discountValue.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? const Color(0xFFCF0000)
                            : Colors.grey,
                      ),
                    ),
                    Text(
                      'OFF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? const Color(0xFFCF0000)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: Color(0xFFCF0000),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$discountLabel  ·  Min RM ${minSpent.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ends ${_fmtDate(endDate)}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Unavailable',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? Colors.green[700]
                            : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Icon(Icons.chevron_right,
                      color: Colors.grey.withOpacity(0.5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }
}