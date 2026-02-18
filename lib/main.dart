import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IoT Flutter Lab 1',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  final TextEditingController _controller = TextEditingController();

  void _handleInput(String value) {
    final cleanValue = value.trim().toLowerCase();

    setState(() {
      // 1. Перевірка на "Avada Kedavra"
      if (cleanValue == 'avada kedavra') {
        _counter = 0;
        _controller.clear();
        return;
      }

      // 2. Спеціальна обробка секретного тексту
      if (cleanValue == 'heisenberg') {
        _counter += 7;
        _controller.clear();
        return;
      }

      // 3. Спроба конвертувати текст у число
      final int? inputNumber = int.tryParse(cleanValue);
      if (inputNumber != null) {
        _counter += inputNumber;
        _controller.clear();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Важливо для пам'яті
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Lab: Magic Input'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Поточне значення лічильника:',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.pinkAccent,
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Введіть число або закляття',
                hintText: 'Напр: 10 або Avada Kedavra',
                prefixIcon: Icon(Icons.edit),
              ),
              onSubmitted: _handleInput, // Спрацьовує при натисканні Enter
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _handleInput(_controller.text),
              icon: const Icon(Icons.bolt),
              label: const Text('Застосувати магію'),
            ),
          ],
        ),
      ),
    );
  }
}
