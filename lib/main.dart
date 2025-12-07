import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/app_provider.dart';
import 'models/invoice.dart';
import 'screens/registration_screen.dart';
import 'screens/home_screen.dart';
import 'screens/invoice_form_screen.dart';
import 'screens/report_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/clients_screen.dart';
import 'screens/access_request_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TODO: PASTE YOUR SUPABASE KEYS HERE
  const supabaseUrl = 'https://fxibqlqcaoyyanvnzana.supabase.co';
  const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ4aWJxbHFjYW95eWFudm56YW5hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxMjk2OTUsImV4cCI6MjA4MDcwNTY5NX0.0LkpXaUE6mxPkExUgrh_lpFY3XQW0xp1dFzDstTiGmU';

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  } catch (e) {
    // debugPrint('Supabase init error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: MaterialApp(
        title: 'VentaBox',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: const AppInitializer(),
        routes: {
          '/registration': (context) => const RegistrationScreen(),
          '/home': (context) => const HomeScreen(),
          '/add-invoice': (context) => const InvoiceFormScreen(),
          '/report': (context) => const ReportScreen(),
          '/clients': (context) => const ClientsScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/edit-invoice') {
            final invoice = settings.arguments as Invoice;
            return MaterialPageRoute(
              builder: (context) => InvoiceFormScreen(invoiceToEdit: invoice),
            );
          }
          return null;
        },
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;
  bool _showSplash = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      context.read<AppProvider>().initialize();
    }
  }

  void _onSplashComplete() {
    if (mounted) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar splash animado primero
    if (_showSplash) {
      return SplashScreen(onComplete: _onSplashComplete);
    }

    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF5F5F5),
                    Color(0xFFFFFFFF),
                  ],
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        // Check if app is activated via Supabase
        if (!provider.isActivated) {
          return const AccessRequestScreen();
        }

        if (provider.user == null) {
          return const RegistrationScreen();
        }

        return const HomeScreen();
      },
    );
  }
}
