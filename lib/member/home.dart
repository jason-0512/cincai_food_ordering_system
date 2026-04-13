import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';

import 'account.dart';
import 'cart.dart';
import 'login.dart';
import 'menu.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  bool _isSearching = false;
  bool _isLoggedIn = false;

  final PageController _bannerController = PageController(initialPage: 9999);
  int _currentBannerIndex=0;
  Timer ? _bannerTimer;

  final List<String> _bannerImages = [
    'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=800',
    'https://images.unsplash.com/photo-1617093727343-374698b1b08d?w=800',
  ];

  //Handle left icons when search bar is opens
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
    ///Check if this tab is currently selected
    final bool isSelected = _selectedIndex == index;
    //Makes the tab tappable
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        // Navigate to the selected page
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Menu()),
          ).then((_) {
            setState(() => _selectedIndex = 0); // ← reset to Home after returning
          });
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const Cart()),
          ).then((_) {
            setState(() => _selectedIndex = 0);
          });
        } else if (index == 3) {
          if (_isLoggedIn) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Account()),
            ).then((_) {
              setState(() => _selectedIndex = 0);
            });
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Login()),
            ).then((_) {
              setState(() => _selectedIndex = 0);
            });
          }
        }
      },
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          //Selected tab (light grey background), unselected (transparent)
          color: isSelected
              ? const Color(0xFFF5F5F5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icons,
              color: isSelected
                  ? const Color(0xFFCF0000)
                  : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? const Color(0xFFCF0000)
                    : Colors.grey,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryItem(String label, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          // Circle image
          ClipOval(
            child: Image.network(
              imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                return SizedBox(
                  width: 64,
                  height: 64,
                  child: loadingProgress == null
                      ? child
                      : Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFEEEEEE),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Label
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _popularItem(String name, String price, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              width: 150,
              height: 130,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                return SizedBox(
                  width: 150,
                  height: 130,
                  child: loadingProgress == null
                      ? child
                      : Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Food name
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          // Price
          Text(
            price,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //Start auto scroll timer every 3 seconds
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _bannerController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
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
              ? const Text(
            'Search',
            key: ValueKey('search'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          )
              : const Text(
            'Cincai',
            key: ValueKey('normal'),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
      //Prevent content from going behind camera notch, status bar or home indicator at bottom
      body: SafeArea(
        child: Column(
          children: [
            //Make content scrollable vertically
            Expanded(
              child: _isSearching
              // SEARCH PAGE - empty page
                  ? const SizedBox()
              // HOME PAGE
                  : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  //page content here
                  SizedBox(
                    height: 250,
                    child: PageView.builder(
                      controller: _bannerController,
                      reverse: false,
                      physics: const PageScrollPhysics(),
                      onPageChanged: (index){
                        setState(() {
                          _currentBannerIndex = index % _bannerImages.length;
                        });
                      },
                      itemCount: 99999,
                      itemBuilder: (context,index){
                        final imageIndex = index % _bannerImages.length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              _bannerImages[imageIndex],
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                return SizedBox(
                                  width: double.infinity,
                                  height: 180,
                                  child: loadingProgress == null
                                      ? child
                                      : Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEEEEE),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  //Banner Dot Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _bannerImages.length,
                          (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentBannerIndex == index ? 20 : 8,
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

                  //Categories Section
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _categoryItem('Set', 'https://images.unsplash.com/photo-1569050467447-ce54b3bbc37d?w=200'),
                        _categoryItem('Rice', 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=200'),
                        _categoryItem('Noodle', 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=200'),
                        _categoryItem('Western Food', 'https://images.unsplash.com/photo-1532550907401-a500c9a57435?w=200'),
                        _categoryItem('Beverage', 'https://images.unsplash.com/photo-1558857563-b371033873b8?w=200'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  //Popular section
                  const Text(
                    'Popular',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 16),

                  //Popular Horizontal Scroll
                  SizedBox(
                    height: 180,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _popularItem('Lu Rou Fan', 'RM 13.90', 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?w=400'),
                        _popularItem('Braised Pork Rice', 'RM 13.90', 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400'),
                        _popularItem('Taiwanese Beef Noodle', 'RM 16.90', 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Search bar inside body - moves up with keyboard
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                child: Row(
                  children: [
                    //Tap left icon close search
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSearching = false;
                        });
                      },
                      //The circular left icon button
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            width: 63,
                            height: 63,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.6),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              _currentIcon(),
                              color: Colors.grey,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    //Expanded Search Bar
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            height: 63,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                const Icon(Icons.search, color: Colors.grey, size: 20),
                                const SizedBox(width: 8),
                                const Expanded(
                                  //Keyboard opens automatically when search activate
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Search for food',
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ),
                                //Close button
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      FocusScope.of(context).unfocus();
                                    });
                                  },
                                  child: const Icon(Icons.close, color: Colors.grey, size: 20),
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
      // Normal nav bar - only shows when NOT searching
      bottomNavigationBar: _isSearching
          ? null
          : Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        child: SizedBox(
          height: 80,
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
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
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _navItem(Icons.home_rounded, 'Home', 0),
                          _navItem(Icons.rice_bowl_outlined, 'Menu', 1),
                          _navItem(Icons.shopping_cart_outlined, 'Cart', 2),
                          _navItem(Icons.person_outline, 'Account', 3),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              //Search circle
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isSearching = true;
                  });
                },
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      width: 63,
                      height: 63,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.search,
                        color: Colors.grey,
                        size: 24,
                      ),
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