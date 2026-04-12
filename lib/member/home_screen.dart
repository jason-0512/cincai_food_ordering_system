import 'package:flutter/material.dart';
import 'menu.dart';
import 'cart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const _HomeContent(),
    const Menu(),
    const CartPage(),
    const Center(child: Text('Account Page')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) {
          setState(() {
            _selectedIndex = i;
          });
        },
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {'label': 'Set', 'image': 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=200&h=200&fit=crop'},
      {'label': 'Rice', 'image': 'https://images.unsplash.com/photo-1516684732162-798a0062be99?w=200&h=200&fit=crop'},
      {'label': 'Noodle', 'image': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=200&h=200&fit=crop'},
      {'label': 'Western Food', 'image': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=200&h=200&fit=crop'},
    ];

    final List<Map<String, dynamic>> popular = [
      {'image': 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400&h=300&fit=crop'},
      {'image': 'https://images.unsplash.com/photo-1534482421-64566f976cfa?w=400&h=300&fit=crop'},
      {'image': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400&h=300&fit=crop'},
    ];

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Cincai',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&h=380&fit=crop',
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.red[700],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        '台湾ゴハン祭り',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: categories.map((cat) {
                  return _CategoryItem(
                    label: cat['label'] as String,
                    imageUrl: cat['image'] as String,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Popular',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 130,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: popular.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        popular[index]['image'] as String,
                        width: 160,
                        height: 130,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 160,
                          height: 130,
                          color: Colors.grey[200],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String label;
  final String imageUrl;

  const _CategoryItem({required this.label, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: ClipOval(
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.restaurant_menu_rounded, 'label': 'Menu'},
      {'icon': Icons.shopping_cart_outlined, 'label': 'Cart'},
      {'icon': Icons.person_outline_rounded, 'label': 'Account'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            ...List.generate(items.length, (i) {
              final selected = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[i]['icon'] as IconData,
                          size: 22,
                          color: selected ? Colors.red[700] : Colors.grey[500],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[i]['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: selected ? Colors.red[700] : Colors.grey[500],
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Icon(Icons.search_rounded, size: 22, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}
