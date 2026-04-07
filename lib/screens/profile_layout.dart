import 'package:flutter/material.dart';
import 'package:iot_flutter/screens/location_settings_screen.dart';
import 'package:iot_flutter/screens/mqtt_settings_screen.dart';
import 'package:iot_flutter/screens/profile_controller.dart';
import 'package:iot_flutter/widgets/custom_button.dart';
import 'package:iot_flutter/widgets/responsive_padding.dart';

class ProfileLayout extends StatelessWidget {
  final ProfileController controller;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final VoidCallback onToggleEdit;
  final VoidCallback onSaveChanges;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;
  final VoidCallback onLocationUpdated;

  const ProfileLayout({
    required this.controller,
    required this.nameController,
    required this.emailController,
    required this.onToggleEdit,
    required this.onSaveChanges,
    required this.onLogout,
    required this.onDeleteAccount,
    required this.onLocationUpdated,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: Icon(controller.isEditing ? Icons.close : Icons.edit),
            onPressed: onToggleEdit,
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsivePadding(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 32),
                CircleAvatar(
                  radius: 60,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 64,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 24),
                if (controller.isEditing) ...[
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ] else ...[
                  Text(
                    controller.currentUser!.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.currentUser!.email,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
                if (controller.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade400),
                    ),
                    child: Text(
                      controller.errorMessage!,
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                ],
                if (controller.successMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade400),
                    ),
                    child: Text(
                      controller.successMessage!,
                      style: TextStyle(color: Colors.green.shade900),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                // Location info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Локація:',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              controller.currentUser?.city ?? 'Не встановлено',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_location),
                        onPressed: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute<bool>(
                              builder:
                                  (context) => LocationSettingsScreen(
                                    controller: controller,
                                  ),
                            ),
                          );
                          if (result == true) {
                            onLocationUpdated();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                if (controller.isEditing) ...[
                  CustomButton(text: 'Save Changes', onPressed: onSaveChanges),
                  const SizedBox(height: 16),
                ],
                CustomButton(
                  text: 'MQTT Settings',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => const MqttSettingsScreen(),
                      ),
                    );
                  },
                  isPrimary: false,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Logout',
                  onPressed: onLogout,
                  isPrimary: false,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Delete Account',
                  onPressed: onDeleteAccount,
                  isPrimary: false,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
