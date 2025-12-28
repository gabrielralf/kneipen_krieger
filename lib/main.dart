// Flutter-Imports
import 'package:flutter/material.dart';
import 'components/auth_gate.dart';

// Supabase SDK importieren (neu hinzugefügt)
import 'package:supabase_flutter/supabase_flutter.dart';

// Der Einstiegspunkt deiner App.
// Hier wird Supabase initialisiert, bevor runApp() aufgerufen wird.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase-Initialisierung:
  await Supabase.initialize(
    url: 'https://lwkkmguwoqrtazwemdaq.supabase.co', // <- deine Supabase-Projekt-URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx3a2ttZ3V3b3FydGF6d2VtZGFxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIzMzU4NTYsImV4cCI6MjA3NzkxMTg1Nn0.HrlZtiJfVrD8eQ55Rmy8qBqw3GmVFq431bFyLBaBWew',);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KneipenKrieger',
      theme: ThemeData(
        // Dies ist das Theme deiner Anwendung.
        // Du kannst hier wie gewohnt Anpassungen vornehmen.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthGate(),
    );
  }
}
