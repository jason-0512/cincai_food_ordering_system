import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/audit_service.dart';

class ProductAdd extends StatefulWidget {
  final Map<String, dynamic>? product;
  final int adminId;

  const ProductAdd({
    super.key,
    this.product,
    required this.adminId,
  });

  @override
  State<ProductAdd> createState() => _ProductAddState();
}

class _ProductAddState extends State<ProductAdd> {
  final _db = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late final TextEditingController _category;
  late final TextEditingController _imageUrl;
  late final TextEditingController _sortOrder;
  bool _isAvailable = true;
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name        = TextEditingController(text: p?['name'] ?? '');
    _price       = TextEditingController(
        text: p?['price'] != null
            ? (p!['price'] as num).toStringAsFixed(2)
            : '');
    _description = TextEditingController(text: p?['description'] ?? '');
    _category    = TextEditingController(text: p?['category'] ?? '');
    _imageUrl    = TextEditingController(text: p?['image_url'] ?? '');
    _sortOrder   = TextEditingController(
        text: p?['sort_order']?.toString() ?? '0');
    _isAvailable = p?['is_available'] as bool? ?? true;
  }

  @override
  void dispose() {
    _name.dispose(); _price.dispose(); _description.dispose();
    _category.dispose(); _imageUrl.dispose(); _sortOrder.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final payload = {
      'name':         _name.text.trim(),
      'price':        double.parse(_price.text.trim()),
      'description':  _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      'category':     _category.text.trim().isEmpty
          ? null
          : _category.text.trim(),
      'image_url':    _imageUrl.text.trim().isEmpty
          ? null
          : _imageUrl.text.trim(),
      'sort_order':   int.tryParse(_sortOrder.text.trim()) ?? 0,
      'is_available': _isAvailable,
    };

    try {
      if (_isEdit) {
        final id = widget.product!['id'];
        await _db.from('product').update(payload).eq('id', id);
        await AuditService.log(
          adminId: widget.adminId,
          action: 'product.update',
          entityType: 'product',
          entityId: id.toString(),
          oldValue: widget.product,
          newValue: payload,
        );
      } else {
        final result = await _db
            .from('product')
            .insert(payload)
            .select()
            .single();
        await AuditService.log(
          adminId: widget.adminId,
          action: 'product.create',
          entityType: 'product',
          entityId: result['id'].toString(),
          newValue: payload,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'New Product'),
        backgroundColor: const Color(0xFFCF0000),
        foregroundColor: Colors.white,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _field(
              controller: _name,
              label: 'Product name',
              validator: (v) =>
              v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            _field(
              controller: _price,
              label: 'Price (RM)',
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v.trim()) == null) return 'Invalid price';
                return null;
              },
            ),
            _field(controller: _category, label: 'Category (optional)'),
            _field(
              controller: _description,
              label: 'Description (optional)',
              maxLines: 3,
            ),
            _field(controller: _imageUrl, label: 'Image URL (optional)'),
            _field(
              controller: _sortOrder,
              label: 'Sort order',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available for ordering',
                  style: TextStyle(fontSize: 14)),
              value: _isAvailable,
              activeColor: const Color(0xFFCF0000),
              onChanged: (v) => setState(() => _isAvailable = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCF0000)),
          ),
          labelStyle: const TextStyle(fontSize: 14),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}