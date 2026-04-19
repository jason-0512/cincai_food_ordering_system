import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'admin/adminPage.dart';
import 'member/home.dart';
import 'member/cart_class.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = 'https://rqpcdmzttshzlwdrodiy.supabase.co';
const String supabaseKey = 'sb_secret_iNEO1r2eTBQVSh-cs9SkCw_EARTiR4M';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  Stripe.publishableKey = 'pk_test_51TJk0YGgJ9NmxvusohNjneMIKQwkOE4JlBfev0rZox6ywzwnRWKfELkPqFJdrM4JWLzo97Pe2gmtZs3VuJ3ya8rg00wUltqVF0';
  await Stripe.instance.applySettings();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MenuCartProvider(),
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const Home(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Login as:'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPage()),
                );
              },
              child: const Text('Admin'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Home()),
                );
              },
              child: const Text('Member'),
            ),
          ],
        ),
      ),
    );
  }
}