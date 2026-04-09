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
    'Rice': [
      MenuItem(
        name: 'Lu Rou Fan',
        price: 13.90,
        description:
            'Tender braised pork cubes slow-cooked in flavorful soy sauce served over fluffy rice, paired with marinated egg and fresh greens for a balanced and hearty meal.',
        imageUrl:
            'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=200',
      ),
      MenuItem(
        name: 'Braised Pork Rice',
        price: 13.90,
        description:
            'Fragrant steamed rice topped with tender braised pork slow-cooked in savory soy sauce, served with marinated egg and fresh vegetables for a rich and satisfying traditional Taiwanese meal.',
        imageUrl:
            'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=200',
      ),
      MenuItem(
        name: 'Minced Pork Rice',
        price: 11.90,
        description:
            'Classic Taiwanese comfort food with seasoned minced pork served over steamed white rice with pickled vegetables.',
        imageUrl:
            'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=200',
      ),
      MenuItem(
        name: 'Taiwanese Sticky Rice',
        price: 11.90,
        description:
            'Traditional glutinous rice cooked with mushrooms, dried shrimp, and savory toppings for a rich and filling meal.',
        imageUrl:
            'https://images.unsplash.com/photo-1516684732162-798a0062be99?w=200',
      ),
    ],
    'Noodle': [
      MenuItem(
        name: 'Taiwanese Beef Noodle',
        price: 16.90,
        description:
            'Rich and hearty beef broth with tender slow-braised beef chunks and springy noodles, a Taiwanese classic.',
        imageUrl:
            'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=200',
      ),
      MenuItem(
        name: 'Instant Pot Taiwanese Noodle',
        price: 14.90,
        description:
            'Smooth and flavorful noodles cooked in a savory broth with tender pork and fresh garnishes.',
        imageUrl:
            'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=200',
      ),
      MenuItem(
        name: "Mom's Dry Noodle",
        price: 12.90,
        description:
            'Homestyle dry tossed noodles with a secret sauce, minced pork, and spring onions — just like home cooking.',
        imageUrl:
            'https://images.unsplash.com/photo-1552611052-33e04de081de?w=200',
      ),
      MenuItem(
        name: 'Braised Pork Belly Noodle',
        price: 15.90,
        description:
            'Springy noodles topped with melt-in-your-mouth braised pork belly slow-cooked in a rich and aromatic soy broth.',
        imageUrl:
            'https://images.unsplash.com/photo-1534482421-64566f976cfa?w=200',
      ),
    ],
    'Western Food': [
      MenuItem(
        name: 'Chicken Chop',
        price: 17.90,
        description:
            'Crispy golden chicken chop served with coleslaw, fries, and a rich mushroom or black pepper sauce.',
        imageUrl:
            'https://images.unsplash.com/photo-1532550907401-a500c9a57435?w=200',
      ),
      MenuItem(
        name: 'Fish & Chips',
        price: 16.90,
        description:
            'Golden battered fish fillet served with crispy fries, coleslaw, and tartar sauce on the side.',
        imageUrl:
            'https://images.unsplash.com/photo-1619895862022-09114b41f16f?w=200',
      ),
      MenuItem(
        name: 'Crispy Chicken',
        price: 15.90,
        description:
            'Juicy fried chicken with an extra crispy coating, served with fries and honey mustard dipping sauce.',
        imageUrl:
            'https://images.unsplash.com/photo-1562967914-608f82629710?w=200',
      ),
      MenuItem(
        name: 'Classic Hash Burger',
        price: 16.90,
        description:
            'Juicy beef patty with crispy hash brown, fresh lettuce, tomato, cheese, and signature sauce in a toasted bun.',
        imageUrl:
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200',
      ),
    ],
    'Beverage': [
      MenuItem(
        name: 'Soya Bean with Grass Jelly',
        price: 5.90,
        description:
            'Smooth and refreshing homemade soya bean drink topped with silky grass jelly cubes.',
        imageUrl:
            'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=200',
      ),
      MenuItem(
        name: 'Milk Tea',
        price: 6.90,
        description:
            'Creamy and aromatic milk tea brewed with premium black tea leaves and fresh milk.',
        imageUrl:
            'https://images.unsplash.com/photo-1558857563-b371033873b8?w=200',
      ),
      MenuItem(
        name: 'Lemon Black Tea',
        price: 5.90,
        description:
            'Refreshing black tea with a squeeze of fresh lemon, served chilled for a tangy and uplifting drink.',
        imageUrl:
            'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=200',
      ),
      MenuItem(
        name: 'Orange Juice',
        price: 6.90,
        description:
            'Freshly squeezed orange juice packed with natural vitamins, served chilled and full of fruity goodness.',
        imageUrl:
            'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=200',
      ),
      MenuItem(
        name: 'Ice Lemon Tea',
        price: 5.50,
        description:
            'Classic iced lemon tea with the perfect balance of sweetness and citrus, served over crushed ice.',
        imageUrl:
            'https://images.unsplash.com/photo-1499638673689-79a0b5115d87?w=200',
      ),
      MenuItem(
        name: 'Kopi-O',
        price: 4.50,
        description:
            'Traditional Malaysian black coffee brewed strong and bold, served hot or iced with a rich aromatic finish.',
        imageUrl:
            'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=200',
      ),
    ],
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: categories.map((category) {
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
          ),
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
              // Back Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(255, 255, 255, 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
                ),
              ),

              // Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GestureDetector(
                  onTap: _showCategoryBottomSheet,
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.6),
                      borderRadius: BorderRadius.circular(50),
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

              // Scrollable list of ALL categories
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 500), // ADD THIS LINE
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

                        // Items under this category
                        ...items.map((item) {
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 12.0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                            (context, child, loadingProgress) {
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
