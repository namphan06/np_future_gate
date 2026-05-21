import 'package:flutter/material.dart';
import 'package:np_future_gate/core/repositories/auth_repository.dart';
import 'package:np_future_gate/core/services/supabase_service.dart';
import 'package:np_future_gate/screens/auth/login_screen.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService.instance;
    final authRepository = AuthRepository();
    final currentUser = supabaseService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authRepository.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Test Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (currentUser != null) ...[
              Text('Email: ${currentUser.email ?? "N/A"}'),
              const SizedBox(height: 8),
              Text('ID: ${currentUser.id}'),
              const SizedBox(height: 8),
              Text('Created: ${currentUser.createdAt}'),
            ],
          ],
        ),
      ),
    );
  }
}