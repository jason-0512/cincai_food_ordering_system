import 'package:flutter/material.dart';
import 'dart:ui';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  // Controllers for each field
  final TextEditingController _nameController = TextEditingController(text: 'Oe Khye Jin');
  final TextEditingController _phoneController = TextEditingController(text: '+60 129200327');
  final TextEditingController _emailController = TextEditingController(text: 'oekj03@gmail.com');
  final TextEditingController _passwordController = TextEditingController(text: '••••••••');

  // Track which field is being edited
  bool _editingName = false;
  bool _editingPhone = false;
  bool _editingEmail = false;
  bool _editingPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Close all editing fields then open the selected one
  void _setEditing(String field) {
    setState(() {
      _editingName = field == 'name';
      _editingPhone = field == 'phone';
      _editingEmail = field == 'email';
      _editingPassword = field == 'password';
    });
  }

  // Close all editing fields
  void _closeAll() {
    setState(() {
      _editingName = false;
      _editingPhone = false;
      _editingEmail = false;
      _editingPassword = false;
    });
  }

  // Helper method to build each profile field card
  Widget _profileField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onEditTap,
    required VoidCallback onSaveTap,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.8),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Value - editable or display
                      isEditing
                          ? TextField(
                        controller: controller,
                        obscureText: obscure,
                        autofocus: true,
                        keyboardType: keyboardType,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      )
                          : Text(
                        obscure ? '••••••••' : controller.text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                // Edit or Save icon
                GestureDetector(
                  onTap: isEditing ? onSaveTap : onEditTap,
                  child: Icon(
                    isEditing ? Icons.check_circle_outline : Icons.edit_outlined,
                    color: isEditing ? const Color(0xFFCF0000) : Colors.grey,
                    size: 22,
                  ),
                ),
              ],
            ),
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Top bar with close button and Profile title
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Close button on left
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
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
                              child: const Icon(Icons.close, color: Colors.black),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Profile title centered
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

              // Personal details heading
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Personal details',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Name field
              _profileField(
                label: 'Name',
                controller: _nameController,
                isEditing: _editingName,
                onEditTap: () => _setEditing('name'),
                onSaveTap: () => _closeAll(),
                keyboardType: TextInputType.name,
              ),

              const SizedBox(height: 16),

              // Phone number field
              _profileField(
                label: 'Phone Number',
                controller: _phoneController,
                isEditing: _editingPhone,
                onEditTap: () => _setEditing('phone'),
                onSaveTap: () => _closeAll(),
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 16),

              // Email field
              _profileField(
                label: 'Email',
                controller: _emailController,
                isEditing: _editingEmail,
                onEditTap: () => _setEditing('email'),
                onSaveTap: () => _closeAll(),
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              // Password field
              _profileField(
                label: 'Password',
                controller: _passwordController,
                isEditing: _editingPassword,
                onEditTap: () => _setEditing('password'),
                onSaveTap: () => _closeAll(),
                obscure: true,
              ),

              const SizedBox(height: 32),

              // Delete my account button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Delete account logic here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCF0000),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: const Text(
                    'Delete My Account',
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
      ),
    );
  }
}