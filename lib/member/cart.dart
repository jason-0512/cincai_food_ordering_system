// cart.dart
// Logged-in users only. Guests (userId <= 0) see a login prompt
// and cannot access any cart functionality.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_class.dart';
import 'payment.dart';
import 'login.dart'; // adjust import path if needed

class Cart extends StatefulWidget {
  final int userId;

  const Cart({super.key, required this.userId});

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  final Set<int> _selectedIndices = {};
  bool _multiSelectMode = false;
  final TextEditingController _noteController = TextEditingController();

  bool get _isGuest => widget.userId <= 0;

  @override
  void initState() {
    super.initState();
    // Guests never touch Supabase — nothing to init
    if (!_isGuest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider =
        Provider.of<MenuCartProvider>(context, listen: false);
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

  // ── If guest: show full-screen login prompt instead of cart ──
  @override
  Widget build(BuildContext context) {
    if (_isGuest) return _buildGuestBlock();
    return _buildCart();
  }

  // ════════════════════════════════════════════════════════════════
  // GUEST BLOCK SCREEN
  // ════════════════════════════════════════════════════════════════
  Widget _buildGuestBlock() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar — back button only
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: ClipOval(
                    child: BackdropFilter(
                      filter:
                      ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
                        child: const Icon(Icons.arrow_back,
                            color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Centered content
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Your Cart Awaits',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'Log in to start adding items to your cart, '
                            'track your orders, and enjoy a seamless '
                            'ordering experience.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const Login()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCF0000),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Back to browsing
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Continue Browsing',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // LOGGED-IN CART
  // ════════════════════════════════════════════════════════════════
  Widget _buildCart() {
    return Consumer<MenuCartProvider>(
      builder: (context, provider, _) {
        final items = provider.cartItems;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F7),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildTopBar(provider, items),
                    Expanded(
                      child: provider.isLoading && items.isEmpty
                          ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFCF0000)))
                          : items.isEmpty
                          ? _buildEmptyCart()
                          : _buildItemList(provider, items),
                    ),
                  ],
                ),

                // Bottom checkout panel
                if (items.isNotEmpty)
                  Positioned(
                    left: 0, right: 0, bottom: 0,
                    child: _CartBottomPanel(
                      items:          items,
                      noteController: _noteController,
                      isLoading:      provider.isLoading,
                      onCheckout:     () => _goToPayment(provider),
                    ),
                  ),

                // Disabled checkout when empty
                if (items.isEmpty)
                  Positioned(
                    left: 16, right: 16, bottom: 32,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[700],
                          disabledBackgroundColor:
                          Colors.red.shade200,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Proceed to Checkout',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Top bar ───────────────────────────────────────────────────
  Widget _buildTopBar(
      MenuCartProvider provider, List<CartItemModel> items) {
    return Padding(
      padding: const EdgeInsets.all(16),
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
                    width: 54, height: 54,
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

          // Title + item count badge
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Cart',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                if (items.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCF0000),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${items.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Select / Delete
          Align(
            alignment: Alignment.centerRight,
            child: items.isEmpty
                ? const SizedBox.shrink()
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_multiSelectMode &&
                    _selectedIndices.isNotEmpty)
                  GestureDetector(
                    onTap: () =>
                        _deleteSelected(provider, items),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Remove (${_selectedIndices.length})',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _toggleSelectMode,
                  child: Text(
                    _multiSelectMode ? 'Cancel' : 'Select',
                    style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty cart ────────────────────────────────────────────────
  Widget _buildEmptyCart() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Your cart is empty.',
              style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  // ── Item list with swipe-to-delete ────────────────────────────
  Widget _buildItemList(
      MenuCartProvider provider, List<CartItemModel> items) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 240),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Dismissible(
          key: ValueKey(item.cartItemId),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) async {
            final confirmed = await _showDeleteDialog(1) == true;
            if (confirmed) {
              await provider.removeCartItem(item);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${item.product.name} removed.'),
                  backgroundColor: const Color(0xFFCF0000),
                  behavior: SnackBarBehavior.floating,
                ));
              }
            }
            return confirmed;
          },
          onDismissed: (_) {},
          background: _swipeBackground(),
          child: _CartItemCard(
            item:           item,
            isMultiSelect:  _multiSelectMode,
            isSelected:     _selectedIndices.contains(index),
            onSelectToggle: () => _toggleItemSelect(index),
            onQtyChanged:   (qty) =>
                provider.updateItemQuantity(item, qty),
            onRemove: () =>
                _deleteSingle(provider, item),
            onTap: _multiSelectMode
                ? () => _toggleItemSelect(index)
                : () => _showItemDetail(item),
          ),
        );
      },
    );
  }

  // ── Multi-select ──────────────────────────────────────────────
  void _toggleSelectMode() => setState(() {
    _multiSelectMode = !_multiSelectMode;
    _selectedIndices.clear();
  });

  void _toggleItemSelect(int index) => setState(() {
    _selectedIndices.contains(index)
        ? _selectedIndices.remove(index)
        : _selectedIndices.add(index);
  });

  // ── Delete with confirmation ──────────────────────────────────
  Future<bool?> _showDeleteDialog(int count) {
    return showDialog<bool>(
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
                  "Remove Items",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to remove $count '
                      'item${count == 1 ? '' : 's'} from your cart?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black),
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
                        child: const Text("No",
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
                        child: const Text("Yes",
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
  }

  Future<void> _deleteSelected(
      MenuCartProvider provider, List<CartItemModel> items) async {
    final count     = _selectedIndices.length;
    final confirmed = await _showDeleteDialog(count);
    if (confirmed != true || !mounted) return;

    final toRemove =
    _selectedIndices.map((i) => items[i]).toList();
    await provider.removeMultipleItems(toRemove);
    if (!mounted) return;
    setState(() {
      _selectedIndices.clear();
      _multiSelectMode = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$count item${count == 1 ? '' : 's'} removed from cart.'),
        backgroundColor: const Color(0xFFCF0000),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _deleteSingle(
      MenuCartProvider provider, CartItemModel item) async {
    final confirmed = await _showDeleteDialog(1);
    if (confirmed != true || !mounted) return;
    await provider.removeCartItem(item);
  }

  // ── Item detail sheet ─────────────────────────────────────────
  void _showItemDetail(CartItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemDetailSheet(item: item),
    );
  }

  // ── Navigate to Payment ───────────────────────────────────────
  void _goToPayment(MenuCartProvider provider) {
    final cartId = provider.activeCart?.cartId;
    if (cartId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Payment(
          userId: widget.userId,
          cartId: cartId,
        ),
      ),
    ).then((_) {
      if (mounted) {
        Provider.of<MenuCartProvider>(context, listen: false)
            .initCart(widget.userId);
      }
    });
  }

  // ── Swipe delete background ───────────────────────────────────
  Widget _swipeBackground() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.red.shade700,
      borderRadius: BorderRadius.circular(16),
    ),
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 20),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.delete_outline, color: Colors.white, size: 28),
        SizedBox(height: 4),
        Text('Remove',
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// Cart item card
// ═══════════════════════════════════════════════════════════════
class _CartItemCard extends StatelessWidget {
  final CartItemModel item;
  final bool isMultiSelect;
  final bool isSelected;
  final VoidCallback onSelectToggle;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _CartItemCard({
    required this.item,
    required this.isMultiSelect,
    required this.isSelected,
    required this.onSelectToggle,
    required this.onQtyChanged,
    required this.onRemove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.red.shade300
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (isMultiSelect)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Checkbox(
                    value: isSelected,
                    activeColor: const Color(0xFFCF0000),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                    onChanged: (_) => onSelectToggle(),
                  ),
                ),

              // Product image from assets/images/
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: item.product.localImagePath != null
                    ? Image.asset(
                  item.product.localImagePath!,
                  width: 70, height: 70, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _thumb(),
                )
                    : _thumb(),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.product.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    if (item.product.category != null)
                      Text(item.product.category!,
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12)),
                    const SizedBox(height: 6),
                    Text('RM ${item.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: Color(0xFFCF0000),
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ],
                ),
              ),

              if (!isMultiSelect)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _QtyPicker(
                        quantity:  item.quantity,
                        onChanged: onQtyChanged,
                        minValue:  1),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: onRemove,
                      child: Icon(Icons.delete_outline,
                          color: Colors.red.shade300, size: 22),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumb() => Container(
    width: 70, height: 70,
    color: Colors.red.shade50,
    child: Icon(Icons.fastfood,
        color: Colors.red.shade200, size: 32),
  );
}

