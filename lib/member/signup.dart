import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'supabase_service.dart';
import 'login.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showSnackBar("Invalid email format");
      return;
    }

    if (password.length < 6) {
      _showSnackBar("Password must be at least 6 characters");
      return;
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      _showSnackBar("Password must contain uppercase letter");
      return;
    }

    setState(() => _isLoading = true);

    final error = await SupabaseService.signUp(
      name: name,
      phone: phone,
      email: email,
      password: password,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (error != null) {
      _showSnackBar(error);
      return;
    }

    _showSnackBar("Account created successfully");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFCF0000),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Top bar with back button and title
              Stack(
                alignment: Alignment.center,
                children: [
                  // Back button
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
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Sign up title
                  const Center(
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Personal details heading
              const Center(
                child: Text(
                  'Personal details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Name field
              TextField(
                controller: _nameController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Name',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide:
                    const BorderSide(color: Colors.grey, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.4), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide:
                    const BorderSide(color: Colors.grey, width: 1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                ),
              ),

              const SizedBox(height: 20),

              // Phone field
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: InputDecoration(
                  hintText: 'Mobile Number',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide:
                    const BorderSide(color: Colors.grey, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.4), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide:
                    const BorderSide(color: Colors.grey, width: 1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                ),
              ),

              const SizedBox(height: 20),

              // Email field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide:
                    const BorderSide(color: Colors.grey, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.4), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide:
                    const BorderSide(color: Colors.grey, width: 1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                ),
              ),

              const SizedBox(height: 20),

              // Password field with show/hide toggle
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide:
                    const BorderSide(color: Colors.grey, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: BorderSide(
                        color: Colors.grey.withOpacity(0.4), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide:
                    const BorderSide(color: Colors.grey, width: 1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Already have an account
              Row(
                children: [
                  const Text(
                    'Already have an account?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      '\tLogin',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFCF0000),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFCF0000),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Sign Up button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCF0000),
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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