import 'package:flutter/material.dart';
import 'package:kneipen_krieger/components/input_fields.dart';
import 'package:kneipen_krieger/components/my_button.dart';

import '../components/auth_db.dart';
import 'register.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  //text editing controllers
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_isLoading) return;

    final emailOrUsername = usernameController.text.trim();
    final password = passwordController.text;

    if (emailOrUsername.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter username/email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthDb().signIn(email: emailOrUsername, password: password);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _goToRegister() async {
    if (_isLoading) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  Future<void> _signInWithOAuth(OAuthProvider provider, String providerName) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: 'com.example.kneipen_krieger://login-callback',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$providerName sign-in failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _oauthButton({
    required String assetPath,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            assetPath,
            height: 26,
            width: 26,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox(width: 26, height: 26);
            },
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 50),

              // Logo
              Image.asset(
                'lib/images/logo2.png',
                width: 240,
                height: 240,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 50),

              const Text(
                'Welcome!',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 25),

              // Username
              InputField(
                controller: usernameController,
                hintText: 'E-mail',
                obscureText: false,
              ),

              // Password
              InputField(
                controller: passwordController,
                hintText: 'Password',
                obscureText: true,
              ),
              const SizedBox(height:10),

              //forgot password?
              Text('Forgot Password?',
              style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height:25),

              //Sign In Button
              MyButton(
                onTap: _isLoading ? null : _signIn,
              ),

              const SizedBox(height: 10),

                //Register Button
              MyButton(
                onTap: _isLoading ? null : _goToRegister,
                text: 'Register',
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _oauthButton(
                    assetPath: 'lib/images/google_logo.png',
                    onTap: _isLoading ? null : () => _signInWithOAuth(OAuthProvider.google, 'Google'),
                  ),
                  const SizedBox(width: 16),
                  _oauthButton(
                    assetPath: 'lib/images/github-mark.png',
                    onTap: _isLoading ? null : () => _signInWithOAuth(OAuthProvider.github, 'GitHub'),
                  ),
                ],
              ),

              if (_isLoading) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
