import 'package:flutter/material.dart';
import 'app_drawer.dart';

/// A reusable scaffold with an AppBar and shared drawer.
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;

  const AppScaffold({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: const AppDrawer(),
      body: body,
    );
  }
}
