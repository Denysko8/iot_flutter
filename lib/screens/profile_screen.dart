import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iot_flutter/cubits/profile_cubit.dart';
import 'package:iot_flutter/screens/location_settings_screen.dart';
import 'package:iot_flutter/screens/login_screen.dart';
import 'package:iot_flutter/screens/mqtt_settings_screen.dart';
import 'package:iot_flutter/services/service_locator.dart';
import 'package:iot_flutter/widgets/custom_button.dart';
import 'package:iot_flutter/widgets/responsive_padding.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileCubit>(
      create:
          (_) => ProfileCubit(
            userUseCase: ServiceLocator().userUseCase,
            locationService: ServiceLocator().locationService,
            connectivityService: ServiceLocator().connectivityService,
            mockApiStorageService: ServiceLocator().mockApiStorageService,
          )..loadUser(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Видалити акаунт'),
            content: const Text(
              'Ви впевнені, що хочете видалити акаунт? '
              'Цю дію неможливо скасувати.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Скасувати'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Видалити',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      await context.read<ProfileCubit>().deleteAccount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state.currentUser != null && !state.isEditing) {
          _nameController.text = state.currentUser!.name;
          _emailController.text = state.currentUser!.email;
        }

        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: Colors.green,
            ),
          );
          context.read<ProfileCubit>().clearSuccessMessage();
        }

        if (state.loggedOut || state.accountDeleted) {
          context.read<ProfileCubit>().clearNavigationFlags();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.currentUser == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: Center(
              child: CustomButton(
                text: 'Go to Login',
                onPressed:
                    () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginScreen(),
                      ),
                      (_) => false,
                    ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: Icon(state.isEditing ? Icons.close : Icons.edit),
                onPressed: () => context.read<ProfileCubit>().toggleEditMode(),
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
                    if (state.isEditing) ...[
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ] else ...[
                      Text(
                        state.currentUser!.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(state.currentUser!.email),
                    ],
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        state.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text('Локація'),
                      subtitle: Text(
                        state.currentUser?.city ?? 'Не встановлено',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_location),
                        onPressed: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute<bool>(
                              builder:
                                  (_) => BlocProvider.value(
                                    value: context.read<ProfileCubit>(),
                                    child: const LocationSettingsScreen(),
                                  ),
                            ),
                          );
                          if (!context.mounted) return;
                          if (result == true) {
                            await context.read<ProfileCubit>().loadUser();
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (state.isEditing)
                      CustomButton(
                        text: 'Save Changes',
                        onPressed:
                            () => context.read<ProfileCubit>().saveChanges(
                              _nameController.text.trim(),
                              _emailController.text.trim(),
                            ),
                      ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'MQTT Settings',
                      isPrimary: false,
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const MqttSettingsScreen(),
                            ),
                          ),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Logout',
                      isPrimary: false,
                      onPressed: () => context.read<ProfileCubit>().logout(),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Delete Account',
                      isPrimary: false,
                      onPressed: () => _confirmDelete(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
