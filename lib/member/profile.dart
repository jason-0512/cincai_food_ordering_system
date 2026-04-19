import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'supabase_service.dart';
import 'login.dart';

class Profile extends StatefulWidget {
  final String email;

  const Profile({super.key, required this.email});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = true;
  bool _isSaving = false;
  bool _obscurePassword = true;

  // Track which field is being edited
  String? _editingField; // 'name', 'phone', 'email', 'password'

  String? currentEmail;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await SupabaseService.getProfile(widget.email);

    if (profile != null) {
      currentEmail = profile['email'];
      _nameController.text = profile['name'] ?? '';
      _phoneController.text = profile['phone'] ?? '';
      _emailController.text = profile['email'] ?? '';
      _passwordController.text = profile['password_hash'] ?? '';
    }

    setState(() => _loading = false);
  }

  Future<void> _update() async {
    final phone = _phoneController.text.trim();

    if (!RegExp(r'^01[0-9]{8,9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter valid Malaysian phone number"),
          backgroundColor: Color(0xFFCF0000),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    await SupabaseService.updateProfile(
      name: _nameController.text,
      phone: _phoneController.text,
      email: currentEmail!,
    );

    setState(() {
      _isSaving = false;
      _editingField = null;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Profile updated"),
        backgroundColor: Color(0xFFCF0000),
      ),
    );
  }

  Future<void> _updateEmail() async {
    final oldEmail = currentEmail!;
    final newEmail = _emailController.text.trim();

    if (newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email cannot be empty"),
          backgroundColor: Color(0xFFCF0000),
        ),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(newEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid email format"),
          backgroundColor: Color(0xFFCF0000),
        ),
      );
      return;
    }

    final error = await SupabaseService.updateEmail(
      oldEmail: oldEmail,
      newEmail: newEmail,
    );

    if (!mounted) return;

    if (error == null) {
      currentEmail = newEmail;
      setState(() => _editingField = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email updated"),
          backgroundColor: Color(0xFFCF0000),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFCF0000),
        ),
      );
    }
  }

  Future<void> _updatePassword() async {
    final newPassword = _passwordController.text;

    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password cannot be empty"),
          backgroundColor: Color(0xFFCF0000),
        ),
      );
      return;
    }

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password must be at least 6 characters"),
          backgroundColor: Color(0xFFCF0000),
        ),
      );
      return;
    }

    if (!RegExp(r'[A-Z]').hasMatch(newPassword)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password must contain uppercase letter"),
          backgroundColor: Color(0xFFCF0000),
        ),
      );
      return;
    }

    final error = await SupabaseService.updatePassword(
      email: currentEmail!,
      newPassword: newPassword,
    );

    if (!mounted) return;

    if (error == null) {
      _passwordController.clear();
      setState(() => _editingField = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password updated"),
          backgroundColor: Color(0xFFCF0000),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFCF0000),
        ),
      );
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => BackdropFilter(
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
                const Text("Delete Account",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text(
                  "This action is permanent.\n\nAll your data will be deleted and cannot be recovered.\n\nDo you really want to continue?",
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 14, color: Colors.black),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
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
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCF0000),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50)),
                          elevation: 0,
                        ),
                        child: const Text("Yes, Delete",
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

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    await SupabaseService.deleteAccount(currentEmail!);

    if (!mounted) return;

    Navigator.pop(context);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
          (route) => false,
    );
  }

  // Foodpanda-style info card
  Widget _buildInfoCard({
    required String label,
    required TextEditingController controller,
    required String fieldKey,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    List<TextInputFormatter>? inputFormatters,
    VoidCallback? onSave,
  }) {
    final isEditing = _editingField == fieldKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _editingField = isEditing ? null : fieldKey;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label + pencil icon row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _editingField = isEditing ? null : fieldKey;
                      });
                    },
                    child: Icon(
                      isEditing ? Icons.close : Icons.edit_outlined,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Value display or edit field
              if (!isEditing)
                Text(
                  isPassword
                      ? '••••••••••'
                      : controller.text.isEmpty
                      ? '—'
                      : controller.text,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else ...[
                TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  obscureText: isPassword ? _obscurePassword : false,
                  autofocus: true,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: 'Enter $label',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.normal,
                    ),
                    suffixIcon: isPassword
                        ? IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                        size: 18,
                      ),
                      onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                      ),
                    )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCF0000),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F7),
        body: SafeArea(
          child: _loading
              ? const Center(
            child: CircularProgressIndicator(color: Color(0xFFCF0000)),
          )
              : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top bar ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: ClipOval(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 20,
                                sigmaY: 20,
                              ),
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
                                child: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Personal details section ───────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildInfoCard(
                        label: 'Name',
                        controller: _nameController,
                        fieldKey: 'name',
                        onSave: _isSaving ? null : _update,
                      ),

                      _buildInfoCard(
                        label: 'Mobile Number',
                        controller: _phoneController,
                        fieldKey: 'phone',
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        onSave: _isSaving ? null : _update,
                      ),

                      _buildInfoCard(
                        label: 'Email',
                        controller: _emailController,
                        fieldKey: 'email',
                        keyboardType: TextInputType.emailAddress,
                        onSave: _updateEmail,
                      ),

                      _buildInfoCard(
                        label: 'Password',
                        controller: _passwordController,
                        fieldKey: 'password',
                        isPassword: true,
                        onSave: _updatePassword,
                      ),

                      const SizedBox(height: 24),

                      // Delete account button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _delete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCF0000),
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Delete Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}