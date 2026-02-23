import 'package:flutter/material.dart';
import 'package:iot_flutter/screens/login_screen.dart';
import 'package:iot_flutter/services/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      home: const LoginScreen(),
    );
  }
}
