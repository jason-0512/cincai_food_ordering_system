import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_class.dart';
import 'cart.dart';

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

  static const double _itemHeight = 135.0;
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

  // Guest cart — stores items locally when userId == 0
  // key: productId, value: {name, price, quantity}
  final Map<int, Map<String, dynamic>> _guestCart = {};

  // True if user is a guest (not logged in)
  bool get _isGuest => widget.userId == 0;

  // Total guest cart quantity
  int get _guestTotalQty =>
      _guestCart.values.fold(0, (sum, item) => sum + (item['quantity'] as int));

  // Total guest cart price
  double get _guestTotalPrice => _guestCart.values
      .fold(0.0, (sum, item) => sum + (item['price'] as double) * (item['quantity'] as int));

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
          fetchedItems[category]!.add(
            MenuItem(
              productId: item['id'] as int,
              name: item['name'] ?? '',
              price: (item['price'] as num).toDouble(),
              description: item['description'] ?? '',
              imageUrl: item['image_url'] ?? '',
            ),
          );
        }
      }

      setState(() {
        menuItems = fetchedItems;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching menu items: $e');
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
        loadingBuilder: (context, child, loadingProgress) {
          return SizedBox(
            width: width,
            height: height,
            child: loadingProgress == null
                ? child
                : Container(color: const Color(0xFFEEEEEE)),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
              width: width, height: height, color: const Color(0xFFEEEEEE));
        },
      );
    } else {
      return Image.asset(
        'assets/images/$imageUrl',
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
              width: width, height: height, color: const Color(0xFFEEEEEE));
        },
      );
    }
  }

  final ScrollController _scrollController = ScrollController();

  final Map<String, GlobalKey> _categoryKeys = {
    'Set': GlobalKey(),
    'Rice': GlobalKey(),
    'Noodle': GlobalKey(),
    'Western Food': GlobalKey(),
    'Beverage': GlobalKey(),
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

    // Only init Supabase cart for logged in users
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
        final RenderBox renderBox =
        key!.currentContext!.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        if (position.dy <= 160 && position.dy > 0) {
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
    final targetOffset = _getOffsetForCategory(category)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController
        .animateTo(targetOffset,
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
              }).toList(),
            ],
          ),
        );
      },
    );
  }

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
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('RM ${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 10),
                      Text(item.description,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey)),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                  sigmaX: 20, sigmaY: 20),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.8),
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
                                              fontWeight: FontWeight.bold)),
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
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                // Close modal first
                                Navigator.pop(context);

                                if (_isGuest) {
                                  // Guest — store items locally in _guestCart
                                  setState(() {
                                    if (_guestCart.containsKey(item.productId)) {
                                      _guestCart[item.productId]!['quantity'] =
                                          (_guestCart[item.productId]!['quantity'] as int) + quantity;
                                    } else {
                                      _guestCart[item.productId] = {
                                        'name': item.name,
                                        'price': item.price,
                                        'quantity': quantity,
                                      };
                                    }
                                  });
                                } else {
                                  // Logged in — add to Supabase cart via provider
                                  final provider =
                                  Provider.of<MenuCartProvider>(
                                    this.context,
                                    listen: false,
                                  );
                                  await provider.addToCart(
                                    userId: widget.userId,
                                    productId: item.productId,
                                    quantity: quantity,
                                    addOnSelection: AddOnSelection(),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFCF0000),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              child: const Text('Add to cart',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
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

              // ===== MAIN CONTENT =====
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
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
                                  width: 1),
                            ),
                            child: const Icon(Icons.arrow_back,
                                color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Dropdown
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GestureDetector(
                      onTap: _showCategoryBottomSheet,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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

                  // Loading or List
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
                                    left: 16.0, top: 24.0, bottom: 8.0),
                                child: Text(category,
                                    style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFCF0000))),
                              ),
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
                                            Container(
                                                width: 120,
                                                height: 16,
                                                decoration: const BoxDecoration(
                                                    color: Color(0xFFEEEEEE),
                                                    borderRadius: BorderRadius.all(
                                                        Radius.circular(4)))),
                                            const SizedBox(height: 8),
                                            Container(
                                                width: 60,
                                                height: 14,
                                                decoration: const BoxDecoration(
                                                    color: Color(0xFFEEEEEE),
                                                    borderRadius: BorderRadius.all(
                                                        Radius.circular(4)))),
                                            const SizedBox(height: 8),
                                            Container(
                                                width: double.infinity,
                                                height: 12,
                                                decoration: const BoxDecoration(
                                                    color: Color(0xFFEEEEEE),
                                                    borderRadius: BorderRadius.all(
                                                        Radius.circular(4)))),
                                            const SizedBox(height: 4),
                                            Container(
                                                width: 150,
                                                height: 12,
                                                decoration: const BoxDecoration(
                                                    color: Color(0xFFEEEEEE),
                                                    borderRadius: BorderRadius.all(
                                                        Radius.circular(4)))),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                          width: 110,
                                          height: 110,
                                          decoration: const BoxDecoration(
                                              color: Color(0xFFEEEEEE),
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(12)))),
                                    ],
                                  ),
                                ),
                              ...items.map((item) {
                                return Column(
                                  children: [
                                    SizedBox(
                                      height: _itemHeight,
                                      child: GestureDetector(
                                        onTap: () => _showItemDetail(item),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16.0,
                                              vertical: 12.0),
                                          child: Row(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                  children: [
                                                    Text(item.name,
                                                        style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                            FontWeight.bold),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                        'RM ${item.price.toStringAsFixed(2)}',
                                                        style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight:
                                                            FontWeight.w500)),
                                                    const SizedBox(height: 6),
                                                    Text(item.description,
                                                        style: const TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.grey),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              ClipRRect(
                                                borderRadius:
                                                BorderRadius.circular(12),
                                                child:
                                                _buildImage(item.imageUrl),
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
                              }).toList(),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),

              // ===== FLOATING CART BAR =====
              // For guests — uses local _guestCart
              // For logged in — uses MenuCartProvider
              if (_isGuest)
              // Guest floating bar — reads from _guestCart
                _guestTotalQty == 0
                    ? const SizedBox.shrink()
                    : Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Cart(
                            userId: widget.userId,
                            guestCart: Map.from(_guestCart),
                          ),
                        ),
                      );
                    },
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text('$_guestTotalQty',
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
                              'RM ${_guestTotalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                )
              else
              // Logged in floating bar — reads from MenuCartProvider
                Consumer<MenuCartProvider>(
                  builder: (context, provider, _) {
                    final items = provider.cartItems;
                    final totalQty =
                    items.fold(0, (sum, i) => sum + i.quantity);
                    final totalPrice =
                    items.fold(0.0, (sum, i) => sum + i.subtotal);

                    if (items.isEmpty) return const SizedBox.shrink();

                    return Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Cart(userId: widget.userId),
                            ),
                          );
                        },
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
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
                              Text('RM ${totalPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
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
}