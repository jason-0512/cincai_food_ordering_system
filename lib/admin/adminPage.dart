import 'package:cincai_food_ordering_system/admin/product_management.dart';
import 'package:cincai_food_ordering_system/admin/promotion_management.dart';
import 'package:cincai_food_ordering_system/member/home.dart';
import 'package:flutter/material.dart';
import 'package:cincai_food_ordering_system/admin/audit_log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPage extends StatelessWidget {
  final int userId;

  const AdminPage({
    super.key,
    required this.userId,
  });

  @override

  Future<void> _logout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out',
                style: TextStyle(
                    color: Color(0xFFCF0000), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Home()),
            (route) => false,
      );
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: const Color(0xFFCF0000),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _sectionLabel('Catalogue'),
          _adminTile(
            context,
            icon: Icons.grid_view_rounded,
            title: 'Product Management',
            subtitle: 'Add, edit and remove menu items',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductManagement(adminId: userId)),
            ),
          ),
          const SizedBox(height: 10),
          _adminTile(
            context,
            icon: Icons.card_giftcard_rounded,
            title: 'Promotion Management',
            subtitle: 'Manage discount codes and offers',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PromotionManagement(adminId: userId)),
            ),
          ),
          const SizedBox(height: 20),
          _sectionLabel('System'),
          _adminTile(
            context,
            icon: Icons.description_outlined,
            title: 'Audit Log',
            subtitle: 'Track admin activity',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AuditLog(adminId: userId)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _adminTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback? onTap,
        bool enabled = true,
      }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFFCF0000)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}