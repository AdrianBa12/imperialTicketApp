import 'package:flutter/material.dart';

import '../widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to search screen after a delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/search');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TurismoImperial'),
      ),
      drawer: const AppDrawer(),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}