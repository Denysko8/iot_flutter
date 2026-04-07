import 'package:flutter/material.dart';
import 'package:iot_flutter/screens/login_screen.dart';
import 'package:iot_flutter/screens/profile_controller.dart';
import 'package:iot_flutter/screens/profile_layout.dart';
import 'package:iot_flutter/widgets/custom_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileController _controller;
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _controller = ProfileController();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _loadUser();
  }

  Future<void> _loadUser() async {
    await _controller.loadUser();
    if (!mounted) return;

    setState(() {
      if (_controller.currentUser != null) {
        _nameController.text = _controller.currentUser!.name;
        _emailController.text = _controller.currentUser!.email;
      }
    });
  }

  void _toggleEditMode() {
    setState(() {
      _controller.toggleEditMode();
    });
  }

  void _handleSaveChanges() async {
    final success = await _controller.saveChanges(
      _nameController.text.trim(),
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _nameController.text = _controller.currentUser!.name;
        _emailController.text = _controller.currentUser!.email;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _controller.clearSuccessMessage();
          });
        }
      });
    }

    setState(() {});
  }

  void _handleDeleteAccount() async {
    final navContext = context;
    final confirmed = await showDialog<bool>(
      context: navContext,
      builder: (context) => AlertDialog(
        title: const Text('Видалити акаунт'),
        content: const Text(
          'Ви впевнені, що хочете видалити акаунт? '
          'Цю дію неможливо буде скасувати.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Скасувати'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Видалити', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _controller.deleteAccount();
      if (success && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  void _handleLogout() async {
    await _controller.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _handleLocationUpdated() async {
    setState(() {
      // Перезавантажити профіль після оновлення локації
    });
    print('ProfileScreen: Локація оновлена');
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_controller.currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Користувач не авторизований'),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Go to Login',
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => false,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ProfileLayout(
      controller: _controller,
      nameController: _nameController,
      emailController: _emailController,
      onToggleEdit: _toggleEditMode,
      onSaveChanges: _handleSaveChanges,
      onLogout: _handleLogout,
      onDeleteAccount: _handleDeleteAccount,
      onLocationUpdated: _handleLocationUpdated,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
