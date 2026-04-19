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

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Name cannot be empty"),
          backgroundColor: Color(0xFFCF0000),
        ),
      );
      return;
    }

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

    setState(() => _isSaving = false);

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

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
        .hasMatch(newEmail)) {
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
          backgroundColor: Color(0xFFCF0000),
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
          backgroundColor: Color(0xFFCF0000),
        ),
      );
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must press button
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Delete Account"),
        content: const Text(
          "This action is permanent.\n\nAll your data will be deleted and cannot be recovered.\n\nDo you really want to continue?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              "Yes, Delete",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: isPassword ? _obscurePassword : false,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF5F5F7),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: Colors.grey, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide:
          BorderSide(color: Colors.grey.withOpacity(0.4), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: const BorderSide(color: Colors.grey, width: 1),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        suffixIcon: isPassword
            ? Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off
                  : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
        )
            : null,
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
          isDestructive ? Colors.red : const Color(0xFFCF0000),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: _loading
            ? const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFCF0000),
          ),
        )
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= TOP BAR =================
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
                                sigmaX: 20, sigmaY: 20),
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

              const SizedBox(height: 16),

              // ================= FIELDS =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Save Profile
                    _buildField(
                      controller: _nameController,
                      label: 'Name',
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _isSaving
                        ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFCF0000),
                      ),
                    )
                        : _buildButton(
                      label: 'Save Profile',
                      onPressed: _update,
                    ),

                    const SizedBox(height: 32),

                    // Email update
                    const Text(
                      'Update Email',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _emailController,
                      label: 'New Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    _buildButton(
                      label: 'Update Email',
                      onPressed: _updateEmail,
                    ),

                    const SizedBox(height: 32),

                    // Password update
                    const Text(
                      'Update Password',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      controller: _passwordController,
                      label: 'New Password',
                      isPassword: true,
                    ),
                    const SizedBox(height: 16),
                    _buildButton(
                      label: 'Update Password',
                      onPressed: _updatePassword,
                    ),

                    const SizedBox(height: 32),

                    // Delete account
                    _buildButton(
                      label: 'Delete Account',
                      onPressed: _delete,
                      isDestructive: true,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}