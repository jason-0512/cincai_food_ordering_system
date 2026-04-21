import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

class AddressItem {
  final int addressId;
  final int? userId;
  String addressLine;
  String city;
  String postcode;
  String state;
  bool isDefault;

  AddressItem({
    required this.addressId,
    this.userId,
    required this.addressLine,
    required this.city,
    required this.postcode,
    required this.state,
    required this.isDefault,
  });

  factory AddressItem.fromJson(Map<String, dynamic> json) {
    return AddressItem(
      addressId: json['address_id'] ?? 0,
      userId: json['user_id'],
      addressLine: json['address_line'] ?? '',
      city: json['city'] ?? '',
      postcode: json['postcode'] ?? '',
      state: json['state'] ?? '',
      isDefault: json['is_default'] ?? false,
    );
  }

  String get shortAddress => addressLine;
  String get fullSubtitle => '$city, $postcode, $state';
}

class AddressSelectionScreen extends StatefulWidget {
  final int userId;
  final AddressItem? currentSelected;
  final bool selectionMode;

  const AddressSelectionScreen({
    super.key,
    required this.userId,
    this.currentSelected,
    this.selectionMode = true,
  });

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  List<AddressItem> _addresses = [];
  bool _isLoading = true;
  AddressItem? _selected;

  // null  = no form open
  // -1    = adding new address
  // other = editing that addressId
  int? _formTargetId;
  bool _formIsSaving = false;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressLineCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _postcodeCtrl;
  late TextEditingController _stateCtrl;
  bool _formIsDefault = false;

  @override
  void initState() {
    super.initState();
    _addressLineCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
    _postcodeCtrl = TextEditingController();
    _stateCtrl = TextEditingController();
    _fetchAddresses();
  }

