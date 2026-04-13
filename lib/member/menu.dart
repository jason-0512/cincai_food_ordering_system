import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:ui';

class MenuItem {
  final String name;
  final double price;
  final String description;
  final String imageUrl;

  const MenuItem({
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
  });
}

class Menu extends StatefulWidget {
  const Menu({super.key});

  @override
  State<Menu> createState() => _MenuState();
}

class _MenuState extends State<Menu> {
  String selectedCategory = 'Set';
  bool _isScrollingFromTap = false;

  List<String> categories = [
    'Set',
    'Rice',
    'Noodle',
    'Western Food',
    'Beverage',
  ];

  // Replace with Supabase data later
  final Map<String, List<MenuItem>> menuItems = {
    'Set': [
      MenuItem(
        name: 'Set A',
        price: 49.90,
        description:
        'Taiwanese-style combo set featuring savory braised rice, traditional noodles, crispy pastries, and refreshing signature drinks.',
        imageUrl:
        'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=200',
      ),
      MenuItem(
        name: 'Set B',
        price: 20.90,
        description:
        'Steamed rice topped with fragrant braised minced pork cooked in a rich soy-based sauce, served with tofu, egg, and fresh vegetables.',
        imageUrl:
        'https://images.unsplash.com/photo-1617093727343-374698b1b08d?w=200',
      ),
    ],
    'Rice': [],
    'Noodle': [],
    'Western Food': [],
    'Beverage': [],
  };

  final ScrollController _scrollController = ScrollController();

  final Map<String, GlobalKey<State<StatefulWidget>>> _categoryKeys = {
    'Set': GlobalKey<State<StatefulWidget>>(),
    'Rice': GlobalKey<State<StatefulWidget>>(),
    'Noodle': GlobalKey<State<StatefulWidget>>(),
    'Western Food': GlobalKey<State<StatefulWidget>>(),
    'Beverage': GlobalKey<State<StatefulWidget>>(),
  };

  //When click menu category it will start from the selected category header
  final Map<String, double> _categoryOffsets = {
    'Set': 0.0,
    'Rice': 355.0,
    'Noodle': 1020.0,
    'Western Food': 1625.0,
    'Beverage': 2230.0,
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isScrollingFromTap) return;

    for (final category in categories) {
      final key = _categoryKeys[category];
      if (key?.currentContext != null) {
        final RenderBox renderBox =
        key!.currentContext!.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);

        if (position.dy <= 150 && position.dy > 0) {
          if (selectedCategory != category) {
            setState(() {
              selectedCategory = category;
            });
          }
        }
      }
    }
  }

  void _scrollToCategory(String category) {
    _isScrollingFromTap = true;

    setState(() {
      selectedCategory = category;
    });

    final offset = _categoryOffsets[category] ?? 0.0;

    _scrollController
        .animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    )
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
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
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
              //Spread individual widget
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
                    setState(() {
                      selectedCategory = category;
                    });
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
                // Image with drag handle overlaid on top
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Image.network(
                        item.imageUrl,
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          return SizedBox(
                            width: double.infinity,
                            height: 250,
                            child: loadingProgress == null
                                ? child
                                : Container(color: const Color(0xFFEEEEEE)),
                          );
                        },
                      ),
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

                // Content
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Food name
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Price
                      Text(
                        'RM ${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Description
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Quantity + Add to cart row
                      Row(
                        children: [
                          // Quantity selector - Liquid Glass
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.8),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Minus button
                                    IconButton(
                                      onPressed: () {
                                        if (quantity > 1) {
                                          setModalState(() {
                                            quantity--;
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.remove),
                                    ),

                                    // Quantity number
                                    SizedBox(
                                      width: 32,
                                      child: Text(
                                        '$quantity',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    // Plus button
                                    IconButton(
                                      onPressed: () {
                                        setModalState(() {
                                          quantity++;
                                        });
                                      },
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
                              onPressed: () {
                                Navigator.pop(context);
                                // TODO: Add to cart logic here
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFCF0000),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              child: const Text(
                                'Add to cart',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button - Liquid Glass
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
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
                            width: 1,
                          ),
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ),

              // Dropdown - Liquid Glass
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
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedCategory,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Scrollable list of ALL categories
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  children: categories.map((category) {
                    final items = menuItems[category] ?? [];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Header with GlobalKey
                        Padding(
                          key: _categoryKeys[category],
                          padding: const EdgeInsets.only(
                            left: 16.0,
                            top: 24.0,
                            bottom: 8.0,
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFCF0000),
                            ),
                          ),
                        ),

                        // Empty content with skeleton first
                        if (items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 12.0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left placeholder
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      // Name placeholder
                                      Container(
                                        width: 120,
                                        height: 16,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEEEEEE),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(4),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Price placeholder
                                      Container(
                                        width: 60,
                                        height: 14,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEEEEEE),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(4),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      // Description line 1
                                      Container(
                                        width: double.infinity,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEEEEEE),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(4),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Description line 2
                                      Container(
                                        width: 150,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEEEEEE),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Image placeholder
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEEEEEE),
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Items under this category
                        ...items.map((item) {
                          return Column(
                            children: [
                              GestureDetector(
                                onTap: () => _showItemDetail(item),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 12.0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      // Left side - text
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'RM ${item.price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              item.description,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(width: 12),

                                      // Right side - image with fixed placeholder
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          item.imageUrl,
                                          width: 110,
                                          height: 110,
                                          fit: BoxFit.cover,
                                          loadingBuilder:
                                              (
                                              context,
                                              child,
                                              loadingProgress,
                                              ) {
                                            return SizedBox(
                                              width: 110,
                                              height: 110,
                                              child: loadingProgress == null
                                                  ? child
                                                  : Container(
                                                color: const Color(
                                                  0xFFEEEEEE,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFEEEEEE),
                              ),
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
        ),
      ),
    );
  }
}