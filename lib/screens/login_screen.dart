import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/license_service.dart'; // Add this import

const Color primaryColor = Color(0xFF53A09D);
const Color secondaryColor = Color(0xFF607D8B);
const Color backgroundColor = Color(0xFFF0F0E3);
const Color textOnPrimary = Color(0xFFF3E9DC);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;
  bool _isButtonEnabled = false;
  bool _obscurePassword = true;
  bool _licenseValid = true; // Default to true to avoid blocking login while checking
  bool _licenseChecked = false; // Track if license check is complete

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _checkLicenseValidity(); // Check license status on init
  }

  Future<void> _checkLicenseValidity() async {
    try {
      final isValid = await LicenseService.isLicenseValid();
      if (mounted) {
        setState(() {
          _licenseValid = isValid;
          _licenseChecked = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _licenseValid = true; // Fallback to allow login
          _licenseChecked = true;
        });
      }
      print('Error checking license: $e');
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_validateForm);
    _passwordController.removeListener(_validateForm);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validateForm() {
    final isEmailNotEmpty = _emailController.text.trim().isNotEmpty;
    final isPasswordNotEmpty = _passwordController.text.isNotEmpty;
    final shouldEnable = isEmailNotEmpty && isPasswordNotEmpty;

    if (_isButtonEnabled != shouldEnable) {
      setState(() {
        _isButtonEnabled = shouldEnable;
      });
    }
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final result = await AuthService.login(email, password);

    if (result == null) {
      final userData = await FirestoreService.getUserProfile();
      print("Usuario autenticado con refId: ${userData?['refId']}");

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Disable button if license is invalid or not checked yet
    final isLoginDisabled = !_licenseValid || !_licenseChecked || !_isButtonEnabled || _loading;

    return Scaffold(
      backgroundColor: secondaryColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/attendify_logo.png',
                  height: 100,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bienvenido a Attendify',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'La app diseñada para que los docentes realicen la asistencia de forma fácil y rápida.',
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Show license warning if invalid
                if (!_licenseValid) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Text(
                      'La licencia ha expirado o está inactiva. Contacte al administrador.',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_error != null) ...[
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: const Icon(Icons.email, color: primaryColor),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock, color: primaryColor),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: primaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoginDisabled ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLoginDisabled ? Colors.grey.shade400 : primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 6,
                      shadowColor: primaryColor.withOpacity(0.5),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: textOnPrimary)
                        : const Text(
                      'Iniciar sesión',
                      style: TextStyle(fontSize: 18, color: textOnPrimary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