  @override
  void dispose() {
    _addressLineCtrl.dispose();
    _cityCtrl.dispose();
    _postcodeCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────────────────────

  Future<void> _fetchAddresses() async {
    try {
      final data = await _supabase
          .from('address')
          .select()
          .eq('user_id', widget.userId)
          .eq('is_deleted', false)
          .order('is_default', ascending: false);

      if (mounted) {
        final addresses =
        (data as List).map((a) => AddressItem.fromJson(a)).toList();

        AddressItem? preselected = widget.currentSelected;
        if (preselected == null) {
          try {
            preselected = addresses.firstWhere((a) => a.isDefault);
          } catch (_) {
            preselected = addresses.isNotEmpty ? addresses.first : null;
          }
        }

        setState(() {
          _addresses = addresses;
          _selected = preselected;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching addresses: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setDefault(AddressItem address) async {
    try {
      await _supabase
          .from('address')
          .update({'is_default': false}).eq('user_id', widget.userId);
      await _supabase
          .from('address')
          .update({'is_default': true}).eq('address_id', address.addressId);
      setState(() {
        for (final a in _addresses) {
          a.isDefault = a.addressId == address.addressId;
        }
        _selected = address;
      });
    } catch (e) {
      debugPrint('Error setting default: $e');
    }
  }

  Future<void> _confirmDelete(AddressItem address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Address',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Remove "${address.shortAddress}"?\nThis cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Color(0xFFCF0000))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _supabase
          .from('address')
          .update({'is_deleted': true, 'is_default': false})
          .eq('address_id', address.addressId);

      if (_selected?.addressId == address.addressId) {
        setState(() => _selected = null);
      }

      if (_formTargetId == address.addressId) _closeForm();

      await _fetchAddresses();

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Address removed successfully"))
      );
    } catch (e) {
      debugPrint('Archive address error: $e');
    }
  }

  // ── Form ────────────────────────────────────────────────────────────────────

  void _openAddForm() {
    _addressLineCtrl.clear();
    _cityCtrl.clear();
    _postcodeCtrl.clear();
    _stateCtrl.clear();
    _formIsDefault = _addresses.isEmpty;
    setState(() => _formTargetId = -1);
  }

  void _openEditForm(AddressItem address) {
    _addressLineCtrl.text = address.addressLine;
    _cityCtrl.text = address.city;
    _postcodeCtrl.text = address.postcode;
    _stateCtrl.text = address.state;
    _formIsDefault = address.isDefault;
    setState(() => _formTargetId = address.addressId);
  }

  void _closeForm() {
    setState(() {
      _formTargetId = null;
      _formIsSaving = false;
    });
  }

  Future<void> _saveForm() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _formIsSaving = true);

    try {
      final isAdding = _formTargetId == -1;

      if (_formIsDefault) {
        await _supabase
            .from('address')
            .update({'is_default': false}).eq('user_id', widget.userId);
      }

      if (isAdding) {
        await _supabase.from('address').insert({
          'user_id': widget.userId,
          'address_line': _addressLineCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'postcode': _postcodeCtrl.text.trim(),
          'state': _stateCtrl.text.trim(),
          'is_default': _formIsDefault,
        });
      } else {
        await _supabase.from('address').update({
          'address_line': _addressLineCtrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'postcode': _postcodeCtrl.text.trim(),
          'state': _stateCtrl.text.trim(),
          'is_default': _formIsDefault,
        }).eq('address_id', _formTargetId!);
      }

      _closeForm();
      await _fetchAddresses();
    } catch (e) {
      debugPrint('Save address error: $e');
      setState(() => _formIsSaving = false);
    }
  }

  // ── UI Helpers ───────────────────────────────────────────────────────────────

  Widget _glassWrap({required Widget child, bool highlighted = false}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: highlighted
                ? const Color(0xFFCF0000).withOpacity(0.08)
                : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlighted
                  ? const Color(0xFFCF0000)
                  : Colors.white.withOpacity(0.8),
              width: highlighted ? 1.5 : 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      filled: true,
      fillColor: Colors.white.withOpacity(0.5),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCF0000), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCF0000), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCF0000), width: 1.5),
      ),
    );
  }

  Widget _addressForm({required bool isAdding}) {
    return _glassWrap(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isAdding ? 'New Address' : 'Edit Address',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _addressLineCtrl,
                decoration: _inputDecoration('Address Line'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityCtrl,
                      decoration: _inputDecoration('City'),
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _postcodeCtrl,
                      decoration: _inputDecoration('Postcode'),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _stateCtrl,
                decoration: _inputDecoration('State'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // Default checkbox
              GestureDetector(
                onTap: () =>
                    setState(() => _formIsDefault = !_formIsDefault),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _formIsDefault
                            ? const Color(0xFFCF0000)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: _formIsDefault
                              ? const Color(0xFFCF0000)
                              : Colors.grey,
                          width: 1.5,
                        ),
                      ),
                      child: _formIsDefault
                          ? const Icon(Icons.check,
                          size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Set as default address',
                      style: TextStyle(fontSize: 13, color: Colors.black),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _formIsSaving ? null : _closeForm,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50)),
                        side: BorderSide(color: Colors.grey.withOpacity(0.4)),
                      ),
                      child: const Text('Cancel',
                          style:
                          TextStyle(color: Colors.black, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _formIsSaving ? null : _saveForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCF0000),
                        disabledBackgroundColor:
                        Colors.grey.withOpacity(0.4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50)),
                      ),
                      child: _formIsSaving
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                          : Text(
                        isAdding ? 'Add' : 'Save',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addressCard(AddressItem address) {
    final isSelected = _selected?.addressId == address.addressId;
    final isEditing = _formTargetId == address.addressId;

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _selected = address),
          child: _glassWrap(
            highlighted: isSelected,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.selectionMode)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSelected ? const Color(0xFFCF0000) : Colors.grey,
                        size: 20,
                      ),
                    ),
                  if (widget.selectionMode) const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                address.shortAddress,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            if (address.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCF0000)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFCF0000)
                                        .withOpacity(0.4),
                                  ),
                                ),
                                child: const Text(
                                  'Default',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFCF0000),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          address.fullSubtitle,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),

                        // Action links row
                        Row(
                          children: [
                            if (!address.isDefault) ...[
                              GestureDetector(
                                onTap: () => _setDefault(address),
                                child: const Text(
                                  'Set as default',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFCF0000),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8),
                                child: Text('·',
                                    style: TextStyle(
                                        color:
                                        Colors.grey.withOpacity(0.5))),
                              ),
                            ],
                            GestureDetector(
                              onTap: () => isEditing
                                  ? _closeForm()
                                  : _openEditForm(address),
                              child: Text(
                                isEditing ? 'Cancel edit' : 'Edit',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                              child: Text('·',
                                  style: TextStyle(
                                      color: Colors.grey.withOpacity(0.5))),
                            ),
                            GestureDetector(
                              onTap: () => _confirmDelete(address),
                              child: const Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFCF0000),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Inline edit form slides in below the card
        if (isEditing) ...[
          const SizedBox(height: 8),
          _addressForm(isAdding: false),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
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
                                width: 1,
                              ),
                            ),
                            child: const Icon(Icons.arrow_back,
                                color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      widget.selectionMode ? 'Select Address' : 'My Addresses',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // ── List ────────────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  if (_addresses.isEmpty && _formTargetId != -1)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(
                        'No saved addresses.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  ..._addresses.map((address) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _addressCard(address),
                  )),

                  // Add new form
                  if (_formTargetId == -1) ...[
                    _addressForm(isAdding: true),
                    const SizedBox(height: 12),
                  ],

                  // Add new button — hidden while any form is open
                  if (_formTargetId == null) ...[
                    _glassWrap(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _openAddForm,
                          borderRadius: BorderRadius.circular(16),
                          splashColor: Colors.grey.withOpacity(0.2),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 16, horizontal: 20),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add,
                                    color: Color(0xFFCF0000),
                                    size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Add New Address',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFCF0000),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),

            // ── Confirm button ───────────────────────────────────────────────
            if (widget.selectionMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: ElevatedButton(
                  onPressed: _selected == null
                      ? null
                      : () => Navigator.pop(context, _selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCF0000),
                    disabledBackgroundColor: Colors.grey.withOpacity(0.4),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: const Text(
                    'Confirm Address',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}