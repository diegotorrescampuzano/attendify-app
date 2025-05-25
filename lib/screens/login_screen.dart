// Import Flutter's material UI library
import 'package:flutter/material.dart';

// Import our custom authentication logic
import '../services/auth_service.dart';

// Import FirestoreService to fetch user data after login
import '../services/firestore_service.dart';

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
      print("Login successful, fetching user profile...");

      // 👇 Aquí cargamos los datos del usuario desde Firestore
      final userData = await FirestoreService.getUserProfile();

      // Puedes imprimir el refId para depuración
      print("Usuario autenticado con refId: ${userData?['refId']}");

      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  // Build the login screen UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio de sesión')), // Top bar with title
      body: SingleChildScrollView( // To prevent overflow on small screens
        child: Padding(
          padding: const EdgeInsets.all(20), // Add padding around form
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
            children: [
              // Attendify logo at the top
              Image.asset(
                'assets/images/attendify_logo.png',
                height: 120,
              ),
              const SizedBox(height: 20),

              // Friendly welcome text for teachers
              const Text(
                'Bienvenido a Attendify',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF53a09d), // Primary app color
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'La app diseñada para que los docentes realicen la asistencia de forma fácil y rápida.',
                style: TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

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
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Password input field (obscureText hides characters)
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20), // Space before button
              // Show loading spinner or login button depending on state
              _loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _login, // Call _login when tapped
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF53a09d), // Primary app color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Iniciar sesión',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFFF3E9DC), // Segundo color corporativo claro para texto
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
