import 'package:flutter/material.dart';
import 'package:np_future_gate/screens/cv/cv_creation_screen.dart';

/// Example screen showing how to navigate to CV Creation
class CVTestScreen extends StatelessWidget {
  const CVTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test CV System'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'He thong tao CV',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CVCreationScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Tao CV Moi'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'Huong dan:\n'
                '1. Bam "Tao CV Moi"\n'
                '2. Chon Mau CV Chung hoac Theo Linh Vuc\n'
                '3. Neu chon Theo Linh Vuc, chon category trong grid\n'
                '4. Hoac Upload CV tu thiet bi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
