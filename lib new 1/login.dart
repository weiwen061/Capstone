import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'classselection.dart';
import 'logout.dart';

// ===================== MAIN =====================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Performance App',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const LoginPage(),
    );
  }
}

// ===================== EMAIL VALIDATION =====================
bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  return emailRegex.hasMatch(email);
}

bool isAllowedDomain(String email) {
  return email.endsWith('@sksi.edu.my');
}

// ===================== LOGIN PAGE =====================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _message = '';
  bool _loading = false;
  bool _obscurePassword = true;

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!isValidEmail(email)) {
      setState(() => _message = 'Invalid email format ❌');
      return;
    }
    if (!isAllowedDomain(email)) {
      setState(() => _message = 'Email domain not allowed ❌');
      return;
    }

    setState(() {
      _loading = true;
      _message = '';
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ClassSelectionPage()),
      );
    } on FirebaseAuthException catch (e) {
      String msg;
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        msg = 'Incorrect email or password ❌';
      } else if (e.code == 'invalid-email') {
        msg = 'Email format is invalid ❌';
      } else if (e.code == 'user-disabled') {
        msg = 'This account has been disabled ❌';
      } else {
        msg = 'Login failed ❌';
      }
      setState(() => _message = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/sksi.jpg', height: 80),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Text('Sign in to continue',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                 _loading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple, // button color
                              foregroundColor: Colors.white,      // text color
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                            child: const Text(
                              'LOGIN',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),

                  const SizedBox(height: 12),
                  Text(_message,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterPage()),
                          );
                        },
                        child: const Text('Create Account',
                            style: TextStyle(color: Colors.orange)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===================== REGISTER PAGE =====================
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
  bool _obscurePassword = true;

void _register() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  // 1️⃣ Validate email format
  if (!isValidEmail(email)) {
    setState(() => _message = 'Invalid email format ❌');
    return;
  }

  // 2️⃣ Validate allowed domain
  if (!isAllowedDomain(email)) {
    setState(() => _message = 'Email domain not allowed ❌');
    return;
  }

  // 3️⃣ Password length check
  if (password.length < 6) {
    setState(() => _message = 'Password must be at least 6 characters ❌');
    return;
  }

  // 4️⃣ Start loading
  setState(() {
    _loading = true;
    _message = '';
  });

  try {
    // 5️⃣ Attempt registration
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 6️⃣ Success
    if (!mounted) return;
    setState(() => _message = 'Account Created ✅');

    // Navigate to class selection page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ClassSelectionPage()),
    );
  } on FirebaseAuthException catch (e) {
    // 7️⃣ Friendly error messages
    String msg;
    switch (e.code) {
      case 'email-already-in-use':
        msg = 'This email is already registered ❌';
        break;
      case 'invalid-email':
        msg = 'Email format is invalid ❌';
        break;
      case 'weak-password':
        msg = 'Password is too weak ❌';
        break;
      case 'operation-not-allowed':
        msg = 'Email/password sign-in not enabled ❌';
        break;
      default:
        msg = e.message ?? 'Registration failed ❌';
    }

    if (mounted) setState(() => _message = msg);
  } catch (e) {
    if (mounted) setState(() => _message = 'Something went wrong ❌');
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Register'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Create Account',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _loading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _register,
                            child: const Text('REGISTER'),
                          ),
                        ),
                  const SizedBox(height: 12),
                  Text(_message,
                      style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
