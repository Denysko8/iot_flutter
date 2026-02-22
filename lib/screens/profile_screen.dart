import 'package:flutter/material.dart';
import 'package:iot_flutter/screens/login_screen.dart';
import 'package:iot_flutter/widgets/custom_button.dart';
import 'package:iot_flutter/widgets/location_button.dart';
import 'package:iot_flutter/widgets/profile_info_tile.dart';
import 'package:iot_flutter/widgets/responsive_padding.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _location;

  void _handleLocationRequest() {
    // Placeholder for location access logic
    setState(() {
      _location = 'Kyiv, Ukraine';
    });
  }

  void _handleLogout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: ResponsivePadding(
          child: Column(
            children: [
              const SizedBox(height: 32),
              CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  size: 64,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'John Doe',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'john.doe@example.com',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 32),
              LocationButton(
                location: _location,
                onRequestLocation: _handleLocationRequest,
              ),
              const ProfileInfoTile(
                icon: Icons.schedule,
                title: 'Active Schedules',
                value: '2 schedules',
              ),
              const ProfileInfoTile(
                icon: Icons.notifications,
                title: 'Notifications',
                value: 'Enabled',
              ),
              const Spacer(),
              CustomButton(
                text: 'Logout',
                onPressed: () => _handleLogout(context),
                isPrimary: false,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
