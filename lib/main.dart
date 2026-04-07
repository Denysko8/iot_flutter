import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:iot_flutter/screens/home_screen.dart';
import 'package:iot_flutter/screens/login_screen.dart';
import 'package:iot_flutter/services/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load();
  } catch (_) {
    await dotenv.load(fileName: '.env.example');
  }

  // Ініціалізуємо всі залежності
  await ServiceLocator().initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Blinds IoT',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  Future<bool> _shouldAutoLogin() async {
    // Перевірка чи є збережений користувач
    final userRepository = ServiceLocator().userRepository;
    final user = await userRepository.getCurrentUser();

    return user != null;
  }

  void _showNoInternetWarning(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Немає з\'єднання з Інтернетом. '
                'Функціонал може бути обмежений.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<bool>(
        future: _shouldAutoLogin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              final shouldAutoLogin = snapshot.data == true;
              if (shouldAutoLogin) {
                final connectivityService =
                    ServiceLocator().connectivityService;
                final hasConnection =
                    await connectivityService.checkConnection();
                if (!context.mounted) return;
                if (!hasConnection) {
                  _showNoInternetWarning(context);
                  await Future<void>.delayed(const Duration(seconds: 2));
                  if (!context.mounted) return;
                }
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
                );
                return;
              }

              Navigator.pushReplacement(
                context,
                MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
              );
            });
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.window,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Smart Blinds',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 48),
                const CircularProgressIndicator(),
              ],
            ),
          );
        },
      ),
    );
  }
}
