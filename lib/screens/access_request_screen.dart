import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/app_provider.dart';

class AccessRequestScreen extends StatefulWidget {
  const AccessRequestScreen({super.key});

  @override
  State<AccessRequestScreen> createState() => _AccessRequestScreenState();
}

class _AccessRequestScreenState extends State<AccessRequestScreen> {
  final _nameController = TextEditingController();
  final _authService = AuthService();
  
  String? _pendingRequestId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkExistingRequest();
  }

  Future<void> _checkExistingRequest() async {
    final id = await _authService.getPendingRequestId();
    if (mounted) {
      setState(() {
        _pendingRequestId = id;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final id = await _authService.requestAccess(_nameController.text.trim());
      setState(() {
        _pendingRequestId = id;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _onApproved() {
    // Mark as activated locally
    context.read<AppProvider>().activateApp();
    // Navigate home is handled by main.dart wrapper or consumer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _pendingRequestId == null 
                  ? _buildInputForm() 
                  : _buildWaitingScreen(),
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.security, size: 80, color: Colors.indigo),
        const SizedBox(height: 24),
        const Text(
          'Bienvenido a RV',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const Text(
          'Esta aplicación es privada. Para acceder, solicita permiso al administrador.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 48),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Tu Nombre y Apellido',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _submitRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('SOLICITAR ACCESO', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildWaitingScreen() {
    return StreamBuilder<AccessStatus>(
      stream: _authService.statusStream(_pendingRequestId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error de conexión: ${snapshot.error}'));
        }

        final status = snapshot.data ?? AccessStatus.pending;

        if (status == AccessStatus.approved) {
          // Trigger approval logic once
          WidgetsBinding.instance.addPostFrameCallback((_) => _onApproved());
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 80, color: Colors.green),
                SizedBox(height: 24),
                Text('¡Acceso Concedido!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                Text('Entrando al sistema...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        if (status == AccessStatus.rejected) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cancel, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                const Text('Solicitud Rechazada', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const Text('El administrador ha denegado tu solicitud.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () {
                    setState(() => _pendingRequestId = null);
                  },
                  child: const Text('Intentar de nuevo'),
                )
              ],
            ),
          );
        }

        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 32),
              Text(
                'Esperando Aprobación...',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'El administrador debe aprobar tu solicitud desde el panel de control.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
