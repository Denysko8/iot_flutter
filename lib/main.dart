import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:iot_flutter/screens/home_screen.dart';
import 'package:iot_flutter/screens/login_screen.dart';
import 'package:iot_flutter/services/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

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

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    // Перевірка чи є збережений користувач
    final userRepository = ServiceLocator().userRepository;
    final user = await userRepository.getCurrentUser();

    if (user != null) {
      // Користувач є, перевіряємо з'єднання
      final connectivityService = ServiceLocator().connectivityService;
      final hasConnection = await connectivityService.checkConnection();

      if (!mounted) return;

      if (!hasConnection) {
        // Немає з'єднання - показуємо попередження, але дозволяємо доступ
        _showNoInternetWarning();
        await Future<void>.delayed(const Duration(seconds: 2));
      }

      // Переходимо на домашній екран
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (context) => const HomeScreen()),
      );
    } else {
      // Немає збереженого користувача - йдемо на логін
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _showNoInternetWarning() {
    if (!mounted) return;
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
      body: Center(
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
      ),
    );
  }
}
