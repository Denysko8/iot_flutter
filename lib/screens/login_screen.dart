import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iot_flutter/cubits/auth_cubit.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    context.read<AuthCubit>().login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
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
    return BlocProvider<AuthCubit>(
      create:
          (_) => AuthCubit(
            userUseCase: ServiceLocator().userUseCase,
            connectivityService: ServiceLocator().connectivityService,
            mockApiStorageService: ServiceLocator().mockApiStorageService,
          ),
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state.status == AuthStatus.noInternet) {
            _showNoInternetDialog();
          }
          if (state.status == AuthStatus.success) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state.status == AuthStatus.loading;
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
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock,
                          isPassword: true,
                          enabled: !isLoading,
                        ),
                        if (state.message != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade400),
                            ),
                            child: Text(
                              state.message!,
                              style: TextStyle(color: Colors.red.shade900),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        CustomButton(
                          text: isLoading ? 'Завантаження...' : 'Login',
                          onPressed: isLoading ? null : _handleLogin,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: isLoading ? null : _navigateToRegister,
                          child: const Text('Don\'t have an account? Register'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
