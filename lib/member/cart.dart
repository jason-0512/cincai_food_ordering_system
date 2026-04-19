import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_class.dart';

class Cart extends StatefulWidget {
  final int userId;
  // Guest cart items passed from Menu — key: productId, value: {name, price, quantity}
  final Map<int, Map<String, dynamic>> guestCart;

  const Cart({
    super.key,
    required this.userId,
    this.guestCart = const {},
  });

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  final TextEditingController _noteController = TextEditingController();

  // Local copy of guest cart so we can edit quantity
  late Map<int, Map<String, dynamic>> _localGuestCart;

  // True if user is guest (not logged in)
  bool get _isGuest => widget.userId == 0;

  // Update guest item quantity
  void _updateGuestQty(int productId, int newQty) {
    setState(() {
      if (newQty <= 0) {
        _localGuestCart.remove(productId);
      } else {
        _localGuestCart[productId]!['quantity'] = newQty;
      }
    });
  }

  // Remove guest item
  void _removeGuestItem(int productId) {
    setState(() => _localGuestCart.remove(productId));
  }

  // Guest cart total price
  double get _guestTotal => _localGuestCart.values.fold(
      0.0,
          (sum, item) =>
      sum + (item['price'] as double) * (item['quantity'] as int));

  // Guest cart total quantity
  int get _guestTotalQty => _localGuestCart.values
      .fold(0, (sum, item) => sum + (item['quantity'] as int));

  @override
  void initState() {
    super.initState();
    // Copy guest cart so we can edit locally
    _localGuestCart = widget.guestCart.map(
          (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
    );
    // Only init Supabase cart for logged in users
    if (!_isGuest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<MenuCartProvider>(context, listen: false);
        if (provider.activeCart == null) {
          provider.initCart(widget.userId);
        } else {
          provider.refreshCart();
        }
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // Confirm order for logged in users
  Future<void> _confirmOrder(MenuCartProvider provider) async {
    if (provider.cartItems.isEmpty) return;

    final order = await provider.confirmOrder(
      userId: widget.userId,
      deliveryOption: DeliveryOption.dineIn,
    );

    if (!mounted) return;

    if (order != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #${order.orderId} placed successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to place order.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MenuCartProvider>();
    final items = provider.cartItems;
    final guestItems = _localGuestCart.entries.toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top bar ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(16),
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
                                        width: 1),
                                  ),
                                  child: const Icon(Icons.arrow_back,
                                      color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Center(
                          child: Text('Cart',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black)),
                        ),
                      ],
                    ),
                  ),

