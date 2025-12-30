import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pages/home.dart';
import '../pages/login.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  static const bool _devSkipAuth = bool.fromEnvironment(
    'DEV_SKIP_AUTH',
    defaultValue: false,
  );

  @override
  Widget build(BuildContext context) {
    // For offline/dev UI work without a real Supabase session.
    if (kDebugMode && _devSkipAuth) return const HomePage();

    final supabase = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;
        if (session != null) return const HomePage();
        return LoginPage();
      },
    );
  }
}
