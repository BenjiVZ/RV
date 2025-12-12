import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/app_provider.dart';
import 'models/invoice.dart';
import 'screens/registration_screen.dart';
import 'screens/invoice_form_screen.dart';
import 'screens/report_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/clients_screen.dart';
import 'screens/access_request_screen.dart';
import 'screens/tools_screen.dart';
import 'screens/tools/cashea_calculator_screen.dart';
import 'screens/tools/currency_converter_screen.dart';
import 'screens/tools/discount_calculator_screen.dart';
import 'widgets/main_scaffold.dart';

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
          // Modern Slate Theme
          useMaterial3: true,
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate 50
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F172A), // Slate 900
            primary: const Color(0xFF0F172A),
            secondary: const Color(0xFF334155), // Slate 700
            surface: Colors.white,
            error: const Color(0xFFEF4444),
          ),
          
          // AppBar Theme
          appBarTheme: const AppBarTheme(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Color(0xFF0F172A),
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),

          // Card Theme
          cardTheme: CardTheme(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFE2E8F0)), // Slate 200
            ),
            margin: EdgeInsets.zero,
          ),

          // Input Decoration
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF1F5F9), // Slate 100
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
            ),
          ),

          // Elevated Button
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        home: const AppInitializer(),
        routes: {
          '/registration': (context) => const RegistrationScreen(),
          '/home': (context) => const MainScaffold(),
          '/add-invoice': (context) => const InvoiceFormScreen(),
          '/report': (context) => const ReportScreen(),
          '/clients': (context) => const ClientsScreen(),
          '/tools': (context) => const ToolsScreen(),
          '/tools/cashea-calculator': (context) => const CasheaCalculatorScreen(),
          '/tools/currency-converter': (context) => const CurrencyConverterScreen(),
          '/tools/discount-calculator': (context) => const DiscountCalculatorScreen(),
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

        return const MainScaffold();
      },
    );
  }
}
