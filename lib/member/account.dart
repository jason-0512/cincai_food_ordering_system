import 'package:flutter/material.dart';
import 'dart:ui';
import 'profile.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    //Up Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
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

                    // Account title centered
                    const Center(
                      child: Text(
                        'Account',
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

              // Profile section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //User name
                    const Text(
                      'Oe', //TODO: Replace with Supabase user name
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    //View profile - navigates to Profile page
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const Profile()),
                        );
                      },
                      child: const Text(
                        'View Profile',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFCF0000),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              //Orders & Addresses section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // My Orders
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              onTap: () {
                                // TODO: Navigate to orders page
                              },
                              splashColor: Colors.grey.withOpacity(0.2),
                              leading: const Icon(Icons.receipt_long_outlined, color: Colors.black),
                              title: const Text(
                                'My Orders',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            ),
                          ),

                          Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.withOpacity(0.3)),

                          // My Addresses
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              onTap: () {
                                // TODO: Navigate to addresses page
                              },
                              splashColor: Colors.grey.withOpacity(0.2),
                              leading: const Icon(Icons.location_on_outlined, color: Colors.black),
                              title: const Text(
                                'My Addresses',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // About Cincai section label
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'About Cincai',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // About Cincai section container
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // About Us
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              onTap: () {
                                // TODO: Navigate to About Us
                              },
                              splashColor: Colors.grey.withOpacity(0.2),
                              leading: const Icon(Icons.info_outline, color: Colors.black),
                              title: const Text(
                                'About Us',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            ),
                          ),

                          Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.withOpacity(0.3)),

                          // Our Story
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              onTap: () {
                                // TODO: Navigate to Our Story
                              },
                              splashColor: Colors.grey.withOpacity(0.2),
                              leading: const Icon(Icons.menu_book_outlined, color: Colors.black),
                              title: const Text(
                                'Our Story',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // General section label
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'General',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // General section container
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Help Centre
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              onTap: () {
                                // TODO: Navigate to Help Centre
                              },
                              splashColor: Colors.grey.withOpacity(0.2),
                              leading: const Icon(Icons.help_outline, color: Colors.black),
                              title: const Text(
                                'Help Centre',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            ),
                          ),

                          Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.withOpacity(0.3)),

                          // Contact Us
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              onTap: () {
                                // TODO: Navigate to Contact Us
                              },
                              splashColor: Colors.grey.withOpacity(0.2),
                              leading: const Icon(Icons.phone_outlined, color: Colors.black),
                              title: const Text(
                                'Contact Us',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            ),
                          ),

                          Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.withOpacity(0.3)),

                          // Terms & Policies
                          Material(
                            color: Colors.transparent,
                            child: ListTile(
                              onTap: () {
                                // TODO: Navigate to Terms & Policies
                              },
                              splashColor: Colors.grey.withOpacity(0.2),
                              leading: const Icon(Icons.description_outlined, color: Colors.black),
                              title: const Text(
                                'Terms & Policies',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Log Out button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Log out logic here
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCF0000),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: const Text(
                    'Log Out',
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