                  // ── Item list ─────────────────────────────────
                  Expanded(
                    child: _isGuest
                    // ===== GUEST CART =====
                        ? guestItems.isEmpty
                        ? const Center(
                      child: Text('Your cart is empty.',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey)),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          16, 0, 16, 200),
                      itemCount: guestItems.length,
                      itemBuilder: (context, index) {
                        final entry = guestItems[index];
                        final productId = entry.key;
                        final name =
                        entry.value['name'] as String;
                        final price =
                        entry.value['price'] as double;
                        final quantity =
                        entry.value['quantity'] as int;
                        final subtotal = price * quantity;

                        return Dismissible(
                          key: Key('guest_$productId'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.only(
                                bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius:
                              BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding:
                            const EdgeInsets.only(right: 20),
                            child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 28),
                          ),
                          onDismissed: (_) =>
                              _removeGuestItem(productId),
                          child: Container(
                            margin: const EdgeInsets.only(
                                bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius:
                              BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black
                                        .withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2))
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius:
                                      BorderRadius.circular(
                                          10),
                                    ),
                                    child: Icon(Icons.fastfood,
                                        color:
                                        Colors.red.shade200,
                                        size: 32),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(name,
                                            style: const TextStyle(
                                                fontWeight:
                                                FontWeight.bold,
                                                fontSize: 15)),
                                        const SizedBox(height: 6),
                                        Text(
                                            'RM ${subtotal.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                                color: Color(
                                                    0xFFD32F2F),
                                                fontWeight:
                                                FontWeight.w700,
                                                fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  _QtyPicker(
                                    quantity: quantity,
                                    onChanged: (newQty) =>
                                        _updateGuestQty(
                                            productId, newQty),
                                    minValue: 0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    )
                    // ===== LOGGED IN CART =====
                        : provider.isLoading && items.isEmpty
                        ? const Center(
                        child: CircularProgressIndicator())
                        : items.isEmpty
                        ? const Center(
                      child: Text('Your cart is empty.',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey)),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          16, 0, 16, 200),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Dismissible(
                          key: Key(
                              'item_${item.cartItemId ?? index}'),
                          direction:
                          DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.only(
                                bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius:
                              BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(
                                right: 20),
                            child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 28),
                          ),
                          onDismissed: (_) =>
                              provider.removeCartItem(item),
                          child: _CartItemCard(
                            item: item,
                            onQtyChanged: (qty) =>
                                provider.updateItemQuantity(
                                    item, qty),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // ── Guest checkout panel ──────────────────────────
              if (_isGuest && guestItems.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _CartBottomPanel(
                    noteController: _noteController,
                    totalQty: _guestTotalQty,
                    totalPrice: _guestTotal,
                    isLoading: false,
                    onCheckout: () => Navigator.pop(context),
                  ),
                ),

              // ── Logged in checkout panel ──────────────────────
              if (!_isGuest && items.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _CartBottomPanel(
                    noteController: _noteController,
                    totalQty: items.fold(0, (sum, i) => sum + i.quantity),
                    totalPrice:
                    items.fold(0.0, (sum, i) => sum + i.subtotal),
                    isLoading: provider.isLoading,
                    onCheckout: () => _confirmOrder(provider),
                  ),
                ),

              // ── Empty cart button (disabled) ──────────────────
              if ((_isGuest && guestItems.isEmpty) ||
                  (!_isGuest && items.isEmpty && !provider.isLoading))
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 32,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: Colors.red.shade200,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Proceed to Checkout',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Bottom panel — note field, total, checkout button
// ═══════════════════════════════════════════════════════════════
class _CartBottomPanel extends StatelessWidget {
  final TextEditingController noteController;
  final int totalQty;
  final double totalPrice;
  final bool isLoading;
  final VoidCallback onCheckout;

  const _CartBottomPanel({
    required this.noteController,
    required this.totalQty,
    required this.totalPrice,
    required this.isLoading,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
      const BorderRadius.vertical(top: Radius.circular(16)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4))
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Note field
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  hintText: 'Note to restaurant (optional)',
                  hintStyle: TextStyle(
                      color: Colors.grey.shade400, fontSize: 14),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F7),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
                maxLines: 1,
              ),
              const SizedBox(height: 14),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total ($totalQty item${totalQty == 1 ? "" : "s"})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text('RM ${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Color(0xFFD32F2F))),
                ],
              ),
              const SizedBox(height: 14),

              // Checkout button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : const Text('Proceed to Checkout',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Cart item card — for logged in users
// ═══════════════════════════════════════════════════════════════
class _CartItemCard extends StatelessWidget {
  final CartItemModel item;
  final ValueChanged<int> onQtyChanged;

  const _CartItemCard({
    required this.item,
    required this.onQtyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.product.imageUrl != null
                  ? Image.network(item.product.imageUrl!,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _thumb())
                  : _thumb(),
            ),
            const SizedBox(width: 12),

            // Name / price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  if (item.addOnSelection.summary.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(item.addOnSelection.summary,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                  const SizedBox(height: 6),
                  Text('RM ${item.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Color(0xFFD32F2F),
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ],
              ),
            ),

            // Qty picker — swipe left to delete
            _QtyPicker(
                quantity: item.quantity,
                onChanged: onQtyChanged,
                minValue: 0),
          ],
        ),
      ),
    );
  }

  Widget _thumb() => Container(
    width: 70,
    height: 70,
    color: Colors.red.shade50,
    child: Icon(Icons.fastfood, color: Colors.red.shade200, size: 32),
  );
}

// ═══════════════════════════════════════════════════════════════
// Quantity picker — frosted glass style matching menu
// ═══════════════════════════════════════════════════════════════
class _QtyPicker extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  final int minValue;

  const _QtyPicker(
      {required this.quantity,
        required this.onChanged,
        this.minValue = 0});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
                color: Colors.white.withOpacity(0.8), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: quantity > minValue
                    ? () => onChanged(quantity - 1)
                    : null,
                icon: const Icon(Icons.remove, size: 18),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
              ),
              SizedBox(
                width: 28,
                child: Text('$quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                onPressed: () => onChanged(quantity + 1),
                icon: const Icon(Icons.add, size: 18),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}