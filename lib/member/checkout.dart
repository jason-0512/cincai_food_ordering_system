import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
const String supabaseUrl = 'https://rqpcdmzttshzlwdrodiy.supabase.co';
const String supabaseKey = 'key';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          'Checkout Page',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}