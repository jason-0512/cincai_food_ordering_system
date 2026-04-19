import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_class.dart';
import 'payment.dart';

class Cart extends StatefulWidget {
  final int userId;
  // Guest-mode local cart: productId → {name, price, quantity, imageUrl, category}
  // Null for logged-in users (they use MenuCartProvider).
  final Map<int, Map<String, dynamic>>? guestCart;

  const Cart({
    super.key,
    required this.userId,
    this.guestCart,
  });

  @override
  State<Cart> createState() => _CartState();
}

class _CartState extends State<Cart> {
  final Set<int> _selectedIndices = {};
  bool _multiSelectMode = false;
  final TextEditingController _noteController = TextEditingController();

  // Local mutable copy of guest cart so deletions update the UI
  late Map<int, Map<String, dynamic>> _localGuestCart;

  bool get _isGuest => widget.userId <= 0;

  @override
  void initState() {
    super.initState();
    // Build a mutable copy of the guest cart (or empty map for logged-in)
    _localGuestCart = widget.guestCart != null
        ? Map<int, Map<String, dynamic>>.from(
        widget.guestCart!.map((k, v) =>
            MapEntry(k, Map<String, dynamic>.from(v))))
        : {};

    // For logged-in users only: load cart from Supabase
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

  // ── Guest cart helpers ────────────────────────────────────────
  List<GuestCartItem> get _guestItems => _localGuestCart.entries
      .map((e) => GuestCartItem(
    productId: e.key,
    name:      e.value['name']     as String,
    price:     e.value['price']    as double,
    imageUrl:  e.value['imageUrl'] as String?,
    category:  e.value['category'] as String?,
    quantity:  e.value['quantity'] as int,
  ))
      .toList();

  double get _guestGrandTotal =>
      _guestItems.fold(0.0, (s, i) => s + i.subtotal);

  void _guestUpdateQty(int productId, int newQty) {
    setState(() {
      if (newQty <= 0) {
        _localGuestCart.remove(productId);
      } else {
        _localGuestCart[productId]!['quantity'] = newQty;
      }
    });
  }

  void _guestRemove(int productId) {
    setState(() => _localGuestCart.remove(productId));
  }

  void _guestBulkRemove(List<int> productIds) {
    setState(() {
      for (final id in productIds) {
        _localGuestCart.remove(id);
      }
    });
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

  // ── Delete confirmation dialog ────────────────────────────────
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
                const Text("Remove Items",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you wish to delete $count '
                      'item${count == 1 ? '' : 's'} from your cart?',
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
                        child: const Text("Cancel",
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
                        child: const Text("Yes, Remove",
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

  // ── Bulk delete ───────────────────────────────────────────────
  Future<void> _deleteSelected(
      MenuCartProvider? provider, List items) async {
    final count = _selectedIndices.length;
    final confirmed = await _showDeleteDialog(count);
    if (confirmed != true || !mounted) return;

    if (_isGuest) {
      final ids = _selectedIndices
          .map((i) => _guestItems[i].productId)
          .toList();
      _guestBulkRemove(ids);
    } else {
      final toRemove = _selectedIndices
          .map((i) => (items as List<CartItemModel>)[i])
          .toList();
      await provider!.removeMultipleItems(toRemove);
    }

    if (!mounted) return;
    setState(() {
      _selectedIndices.clear();
      _multiSelectMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          '$count item${count == 1 ? '' : 's'} removed from cart.'),
      backgroundColor: const Color(0xFFCF0000),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Single delete ─────────────────────────────────────────────
  Future<void> _deleteSingle({
    MenuCartProvider? provider,
    CartItemModel? supabaseItem,
    int? guestProductId,
  }) async {
    final confirmed = await _showDeleteDialog(1);
    if (confirmed != true || !mounted) return;
    if (_isGuest && guestProductId != null) {
      _guestRemove(guestProductId);
    } else if (provider != null && supabaseItem != null) {
      await provider.removeCartItem(supabaseItem);
    }
  }

  // ── Show item detail sheet ────────────────────────────────────
  void _showGuestItemDetail(GuestCartItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GuestItemDetailSheet(item: item),
    );
  }

  void _showSupabaseItemDetail(CartItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SupabaseItemDetailSheet(item: item),
    );
  }

  // ── Navigate to Payment ───────────────────────────────────────
  // Only for logged-in users with an active cart.
  void _goToPayment(MenuCartProvider provider) {
    final cartId = provider.activeCart?.cartId;
    if (cartId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Payment(
          userId: widget.userId,  // real user id
          cartId: cartId,         // real cart id from Supabase
        ),
      ),
    ).then((_) {
      // After returning from payment re-init the cart
      if (mounted && !_isGuest) {
        Provider.of<MenuCartProvider>(context, listen: false)
            .initCart(widget.userId);
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isGuest) return _buildGuestCart();
    return _buildSupabaseCart();
  }

  // ════════════════════════════════════════════════════════════════
  // GUEST CART
  // ════════════════════════════════════════════════════════════════
  Widget _buildGuestCart() {
    final items = _guestItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(
                    itemCount: items.length,
                    provider: null,
                    supabaseItems: const [],
                  ),
                  Expanded(
                    child: items.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                      padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 220),
                      itemCount: items.length,
                      itemBuilder: (ctx, index) {
                        final item = items[index];
                        return Dismissible(
                          key: ValueKey(item.productId),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            final ok = await _showDeleteDialog(1);
                            if (ok == true) {
                              _guestRemove(item.productId);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('${item.name} removed.'),
                                  backgroundColor: const Color(0xFFCF0000),
                                  behavior: SnackBarBehavior.floating,
                                ));
                              }
                            }
                            return ok == true;
                          },
                          background: _swipeBackground(),
                          child: _GuestCartCard(
                            item:          item,
                            isMultiSelect: _multiSelectMode,
                            isSelected:
                            _selectedIndices.contains(index),
                            onSelectToggle: () =>
                                _toggleItemSelect(index),
                            onQtyChanged: (qty) =>
                                _guestUpdateQty(item.productId, qty),
                            onRemove: () => _deleteSingle(
                                guestProductId: item.productId),
                            onTap: _multiSelectMode
                                ? () => _toggleItemSelect(index)
                                : () =>
                                _showGuestItemDetail(item),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              if (items.isNotEmpty)
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: _GuestBottomPanel(
                    items:          items,
                    noteController: _noteController,
                    // Guests cannot checkout — prompt login
                    onCheckout: () => _showLoginPrompt(),
                  ),
                ),
              if (items.isEmpty)
                _disabledCheckoutBtn(),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoginPrompt() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please log in to proceed to checkout.'),
        backgroundColor: Color(0xFFCF0000),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // LOGGED-IN (SUPABASE) CART
  // ════════════════════════════════════════════════════════════════
  Widget _buildSupabaseCart() {
    return Consumer<MenuCartProvider>(
      builder: (context, provider, _) {
        final items = provider.cartItems;

        return Scaffold(
            backgroundColor: const Color(0xFFF5F5F7),
            body: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SafeArea(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        _buildTopBar(
                          itemCount: items.length,
                          provider:  provider,
                          supabaseItems: items,
                        ),
                        Expanded(
                          child: provider.isLoading && items.isEmpty
                              ? const Center(
                              child: CircularProgressIndicator())
                              : items.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                16, 0, 16, 220),
                            itemCount: items.length,
                            itemBuilder: (ctx, index) {
                              final item = items[index];
                              return Dismissible(
                                key: ValueKey(item.cartItemId),
                                direction:
                                DismissDirection.endToStart,
                                confirmDismiss: (_) async {
                                  final ok = await _showDeleteDialog(1);
                                  if (ok == true) {
                                    await provider.removeCartItem(item);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('${item.product.name} removed.'),
                                        backgroundColor: const Color(0xFFCF0000),
                                        behavior: SnackBarBehavior.floating,
                                      ));
                                    }
                                  }
                                  return ok == true;
                                },
                                background: _swipeBackground(),
                                child: _SupabaseCartCard(
                                  item:          item,
                                  isMultiSelect: _multiSelectMode,
                                  isSelected:    _selectedIndices
                                      .contains(index),
                                  onSelectToggle: () =>
                                      _toggleItemSelect(index),
                                  onQtyChanged: (qty) =>
                                      provider.updateItemQuantity(
                                          item, qty),
                                  onRemove: () => _deleteSingle(
                                    provider:      provider,
                                    supabaseItem:  item,
                                  ),
                                  onTap: _multiSelectMode
                                      ? () =>
                                      _toggleItemSelect(index)
                                      : () => _showSupabaseItemDetail(
                                      item),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
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
                    if (items.isEmpty) _disabledCheckoutBtn(),
                  ],
                ),
              ),
            ),
            );
        },
    );
  }

  // ── Shared top bar ────────────────────────────────────────────
  Widget _buildTopBar({
    required int itemCount,
    required MenuCartProvider? provider,
    required List supabaseItems,
  }) {
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

          // Title with item count badge
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Cart',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                if (itemCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCF0000),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$itemCount',
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

          // Select / Delete (top-right)
          Align(
            alignment: Alignment.centerRight,
            child: itemCount == 0
                ? const SizedBox.shrink()
                : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_multiSelectMode &&
                    _selectedIndices.isNotEmpty)
                  GestureDetector(
                    onTap: () => _deleteSelected(
                        provider, supabaseItems),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Delete (${_selectedIndices.length})',
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isGuest
                ? 'Your cart is empty.\nLog in to save your cart.'
                : 'Your cart is empty.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

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
        Text('Delete',
            style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _disabledCheckoutBtn() => Positioned(
    left: 16, right: 16, bottom: 32,
    child: SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFCF0000),
          disabledBackgroundColor: Colors.red.shade200,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Text('Proceed to Checkout',
          style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
// GUEST cart card
// ═══════════════════════════════════════════════════════════════
class _GuestCartCard extends StatelessWidget {
  final GuestCartItem item;
  final bool isMultiSelect;
  final bool isSelected;
  final VoidCallback onSelectToggle;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _GuestCartCard({
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
    return _buildCard(
      context:      context,
      isSelected:   isSelected,
      isMultiSelect: isMultiSelect,
      onSelectToggle: onSelectToggle,
      onTap:        onTap,
      image:        item.localImagePath != null
          ? Image.asset(item.localImagePath!,
          width: 70, height: 70, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _thumb())
          : _thumb(),
      name:     item.name,
      category: item.category,
      subtotal: item.subtotal,
      quantity: item.quantity,
      onQtyChanged: onQtyChanged,
      onRemove:     onRemove,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SUPABASE cart card
// ═══════════════════════════════════════════════════════════════
class _SupabaseCartCard extends StatelessWidget {
  final CartItemModel item;
  final bool isMultiSelect;
  final bool isSelected;
  final VoidCallback onSelectToggle;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  const _SupabaseCartCard({
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
    return _buildCard(
      context:      context,
      isSelected:   isSelected,
      isMultiSelect: isMultiSelect,
      onSelectToggle: onSelectToggle,
      onTap:        onTap,
      image:        item.product.localImagePath != null
          ? Image.asset(item.product.localImagePath!,
          width: 70, height: 70, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _thumb())
          : _thumb(),
      name:     item.product.name,
      category: item.product.category,
      subtotal: item.subtotal,
      quantity: item.quantity,
      onQtyChanged: onQtyChanged,
      onRemove:     onRemove,
    );
  }
}

// ── Shared card builder ───────────────────────────────────────
Widget _buildCard({
  required BuildContext context,
  required bool isSelected,
  required bool isMultiSelect,
  required VoidCallback onSelectToggle,
  required VoidCallback onTap,
  required Widget image,
  required String name,
  required String? category,
  required double subtotal,
  required int quantity,
  required ValueChanged<int> onQtyChanged,
  required VoidCallback onRemove,
}) {
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
          isSelected ? Colors.red.shade300 : Colors.transparent,
          width: 1.5,
        ),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: image,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  if (category != null)
                    Text(category,
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 12)),
                  const SizedBox(height: 6),
                  Text('RM ${subtotal.toStringAsFixed(2)}',
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
                      quantity:  quantity,
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
  child: Icon(Icons.fastfood, color: Colors.red.shade200, size: 32),
);

// ═══════════════════════════════════════════════════════════════
// Detail sheets
// ═══════════════════════════════════════════════════════════════
class _GuestItemDetailSheet extends StatelessWidget {
  final GuestCartItem item;
  const _GuestItemDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    return _DetailSheetScaffold(
      imageWidget: item.localImagePath != null
          ? Image.asset(item.localImagePath!,
          height: 220, width: double.infinity, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder())
          : _placeholder(),
      name:      item.name,
      category:  item.category,
      price:     item.price,
      description: '',
      quantity:  item.quantity,
      subtotal:  item.subtotal,
    );
  }
}

class _SupabaseItemDetailSheet extends StatelessWidget {
  final CartItemModel item;
  const _SupabaseItemDetailSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final p = item.product;
    return _DetailSheetScaffold(
      imageWidget: p.localImagePath != null
          ? Image.asset(p.localImagePath!,
          height: 220, width: double.infinity, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder())
          : _placeholder(),
      name:        p.name,
      category:    p.category,
      price:       p.price,
      description: p.description,
      quantity:    item.quantity,
      subtotal:    item.subtotal,
    );
  }
}

class _DetailSheetScaffold extends StatelessWidget {
  final Widget imageWidget;
  final String name;
  final String? category;
  final double price;
  final String description;
  final int quantity;
  final double subtotal;

  const _DetailSheetScaffold({
    required this.imageWidget,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.quantity,
    required this.subtotal,
  });

  @override
  Widget build(BuildContext context) {
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
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                      child: imageWidget,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          if (category != null)
                            Text(category!,
                                style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13)),
                          const SizedBox(height: 6),
                          Text('RM ${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFFCF0000),
                                  fontWeight: FontWeight.w700)),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(description,
                                style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                    height: 1.5)),
                          ],
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          _row('Qty in cart', '$quantity'),
                          const SizedBox(height: 6),
                          _row('Subtotal',
                              'RM ${subtotal.toStringAsFixed(2)}',
                              valueColor: const Color(0xFFCF0000)),
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
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.black)),
      ],
    );
  }
}

Widget _placeholder() => Container(
  height: 220, width: double.infinity,
  color: Colors.red.shade50,
  child: Icon(Icons.fastfood, color: Colors.red.shade200, size: 72),
);

// ═══════════════════════════════════════════════════════════════
// Guest bottom panel (no payment — shows login prompt)
// ═══════════════════════════════════════════════════════════════
class _GuestBottomPanel extends StatelessWidget {
  final List<GuestCartItem> items;
  final TextEditingController noteController;
  final VoidCallback onCheckout;

