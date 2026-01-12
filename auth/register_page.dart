import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _message = '';
  bool _loading = false;

  void _register() async {
    setState(() {
      _loading = true;
      _message = '';
    });

    try {
      // 1. Create the user
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. FORCE LOGOUT immediately so they are not logged in automatically
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      // 3. Go back to Login Page and pass a success message
      Navigator.pop(context, "Account created successfully! Please log in.");

    } on FirebaseAuthException catch (e) {
      setState(() => _message = e.message ?? "Registration failed");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
             TextField(
              controller: _emailController, 
              decoration: const InputDecoration(labelText: "Email"),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController, 
              decoration: const InputDecoration(labelText: "Password"), 
              obscureText: true
            ),
            const SizedBox(height: 20),
            
            _loading 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _register, 
                  child: const Text("Register")
                ),
            
            const SizedBox(height: 12),
            Text(_message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}