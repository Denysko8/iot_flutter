import 'package:flutter/material.dart';
import 'package:iot_flutter/screens/home_screen.dart';
import 'package:iot_flutter/screens/register_screen.dart';
import 'package:iot_flutter/services/service_locator.dart';
import 'package:iot_flutter/widgets/custom_button.dart';
import 'package:iot_flutter/widgets/custom_text_field.dart';
import 'package:iot_flutter/widgets/responsive_padding.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Перевірка підключення до Інтернету
      final connectivityService = ServiceLocator().connectivityService;
      final hasConnection = await connectivityService.checkConnection();

      if (!hasConnection) {
        if (!mounted) return;
        _showNoInternetDialog();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userUseCase = ServiceLocator().userUseCase;
      final result = await userUseCase.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (result.success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(builder: (context) => const HomeScreen()),
        );
      } else {
        setState(() {
          _errorMessage = result.errorMessage;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Сталася помилка при логуванні';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showNoInternetDialog() {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.orange),
                SizedBox(width: 8),
                Text('Немає з\'єднання'),
              ],
            ),
            content: const Text(
              'Для входу в систему необхідне підключення до Інтернету. '
              'Будь ласка, перевірте ваше з\'єднання та спробуйте знову.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Зрозуміло'),
              ),
            ],
          ),
    );
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ResponsivePadding(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.window,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Smart Blinds',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 48),
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock,
                    isPassword: true,
                    enabled: !_isLoading,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade400),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  CustomButton(
                    text: _isLoading ? 'Завантаження...' : 'Login',
                    onPressed: _isLoading ? null : _handleLogin,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : _navigateToRegister,
                    child: const Text('Don\'t have an account? Register'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