  const _GuestBottomPanel({
    required this.items,
    required this.noteController,
    required this.onCheckout,
  });

  double get _grandTotal => items.fold(0.0, (s, i) => s + i.subtotal);

  @override
  Widget build(BuildContext context) {
    return _panelContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _handle(),
          _noteField(noteController),
          const SizedBox(height: 14),
          _totalRow(items.length, _grandTotal),
          const SizedBox(height: 8),
          // Guest notice
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(children: [
              Icon(Icons.info_outline,
                  color: Colors.orange.shade700, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Log in to save your cart and checkout.',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          _checkoutBtn(isLoading: false, onCheckout: onCheckout,
              label: 'Log in to Checkout'),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Logged-in bottom panel (links to Payment)
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
    return _panelContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _handle(),
          _noteField(noteController),
          const SizedBox(height: 14),
          _totalRow(items.length, _grandTotal),
          const SizedBox(height: 14),
          _checkoutBtn(isLoading: isLoading, onCheckout: onCheckout),
        ],
      ),
    );
  }
}

// ── Shared panel helpers ──────────────────────────────────────
Widget _panelContainer({required Widget child}) {
  return ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                offset: const Offset(0, -4))
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: child,
      ),
    ),
  );
}

Widget _handle() => Center(
  child: Container(
    width: 36, height: 4,
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2)),
  ),
);

Widget _noteField(TextEditingController controller) => TextField(
  controller: controller,
  decoration: InputDecoration(
    hintText: 'Note to restaurant (optional)',
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
    filled: true,
    fillColor: const Color(0xFFF5F5F7),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none),
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  ),
  maxLines: 1,
);

Widget _totalRow(int count, double grandTotal) => Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text('Total ($count item${count == 1 ? '' : 's'})',
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 15)),
    Text('RM ${grandTotal.toStringAsFixed(2)}',
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: Color(0xFFCF0000))),
  ],
);

Widget _checkoutBtn({
  required bool isLoading,
  required VoidCallback onCheckout,
  String label = 'Proceed to Checkout',
}) =>
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
            width: 22, height: 22,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2))
            : Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );

// ═══════════════════════════════════════════════════════════════
// Quantity picker
// ═══════════════════════════════════════════════════════════════
class _QtyPicker extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  final int minValue;

  const _QtyPicker(
      {required this.quantity,
        required this.onChanged,
        this.minValue = 1});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Btn(
            icon: Icons.remove,
            onTap: quantity > minValue
                ? () => onChanged(quantity - 1)
                : null),
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