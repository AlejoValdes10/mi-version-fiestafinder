import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/ff.png', height: 150),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('INICIAR SESIÓN'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text('REGISTRARSE'),
            ),
          ],
        ),
      ),
    );
  }
}
