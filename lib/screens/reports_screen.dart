// Import the Flutter material design library
import 'package:flutter/material.dart';

// Define a stateless widget for the Reports screen
class ReportScreen extends StatelessWidget {
  // Constructor with optional key for widget identification
  const ReportScreen({super.key});

  // This method returns the widget's UI structure
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar provides the top bar with a label
      appBar: AppBar(
        title: const Text('Reportes'), // Title displayed in the AppBar
      ),

      // The main body of the screen
      body: const Center(
        // Center the text widget
        child: Text(
          'Vista de Reportes', // Text to display in the body
          style: TextStyle(fontSize: 24), // Style with font size
        ),
      ),
    );
  }
}
