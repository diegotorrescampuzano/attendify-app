// Import Flutter's material UI library
import 'package:flutter/material.dart';

// Import our custom authentication logic
import '../services/auth_service.dart';

// The login screen is a StatefulWidget because it has dynamic behavior (loading, error messages, etc.)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}); // Constructor with optional key

  @override
  State<LoginScreen> createState() => _LoginScreenState(); // Create the widget's state
}

// This class holds the mutable state of the LoginScreen
class _LoginScreenState extends State<LoginScreen> {
  // Controller to read the email input field
  final TextEditingController _emailController = TextEditingController();

  // Controller to read the password input field
  final TextEditingController _passwordController = TextEditingController();

  // Boolean to track whether login is in progress
  bool _loading = false;

  // Optional error message to show if login fails
  String? _error;

  // Method to handle login logic
  Future<void> _login() async {
    // Update UI to show loading and reset previous error
    setState(() {
      _loading = true;
      _error = null;
    });

    // Get trimmed values from input fields
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Call the login function from AuthService
    final result = await AuthService.login(email, password);

    // Once login completes, update loading state and error message
    setState(() {
      _loading = false;
      _error = result; // Will be null if login is successful
    });

    // If login succeeded (no error), navigate to the home screen
    if (result == null) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  // Build the login screen UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')), // Top bar with title
      body: Padding(
        padding: const EdgeInsets.all(20), // Add padding around form
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
          children: [
            // If there's an error, show it as red text
            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 10), // Add spacing after error
            ],
            // Email input field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            // Password input field (obscureText hides characters)
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20), // Space before button
            // Show loading spinner or login button depending on state
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _login, // Call _login when tapped
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
