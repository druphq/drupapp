import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_notifier.dart';
import '../../providers/user_notifier.dart';
import '../../theme/app_colors.dart';
import '../../core/constants/constants.dart';
import '../widgets/custom_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isDriver = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter email and password');
      return;
    }

    bool success;
    if (_isDriver) {
      success = await ref
          .read(authNotifierProvider.notifier)
          .loginWithEmail(email, password);
    } else {
      success = await ref
          .read(authNotifierProvider.notifier)
          .loginWithEmail(email, password);
    }

    if (success && mounted) {
      // Initialize user location
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        await ref
            .read(userNotifierProvider.notifier)
            .loadUserProfile(currentUser.id);
        await ref.read(userNotifierProvider.notifier).updateUserLocation();
      }

      // Navigate to appropriate screen
      if (mounted) {
        if (_isDriver) {
          context.go(AppConstants.driverMapRoute);
        } else {
          context.go(AppConstants.homeRoute);
        }
      }
    } else if (mounted) {
      final error = ref.read(authNotifierProvider).error;
      _showError(error?.toString() ?? 'Login failed');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.local_taxi, size: 80, color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'Welcome Back',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to continue',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Checkbox(
                    value: _isDriver,
                    onChanged: (value) {
                      setState(() {
                        _isDriver = value ?? false;
                      });
                    },
                  ),
                  const Text('Login as Driver'),
                ],
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Sign In',
                onPressed: _handleLogin,
                isLoading: isLoading,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // Quick test login
                  _emailController.text = 'test@example.com';
                  _passwordController.text = 'password';
                },
                child: const Text('Use Test Account'),
              ),
              const SizedBox(height: 24),
              const Text(
                'Demo App - Any email/password works',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
