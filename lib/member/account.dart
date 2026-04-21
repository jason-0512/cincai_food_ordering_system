import 'package:flutter/material.dart';
import 'dart:ui';
import 'supabase_service.dart';
import 'login.dart';
import 'profile.dart';
import 'order.dart';
import 'address_selection.dart';

class Account extends StatefulWidget {
  final String email;

  const Account({super.key, required this.email});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  String _name = '';
  bool _loading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await SupabaseService.getProfile(widget.email);

    if (!mounted) return;

    setState(() {
      _name = data?['name'] ?? 'User';
      _userId = data?['id'];
      _loading = false;
    });
  }

  Future<void> _logout() async {
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
                const Text("Logging Out?",
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text(
                  "Are you sure you want to log out?",
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
                        child: const Text("Log Out",
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

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
          (route) => false,
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

              /// ================= TOP BAR =================
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
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.6),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              child: const Icon(Icons.arrow_back),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              /// ================= USER INFO =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _loading
                    ? Container(
                  width: 120,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                )
                    : Text(
                  _name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Profile(email: widget.email),
                      ),
                    );
                    _loadUser(); // refresh after profile edit
                  },
                  child: const Text(
                    "View Profile",
                    style: TextStyle(
                      color: Color(0xFFCF0000),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// ================= ORDERS & ADDRESSES =================
              _buildSectionCard([
                _tile(Icons.receipt_long_outlined, "My Orders", onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Order(email: widget.email),
                    ),
                  );
                }),
                _divider(),
                _tile(
                  Icons.location_on_outlined,
                  "My Addresses",
                  onTap: () {
                    if (_userId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddressSelectionScreen(userId: _userId!, selectionMode: false),
                        ),
                      );
                    }
                  },
                ),
              ]),

              const SizedBox(height: 20),

              /// ================= ABOUT CINCAI =================
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'About Cincai',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              _buildSectionCard([
                _tile(Icons.info_outline, "About Us"),
                _divider(),
                _tile(Icons.menu_book_outlined, "Our Story"),
              ]),

              const SizedBox(height: 20),

              /// ================= GENERAL =================
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "General",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              _buildSectionCard([
                _tile(Icons.help_outline, "Help Centre"),
                _divider(),
                _tile(Icons.phone_outlined, "Contact Us"),
                _divider(),
                _tile(Icons.description_outlined, "Terms & Policies"),
              ]),

              const SizedBox(height: 30),

              /// ================= LOGOUT =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCF0000),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: const Text(
                    "Log Out",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.8)),
            ),
            child: Column(children: children),
          ),
        ),
      ),
    );
  }

  // onTap is optional — tiles without onTap do nothing when tapped
  Widget _tile(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      color: Colors.grey.withOpacity(0.3),
      indent: 16,
      endIndent: 16,
    );
  }
}