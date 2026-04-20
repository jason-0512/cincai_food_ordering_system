// cart_class.dart
// Models + MenuCartProvider only. No UI. No guest cart logic.
// Guests (userId <= 0) are blocked at the Cart page level.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────
// Supabase credentials
// ─────────────────────────────────────────────
const String supabaseURL = 'https://wyvoeclxjnsxhncxqnrd.supabase.co';
const String supabaseKey = 'sb_secret_j8gYAxH8o8Ply0dq1_3ZGA_blvAk5nI';

// ─────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────
enum DeliveryOption { dineIn, takeaway, delivery }
enum CartStatus { active, checkedOut, cancelled }

// ─────────────────────────────────────────────
// Product  —  DB: id, name, price, description,
//                 category, image_url, is_available, sort_order
// ─────────────────────────────────────────────
class Product {
  final int productId;
  final String name;
  final String description;
  final double price;
  final String? category;
  final String? imageUrl;
  final bool isAvailable;

  Product({
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    this.category,
    this.imageUrl,
    this.isAvailable = true,
  });

  // Full local asset path e.g. assets/images/R1.png
  String? get localImagePath =>
      (imageUrl != null && imageUrl!.isNotEmpty)
          ? 'assets/images/$imageUrl'
          : null;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId:   json['id']           as int,
      name:        json['name']         as String,
      description: json['description']  as String? ?? '',
      price:       (json['price']       as num).toDouble(),
      category:    json['category']     as String?,
      imageUrl:    json['image_url']    as String?,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }
}

// ─────────────────────────────────────────────
// Add-on selection (kept for extensibility)
// ─────────────────────────────────────────────
class AddOnSelection {
  final Map<int, int> radioSelections;
  final Map<int, Set<int>> checkboxSelections;
  final Map<int, String> textSelections;

  AddOnSelection({
    Map<int, int>? radioSelections,
    Map<int, Set<int>>? checkboxSelections,
    Map<int, String>? textSelections,
  })  : radioSelections    = radioSelections    ?? {},
        checkboxSelections = checkboxSelections ?? {},
        textSelections     = textSelections     ?? {};

  String get summary {
    final parts = <String>[];
    radioSelections.forEach((gid, oid) => parts.add('r$gid:$oid'));
    checkboxSelections.forEach(
            (gid, ids) => parts.add('c$gid:${ids.join(",")}'));
    textSelections.forEach(
            (gid, t) { if (t.isNotEmpty) parts.add('t$gid:$t'); });
    return parts.join(' | ');
  }
}

// ─────────────────────────────────────────────
// CartItemModel  —  DB: cart_item_id(auto), created_at(auto),
//                       cart_id, product_id, quantity, subtotal
// ─────────────────────────────────────────────
class CartItemModel {
  final int? cartItemId;
  final int cartId;
  final int productId;
  int quantity;
  double subtotal;
  final DateTime? createdAt;
  final Product product;
  final AddOnSelection addOnSelection;

  CartItemModel({
    this.cartItemId,
    required this.cartId,
    required this.productId,
    required this.quantity,
    required this.subtotal,
    this.createdAt,
    required this.product,
    AddOnSelection? addOnSelection,
  }) : addOnSelection = addOnSelection ?? AddOnSelection();

  factory CartItemModel.fromJson(
      Map<String, dynamic> json, Product product) {
    return CartItemModel(
      cartItemId: json['cart_item_id'] as int?,
      cartId:     json['cart_id']      as int,
      productId:  json['product_id']   as int,
      quantity:   json['quantity']     as int,
      subtotal:   (json['subtotal']    as num).toDouble(),
      createdAt:  json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      product: product,
    );
  }
}

// ─────────────────────────────────────────────
// CartModel  —  DB: cart_id(auto), user_id, cart_status
// ─────────────────────────────────────────────
class CartModel {
  final int cartId;
  final int userId;
  CartStatus status;
  List<CartItemModel> items;

