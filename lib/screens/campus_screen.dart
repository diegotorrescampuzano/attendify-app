import 'package:flutter/material.dart';
import '../widgets/app_scaffold.dart';

/// Campus screen wrapped with AppScaffold and drawer for logout
class CampusScreen extends StatelessWidget {
  const CampusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Campus',
      body: const Center(
        child: Text('Campus content here'),
      ),
    );
  }
}
