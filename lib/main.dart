// Flutter-Imports
import 'package:flutter/material.dart';

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

  // This widget is the root of your application.
  // -------------------------------------------------------------
  // Hier kannst du Themes, App-Namen usw. konfigurieren.
  // Supabase wird bereits im main() initialisiert,
  // du musst hier also nichts weiter anpassen.
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter + Supabase Demo',
      theme: ThemeData(
        // Dies ist das Theme deiner Anwendung.
        // Du kannst hier wie gewohnt Anpassungen vornehmen.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// Der State deines Home Screens.
// -------------------------------------------------------------
// Hier wurde eine neue Methode (_testSupabase) hinzugefügt,
// um die Supabase-Verbindung zu prüfen.
// -------------------------------------------------------------
class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  // Diese Variable speichert die Rückmeldung von Supabase.
  String _dbResponse = '';

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  // 🔍 NEU:
  // Diese Funktion testet, ob Supabase korrekt funktioniert.
  // Sie fragt aus der Tabelle "profiles" ein Datensatzlimit von 1 ab.
  Future<void> _testSupabase() async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .limit(1);

      // Wenn erfolgreich, aktualisieren wir den State.
      setState(() {
        _dbResponse = data.toString();
      });
    } catch (e) {
      // Fehlerbehandlung
      setState(() {
        _dbResponse = 'Fehler: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called,
    // for instance as done by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating
    // rather than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Hier nehmen wir den Titel aus MyHomePage.
        title: Text(widget.title),
      ),
      body: Center(
        // Center ist ein Layout-Widget. Es positioniert den Inhalt mittig.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Bestehender Text:
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 30),

            // 🔧 NEU:
            // Button, um Supabase-Verbindung zu testen.
            ElevatedButton(
              onPressed: _testSupabase,
              child: const Text('Test Supabase Connection'),
            ),

            const SizedBox(height: 10),

            // Anzeige der Supabase-Antwort oder Fehler
            Text(
              _dbResponse.isEmpty ? 'No response yet' : _dbResponse,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),

      // FloatingActionButton bleibt unverändert.
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