// ═══════════════════════════════════════════════════════════════
// Item detail bottom sheet (tap a cart item)
// ═══════════════════════════════════════════════════════════════
class _ItemDetailSheet extends StatelessWidget {
  final CartItemModel item;
  const _ItemDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final p = item.product;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      minChildSize: 0.4,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product image
                    if (p.localImagePath != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
                        child: Image.asset(
                          p.localImagePath!,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        ),
                      )
                    else
                      _placeholder(),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          if (p.category != null)
                            Text(p.category!,
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13)),
                          const SizedBox(height: 6),
                          Text(
                            'RM ${p.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 18,
                                color: Color(0xFFCF0000),
                                fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          if (p.description.isNotEmpty)
                            Text(p.description,
                                style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                    height: 1.5)),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          _infoRow('Qty in cart', '${item.quantity}'),
                          const SizedBox(height: 6),
                          _infoRow(
                            'Subtotal',
                            'RM ${item.subtotal.toStringAsFixed(2)}',
                            valueColor: const Color(0xFFCF0000),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCF0000),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value,
      {Color? valueColor}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, color: Colors.grey)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Colors.black)),
        ],
      );

  Widget _placeholder() => Container(
    height: 220,
    width: double.infinity,
    color: Colors.red.shade50,
    child: Icon(Icons.fastfood,
        color: Colors.red.shade200, size: 72),
  );
}

// ═══════════════════════════════════════════════════════════════
// Bottom checkout panel
// ═══════════════════════════════════════════════════════════════
class _CartBottomPanel extends StatelessWidget {
  final List<CartItemModel> items;
  final TextEditingController noteController;
  final bool isLoading;
  final VoidCallback onCheckout;

  const _CartBottomPanel({
    required this.items,
    required this.noteController,
    required this.isLoading,
    required this.onCheckout,
  });

  double get _grandTotal => items.fold(0.0, (s, i) => s + i.subtotal);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
      const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, -4)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),

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

              // Grand total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total (${items.length} '
                        'item${items.length == 1 ? '' : 's'})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    'RM ${_grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Color(0xFFCF0000)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Checkout button
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFCF0000),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                      width: 22, height: 22,
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
// Quantity picker
// ═══════════════════════════════════════════════════════════════
class _QtyPicker extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  final int minValue;

  const _QtyPicker({
    required this.quantity,
    required this.onChanged,
    this.minValue = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Btn(
          icon: Icons.remove,
          onTap: quantity > minValue
              ? () => onChanged(quantity - 1)
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('$quantity',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold)),
        ),
        _Btn(icon: Icons.add, onTap: () => onChanged(quantity + 1)),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _Btn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: onTap != null
              ? const Color(0xFFCF0000)
              : Colors.grey.shade300,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}