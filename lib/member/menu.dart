import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_class.dart';
import 'cart.dart';
import 'login.dart'; // adjust path if login.dart is in a subfolder

class MenuItem {
  final int productId;
  final String name;
  final double price;
  final String description;
  final String imageUrl;

  const MenuItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
  });
}

class Menu extends StatefulWidget {
  final String initialCategory;
  final int userId;

  const Menu({
    super.key,
    this.initialCategory = 'Set',
    required this.userId,
  });

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  String selectedCategory = 'Set';
  bool _isScrollingFromTap = false;
  bool _isLoading = true;

  static const double _itemHeight  = 135.0;
  static const double _headerHeight = 63.0;

  List<String> categories = [
    'Set',
    'Rice',
    'Noodle',
    'Western Food',
    'Beverage',
  ];

  Map<String, List<MenuItem>> menuItems = {
    'Set': [],
    'Rice': [],
    'Noodle': [],
    'Western Food': [],
    'Beverage': [],
  };

  // Guest = userId == 0 (not logged in)
  bool get _isGuest => widget.userId == 0;

  Future<void> _fetchMenuItems() async {
    try {
      final response = await Supabase.instance.client
          .from('product')
          .select()
          .eq('is_available', true)
          .order('created_at', ascending: true);

      final Map<String, List<MenuItem>> fetchedItems = {
        'Set': [],
        'Rice': [],
        'Noodle': [],
        'Western Food': [],
        'Beverage': [],
      };

      for (final item in response) {
        final category = item['category'] as String;
        if (fetchedItems.containsKey(category)) {
          fetchedItems[category]!.add(MenuItem(
            productId:   item['id']          as int,
            name:        item['name']        ?? '',
            price:       (item['price']      as num).toDouble(),
            description: item['description'] ?? '',
            imageUrl:    item['image_url']   ?? '',
          ));
        }
      }

      setState(() {
        menuItems  = fetchedItems;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching menu items: $e');
      setState(() => _isLoading = false);
    }
  }

  Widget _buildImage(String imageUrl,
      {double width = 110, double height = 110}) {
    if (imageUrl.isEmpty) {
      return Container(
          width: width, height: height, color: const Color(0xFFEEEEEE));
    }
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => SizedBox(
          width: width,
          height: height,
          child: progress == null
              ? child
              : Container(color: const Color(0xFFEEEEEE)),
        ),
        errorBuilder: (_, __, ___) => Container(
            width: width, height: height, color: const Color(0xFFEEEEEE)),
      );
    } else {
      return Image.asset(
        'assets/images/$imageUrl',
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
            width: width, height: height, color: const Color(0xFFEEEEEE)),
      );
    }
  }

  final ScrollController _scrollController = ScrollController();

  final Map<String, GlobalKey> _categoryKeys = {
    'Set':          GlobalKey(),
    'Rice':         GlobalKey(),
    'Noodle':       GlobalKey(),
    'Western Food': GlobalKey(),
    'Beverage':     GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory;
    _scrollController.addListener(_onScroll);
    _fetchMenuItems().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCategory(widget.initialCategory);
      });
    });

    // Init Supabase cart for logged-in users only
    if (!_isGuest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<MenuCartProvider>(context, listen: false)
            .initCart(widget.userId);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _getOffsetForCategory(String category) {
    double offset = 0;
    for (final cat in categories) {
      if (cat == category) break;
      final count = menuItems[cat]?.length ?? 0;
      offset += _headerHeight + (count * _itemHeight);
    }
    return offset;
  }

  void _onScroll() {
    if (_isScrollingFromTap) return;
    for (final category in categories) {
      final key = _categoryKeys[category];
      if (key?.currentContext != null) {
        final box =
        key!.currentContext!.findRenderObject() as RenderBox;
        final pos = box.localToGlobal(Offset.zero);
        if (pos.dy <= 160 && pos.dy > 0) {
          if (selectedCategory != category) {
            setState(() => selectedCategory = category);
          }
        }
      }
    }
  }

  void _scrollToCategory(String category) {
    if (!_scrollController.hasClients) return;
    _isScrollingFromTap = true;
    setState(() => selectedCategory = category);
    final target = _getOffsetForCategory(category)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController
        .animateTo(target,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic)
        .then((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _isScrollingFromTap = false;
      });
    });
  }

  void _showCategoryBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5F5F7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding:
          const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              ...categories.map((category) {
                return ListTile(
                  title: Text(
                    category,
                    style: TextStyle(
                      fontSize: 16,
                      color: selectedCategory == category
                          ? const Color(0xFFCF0000)
                          : Colors.black,
                      fontWeight: selectedCategory == category
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    setState(() => selectedCategory = category);
                    Navigator.pop(context);
                    _scrollToCategory(category);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ── Show login-required dialog ────────────────────────────────
  // Shown when a guest taps "Add to cart"
  void _showLoginRequired() {
    showDialog(
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
                  "Login Required",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Please log in to add items to your cart and place an order.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
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
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Login()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCF0000),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50)),
                          elevation: 0,
                        ),
                        child: const Text("Log In",
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

  // ── Item detail bottom sheet ──────────────────────────────────
  void _showItemDetail(MenuItem item) {
    int quantity = 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5F5F7),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product image
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                      child: _buildImage(item.imageUrl,
                          width: double.infinity, height: 300),
                    ),
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 50,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(
                        'RM ${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 10),
                      Text(item.description,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 24),

                      Row(
                        children: [
                          // Quantity picker (always shown)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                  sigmaX: 20, sigmaY: 20),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  borderRadius:
                                  BorderRadius.circular(50),
                                  border: Border.all(
                                      color:
                                      Colors.white.withOpacity(0.8),
                                      width: 1),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        if (quantity > 1) {
                                          setModalState(() => quantity--);
                                        }
                                      },
                                      icon: const Icon(Icons.remove),
                                    ),
                                    SizedBox(
                                      width: 32,
                                      child: Text('$quantity',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight:
                                              FontWeight.bold)),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          setModalState(() => quantity++),
                                      icon: const Icon(Icons.add),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Add to cart button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                // ── GUEST: block and show login dialog ──
                                if (_isGuest) {
                                  Navigator.pop(context); // close sheet first
                                  _showLoginRequired();
                                  return;
                                }

                                // ── LOGGED IN: add to Supabase cart ──
                                Navigator.pop(context);
                                final provider =
                                Provider.of<MenuCartProvider>(
                                  this.context,
                                  listen: false,
                                );
                                final error = await provider.addToCart(
                                  userId:         widget.userId,
                                  productId:      item.productId,
                                  quantity:       quantity,
                                  addOnSelection: AddOnSelection(),
                                );
                                if (!mounted) return;
                                if (error != null) {
                                  ScaffoldMessenger.of(this.context)
                                      .showSnackBar(SnackBar(
                                    content: Text(error),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                const Color(0xFFCF0000),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              child: Text(
                                // Label changes for guest to signal login is needed
                                _isGuest
                                    ? 'Log in to Order'
                                    : 'Add to cart',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        body: SafeArea(
          child: Stack(
            children: [
              // ── MAIN CONTENT ──────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
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
                                  width: 1),
                            ),
                            child: const Icon(Icons.arrow_back,
                                color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Category dropdown
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GestureDetector(
                      onTap: _showCategoryBottomSheet,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: BackdropFilter(
                          filter:
                          ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            width: 220,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 12.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.8),
                                  width: 1),
                            ),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(selectedCategory,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500)),
                                const Icon(Icons.keyboard_arrow_down),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Loading / item list
                  if (_isLoading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFFCF0000)),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 80),
                        children: categories.map((category) {
                          final items = menuItems[category] ?? [];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                key: _categoryKeys[category],
                                padding: const EdgeInsets.only(
                                    left: 16.0,
                                    top: 24.0,
                                    bottom: 8.0),
                                child: Text(category,
                                    style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFCF0000))),
                              ),

                              // Skeleton placeholders while empty
                              if (items.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 12.0),
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            _skeletonBox(120, 16),
                                            const SizedBox(height: 8),
                                            _skeletonBox(60, 14),
                                            const SizedBox(height: 8),
                                            _skeletonBox(double.infinity, 12),
                                            const SizedBox(height: 4),
                                            _skeletonBox(150, 12),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      _skeletonBox(110, 110,
                                          radius: 12),
                                    ],
                                  ),
                                ),

                              // Menu items
                              ...items.map((item) {
                                return Column(
                                  children: [
                                    SizedBox(
                                      height: _itemHeight,
                                      child: GestureDetector(
                                        onTap: () =>
                                            _showItemDetail(item),
                                        child: Padding(
                                          padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16.0,
                                              vertical: 12.0),
                                          child: Row(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                                  children: [
                                                    Text(item.name,
                                                        style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                            FontWeight
                                                                .bold),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis),
                                                    const SizedBox(
                                                        height: 4),
                                                    Text(
                                                      'RM ${item.price.toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                          FontWeight
                                                              .w500),
                                                    ),
                                                    const SizedBox(
                                                        height: 6),
                                                    Text(
                                                      item.description,
                                                      style: const TextStyle(
                                                          fontSize: 13,
                                                          color:
                                                          Colors.grey),
                                                      maxLines: 2,
                                                      overflow:
                                                      TextOverflow
                                                          .ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              ClipRRect(
                                                borderRadius:
                                                BorderRadius.circular(
                                                    12),
                                                child: _buildImage(
                                                    item.imageUrl),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: Color(0xFFEEEEEE)),
                                  ],
                                );
                              }),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),

              // ── FLOATING CART BAR (logged-in only) ───────────
              // Guests see nothing here — no cart bar at all
              if (!_isGuest)
                Consumer<MenuCartProvider>(
                  builder: (context, provider, _) {
                    final items      = provider.cartItems;
                    final totalQty   = items.fold(0,   (s, i) => s + i.quantity);
                    final totalPrice = items.fold(0.0, (s, i) => s + i.subtotal);

                    if (items.isEmpty) return const SizedBox.shrink();

                    return Positioned(
                      left: 16, right: 16, bottom: 16,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                Cart(userId: widget.userId),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCF0000),
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              // Item count badge
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text('$totalQty',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                ),
                              ),
                              const Text('View your cart',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              Text(
                                'RM ${totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeletonBox(double width, double height,
      {double radius = 4}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.all(Radius.circular(radius)),
        ),
      );
}