  CartModel({
    required this.cartId,
    required this.userId,
    required this.status,
    this.items = const [],
  });

  double get grandTotal =>
      items.fold(0.0, (sum, i) => sum + i.subtotal);
}

// ═══════════════════════════════════════════════════════════════
// MenuCartProvider
// ═══════════════════════════════════════════════════════════════
class MenuCartProvider extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;

  List<Product>    _products   = [];
  CartModel?       _activeCart;
  bool             _isLoading  = false;
  String?          _error;

  List<Product>       get products      => _products;
  CartModel?          get activeCart    => _activeCart;
  bool                get isLoading     => _isLoading;
  String?             get error         => _error;
  List<CartItemModel> get cartItems     => _activeCart?.items ?? [];
  // Total item quantity — used for the cart badge in Menu / Home
  int get cartItemCount =>
      cartItems.fold(0, (sum, i) => sum + i.quantity);

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void clearError()        { _error = null;  notifyListeners(); }

  // ── READ: products (available only, sorted) ───────────────────
  Future<void> fetchProducts() async {
    _setLoading(true);
    _error = null;
    try {
      final response = await _db
          .from('product')
          .select()
          .eq('is_available', true)
          .order('sort_order', ascending: true);
      _products =
          (response as List).map((j) => Product.fromJson(j)).toList();
      notifyListeners();
    } catch (e) {
      _error = 'fetchProducts error: $e';
      print(_error);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ── READ: cart items with product JOIN ────────────────────────
  Future<void> _fetchCartItems() async {
    if (_activeCart == null) return;
    try {
      final rows = await _db
          .from('cart_item')
          .select('*, product(*)')           // nested JOIN
          .eq('cart_id', _activeCart!.cartId)
          .order('created_at', ascending: true);

      final items = <CartItemModel>[];
      for (final row in (rows as List)) {
        final product =
        Product.fromJson(row['product'] as Map<String, dynamic>);
        items.add(CartItemModel.fromJson(row, product));
      }
      _activeCart!.items = items;
      notifyListeners();
    } catch (e) {
      _error = '_fetchCartItems error: $e';
      print(_error);
      notifyListeners();
    }
  }

  // ── Public refresh ────────────────────────────────────────────
  Future<void> refreshCart() async {
    if (_products.isEmpty) await fetchProducts();
    await _fetchCartItems();
  }

  // ── CREATE / REUSE active cart ────────────────────────────────
  // Only for logged-in users (userId > 0).
  // cart_id is auto-incremented by DB — never pass it in INSERT.
  Future<void> initCart(int userId) async {
    if (userId <= 0) return; // guest blocked

    _setLoading(true);
    _error = null;
    try {
      if (_products.isEmpty) await fetchProducts();

      final existing = await _db
          .from('cart')
          .select()
          .eq('user_id', userId)
          .eq('cart_status', 'active')
          .maybeSingle();

      if (existing != null) {
        _activeCart = CartModel(
          cartId: existing['cart_id'] as int,
          userId: userId,
          status: CartStatus.active,
          items:  [],
        );
      } else {
        // INSERT: only user_id + cart_status; cart_id auto-incremented
        final newCart = await _db
            .from('cart')
            .insert({'user_id': userId, 'cart_status': 'active'})
            .select()
            .single();
        _activeCart = CartModel(
          cartId: newCart['cart_id'] as int,
          userId: userId,
          status: CartStatus.active,
          items:  [],
        );
      }
      await _fetchCartItems();
      notifyListeners();
    } catch (e) {
      _error = 'initCart error: $e';
      print(_error);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ── CREATE / MERGE: add item ──────────────────────────────────
  // Returns null on success, error string on failure.
  // Blocked for guests (userId <= 0).
  Future<String?> addToCart({
    required int userId,
    required int productId,
    required int quantity,
    required AddOnSelection addOnSelection,
  }) async {
    if (userId <= 0) {
      return 'Please log in to add items to cart';
    }

    if (_activeCart == null) await initCart(userId);
    if (_activeCart == null) return 'Failed to create cart';

    _setLoading(true);
    _error = null;
    try {
      final productRes = await _db
          .from('product')
          .select()
          .eq('id', productId)
          .single();
      final product = Product.fromJson(productRes);

      if (!product.isAvailable) {
        return '${product.name} is currently unavailable';
      }

      // MERGE: same product already in cart → UPDATE quantity
      final existing = _activeCart!.items
          .where((i) => i.productId == productId)
          .toList();

      if (existing.isNotEmpty) {
        final item   = existing.first;
        final newQty = item.quantity + quantity;
        final newSub = product.price * newQty;
        await _db
            .from('cart_item')
            .update({'quantity': newQty, 'subtotal': newSub})
            .eq('cart_item_id', item.cartItemId!);
        item.quantity = newQty;
        item.subtotal = newSub;
        notifyListeners();
        return null; // success
      }

      // INSERT new row
      final subtotal = product.price * quantity;
      final res = await _db.from('cart_item').insert({
        'cart_id':    _activeCart!.cartId,
        'product_id': productId,
        'quantity':   quantity,
        'subtotal':   subtotal,
        // cart_item_id → auto-incremented, do NOT include
        // created_at   → auto-generated,    do NOT include
      }).select().single();

      _activeCart!.items.add(CartItemModel(
        cartItemId:    res['cart_item_id'] as int,
        cartId:        _activeCart!.cartId,
        productId:     productId,
        quantity:      quantity,
        subtotal:      subtotal,
        createdAt:     res['created_at'] != null
            ? DateTime.parse(res['created_at'] as String)
            : null,
        product:        product,
        addOnSelection: addOnSelection,
      ));
      notifyListeners();
      return null; // success
    } catch (e) {
      _error = 'addToCart error: $e';
      print(_error);
      notifyListeners();
      return _error;
    } finally {
      _setLoading(false);
    }
  }

  // ── UPDATE: quantity + subtotal ───────────────────────────────
  Future<void> updateItemQuantity(CartItemModel item, int newQty) async {
    if (newQty <= 0) { await removeCartItem(item); return; }
    _setLoading(true);
    _error = null;
    try {
      final newSubtotal = item.product.price * newQty;
      await _db
          .from('cart_item')
          .update({'quantity': newQty, 'subtotal': newSubtotal})
          .eq('cart_item_id', item.cartItemId!);
      item.quantity = newQty;
      item.subtotal = newSubtotal;
      notifyListeners();
    } catch (e) {
      _error = 'updateItemQuantity error: $e';
      print(_error);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ── DELETE: single item ───────────────────────────────────────
  Future<void> removeCartItem(CartItemModel item) async {
    _setLoading(true);
    _error = null;
    try {
      await _db
          .from('cart_item')
          .delete()
          .eq('cart_item_id', item.cartItemId!);
      _activeCart!.items
          .removeWhere((i) => i.cartItemId == item.cartItemId);
      notifyListeners();
    } catch (e) {
      _error = 'removeCartItem error: $e';
      print(_error);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ── DELETE: bulk ──────────────────────────────────────────────
  Future<void> removeMultipleItems(
      List<CartItemModel> itemsToRemove) async {
    if (itemsToRemove.isEmpty) return;
    _setLoading(true);
    _error = null;
    try {
      final ids = itemsToRemove.map((i) => i.cartItemId!).toList();
      await _db
          .from('cart_item')
          .delete()
          .inFilter('cart_item_id', ids);
      _activeCart!.items
          .removeWhere((i) => ids.contains(i.cartItemId));
      notifyListeners();
    } catch (e) {
      _error = 'removeMultipleItems error: $e';
      print(_error);
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ── Mark cart checked-out (local state only) ──────────────────
  // DB cart_status update is done inside payment.dart.
  void markCartCheckedOut() {
    _activeCart = null;
    notifyListeners();
  }
}