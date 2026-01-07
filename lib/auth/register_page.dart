import 'package:flutter/material.dart';
import 'auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _message = '';

  void _register() {
    final success = AuthService.register(
      _emailController.text,
      _passwordController.text,
    );

    setState(() {
      _message = success
          ? 'Account Created ✅'
          : 'Email already exists ❌';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Student')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _register,
              child: const Text('Register'),
            ),
            Text(_message),
          ],
        ),
      ),
    );
  }
}