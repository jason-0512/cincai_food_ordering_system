import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';
import 'dart:async';
import 'account.dart';
import 'cart.dart';
import 'login.dart';
import 'menu.dart';

class Home extends StatefulWidget {
  final String? userEmail;

  const Home({super.key, this.userEmail});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  bool _isSearching = false;

  // Stores the logged-in user's id
  // null means guest (not logged in)
  int? _userId;

  List<String> _bannerImages = [];
  Map<String, String> _categoryImages = {
    'Set': '',
    'Rice': '',
    'Noodle': '',
    'Western Food': '',
    'Beverage': '',
  };

  List<Map<String, String>> _popularItems = [];

  final PageController _bannerController = PageController(initialPage: 9999);
  int _currentBannerIndex = 0;
  Timer? _bannerTimer;

  IconData _currentIcon() {
    switch (_selectedIndex) {
      case 0:
        return Icons.home_rounded;
      case 1:
        return Icons.rice_bowl_outlined;
      case 2:
        return Icons.shopping_cart_outlined;
      case 3:
        return Icons.person_outline;
      default:
        return Icons.home_rounded;
    }
  }

  Widget _navItem(IconData icons, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (index == 1) {
          // Anyone can browse menu — guests use userId 0
          _showTablePickerDialog();
        } else if (index == 2) {
          // Anyone can view cart — guests use userId 0
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Cart(userId: _userId ?? 0),
            ),
          ).then((_) => setState(() => _selectedIndex = 0));
        } else if (index == 3) {
          if (widget.userEmail != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Account(email: widget.userEmail!),
              ),
            ).then((_) => setState(() => _selectedIndex = 0));
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Login()),
            ).then((_) => setState(() => _selectedIndex = 0));
          }
        }
      },
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5F5F5) : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icons,
                color: isSelected ? const Color(0xFFCF0000) : Colors.grey,
                size: 24),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color:
                    isSelected ? const Color(0xFFCF0000) : Colors.grey,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _categoryItem(String label, String imageUrl) {
    return GestureDetector(
      // Anyone can tap categories — guests use userId 0
      onTap: () => _showTablePickerDialog(initialCategory: label),
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            ClipOval(child: _buildImage(imageUrl, width: 64, height: 64)),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _popularItem(
      String name, String price, String imageUrl, String category) {
    return GestureDetector(
      // Anyone can tap popular items — guests use userId 0
      onTap: () => _showTablePickerDialog(initialCategory: category),
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildImage(imageUrl, width: 150, height: 130),
            ),
            const SizedBox(height: 8),
            Text(name,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            const SizedBox(height: 4),
            Text(price,
                style:
                const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _showTablePickerDialog({String initialCategory = 'Set'}) {
    int? selectedTable;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                backgroundColor: const Color(0xFFF5F5F7),
                insetPadding:
                const EdgeInsets.symmetric(horizontal: 100),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Select Your Table Number',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 200,
                        height: 250,
                        child: ListView.builder(
                          itemCount: 14,
                          itemBuilder: (context, index) {
                            final tableNumber = index + 1;
                            final isSelected = selectedTable == tableNumber;
                            return GestureDetector(
                              onTap: () => setDialogState(
                                      () => selectedTable = tableNumber),
                              child: Container(
                                height: 40,
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFCF0000)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFCF0000)
                                        : Colors.grey.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text('$tableNumber',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.black)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() => _selectedIndex = 0);
                            },
                            child: const Text('Cancel',
                                style: TextStyle(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            onPressed: selectedTable == null
                                ? null
                                : () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Menu(
                                    initialCategory: initialCategory,
                                    // Pass _userId — 0 for guests
                                    userId: _userId ?? 0,
                                  ),
                                ),
                              ).then((_) =>
                                  setState(() => _selectedIndex = 0));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFCF0000),
                              disabledBackgroundColor:
                              Colors.grey.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50)),
                            ),
                            child: const Text('Confirm',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _bannerController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
    _fetchHomeData();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
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

  Future<void> _fetchHomeData() async {
    try {
      final response = await Supabase.instance.client
          .from('product')
          .select()
          .eq('is_available', true)
          .order('sort_order', ascending: true);

      final setItems =
      response.where((item) => item['category'] == 'Set').toList();
      final List<String> bannerImages = setItems
          .map((item) => item['image_url'] as String? ?? '')
          .where((url) => url.isNotEmpty)
          .toList();

      final Map<String, String> categoryImages = {
        'Set': '',
        'Rice': '',
        'Noodle': '',
        'Western Food': '',
        'Beverage': '',
      };

      for (final item in response) {
        final category = item['category'] as String;
        if (categoryImages.containsKey(category) &&
            categoryImages[category]!.isEmpty) {
          categoryImages[category] = item['image_url'] ?? '';
        }
      }

      final popularNames = [
        'Set B',
        'Lu Rou Fan',
        'Minced Pork Rice',
        'Taiwanese Beef Noodle',
      ];
      final List<Map<String, String>> popularItems = [];
      for (final name in popularNames) {
        final found =
        response.where((item) => item['name'] == name).toList();
        if (found.isNotEmpty) {
          popularItems.add({
            'name': found[0]['name'] ?? '',
            'price':
            'RM ${(found[0]['price'] as num).toStringAsFixed(2)}',
            'imageUrl': found[0]['image_url'] ?? '',
            'category': found[0]['category'] ?? 'Set',
          });
        }
      }

      // Fetch userId from email if logged in
      if (widget.userEmail != null) {
        final user = await Supabase.instance.client
            .from('users')
            .select('id')
            .eq('email', widget.userEmail!.trim())
            .maybeSingle();
        if (user != null) {
          setState(() => _userId = user['id'] as int);
        }
      }

      setState(() {
        if (bannerImages.isNotEmpty) _bannerImages = bannerImages;
        _categoryImages = categoryImages;
        _popularItems = popularItems;
      });
    } catch (e) {
      print('Error fetching home data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F5F7),
        elevation: 0,
        toolbarHeight: 90,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isSearching
              ? const Text('Search',
              key: ValueKey('search'),
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black))
              : const Text('Cincai',
              key: ValueKey('normal'),
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isSearching
                  ? const SizedBox()
                  : ListView(
                padding:
                const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  SizedBox(
                    height: 250,
                    child: PageView.builder(
                      controller: _bannerController,
                      reverse: false,
                      physics: const PageScrollPhysics(),
                      onPageChanged: (index) {
                        if (_bannerImages.isEmpty) return;
                        setState(() {
                          _currentBannerIndex =
                              index % _bannerImages.length;
                        });
                      },
                      itemCount: 99999,
                      itemBuilder: (context, index) {
                        if (_bannerImages.isEmpty)
                          return const SizedBox();
                        final imageIndex =
                            index % _bannerImages.length;
                        return GestureDetector(
                          onTap: () => _showTablePickerDialog(
                              initialCategory: 'Set'),
                          child: Padding(
                            padding:
                            const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius:
                              BorderRadius.circular(16),
                              child: _buildImage(
                                _bannerImages[imageIndex],
                                width: double.infinity,
                                height: 250,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _bannerImages.length,
                          (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 4),
                        width:
                        _currentBannerIndex == index ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentBannerIndex == index
                              ? Colors.black.withOpacity(0.5)
                              : Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Categories',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _categoryItem(
                            'Set', _categoryImages['Set'] ?? ''),
                        _categoryItem(
                            'Rice', _categoryImages['Rice'] ?? ''),
                        _categoryItem('Noodle',
                            _categoryImages['Noodle'] ?? ''),
                        _categoryItem('Western Food',
                            _categoryImages['Western Food'] ?? ''),
                        _categoryItem('Beverage',
                            _categoryImages['Beverage'] ?? ''),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Popular',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _popularItems
                          .map((item) => _popularItem(
                        item['name']!,
                        item['price']!,
                        item['imageUrl']!,
                        item['category'] ?? 'Set',
                      ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, bottom: 24),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isSearching = false),
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                              sigmaX: 20, sigmaY: 20),
                          child: Container(
                            width: 63,
                            height: 63,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.8),
                                  width: 1),
                            ),
                            child: Icon(_currentIcon(),
                                color: Colors.grey, size: 24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                              sigmaX: 20, sigmaY: 20),
                          child: Container(
                            height: 63,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.8),
                                  width: 1),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search,
                                    color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Search for food',
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(
                                          color: Colors.grey),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() =>
                                      FocusScope.of(context).unfocus()),
                                  child: const Icon(Icons.close,
                                      color: Colors.grey, size: 20),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _isSearching
          ? null
          : Padding(
        padding: const EdgeInsets.only(
            left: 16, right: 16, bottom: 24),
        child: SizedBox(
          height: 80,
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                        sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                            width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                        children: [
                          _navItem(Icons.home_rounded, 'Home', 0),
                          _navItem(
                              Icons.rice_bowl_outlined, 'Menu', 1),
                          _navItem(Icons.shopping_cart_outlined,
                              'Cart', 2),
                          _navItem(
                              Icons.person_outline, 'Account', 3),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => _isSearching = true),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                        sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: 63,
                      height: 63,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                            width: 1),
                      ),
                      child: const Icon(Icons.search,
                          color: Colors.grey, size: 24),
                    ),
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