import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_add_edit.dart';


class ProductManagement extends StatefulWidget {
  final int adminId;
  const ProductManagement({super.key, required this.adminId});

  @override
  State<ProductManagement> createState() => _ProductManagementState();
}

class _ProductManagementState extends State<ProductManagement> {
  final _db = Supabase.instance.client;
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _loading = true);
    final data = await _db
        .from('product')
        .select()
        .order('sort_order')
        .order('name');
    setState(() {
      _products = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product'),
        content: Text('Remove "${product['name']}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _db.from('product').delete().eq('id', product['id']);
    _fetchProducts();
  }

  Future<void> _toggleAvailability(Map<String, dynamic> product) async {
    final newValue = !(product['is_available'] as bool? ?? true);
    await _db
        .from('product')
        .update({'is_available': newValue})
        .eq('id', product['id']);
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        backgroundColor: const Color(0xFFCF0000),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFCF0000),
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductAdd(adminId: widget.adminId),
            ),
          );
          _fetchProducts();
        },
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
          ? const Center(child: Text('No products yet. Tap + to add one.'))
          : RefreshIndicator(
        onRefresh: _fetchProducts,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _products.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final p = _products[i];
            final available = p['is_available'] as bool? ?? true;
            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: p['image_url'] != null
                      ? Image.network(
                    p['image_url'],
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _imagePlaceholder(),
                  )
                      : _imagePlaceholder(),
                ),
                title: Text(
                  p['name'] ?? '-',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: available ? null : Colors.grey,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p['category'] != null)
                      Text(
                        p['category'],
                        style: const TextStyle(fontSize: 11),
                      ),
                    Text(
                      'RM ${(p['price'] as num?)?.toStringAsFixed(2) ?? '-'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFCF0000),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // availability toggle
                    GestureDetector(
                      onTap: () => _toggleAvailability(p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: available
                              ? const Color(0xFFE8F5E9)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          available ? 'Live' : 'Hidden',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: available
                                ? Colors.green.shade700
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // edit
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductAdd(
                              product: p,
                              adminId: widget.adminId,
                            ),
                          ),
                        );
                        _fetchProducts();
                      },
                    ),
                    // delete
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: () => _deleteProduct(p),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 52,
      height: 52,
      color: Colors.grey.shade100,
      child: const Icon(Icons.fastfood_outlined, size: 24, color: Colors.grey),
    );
  }
}