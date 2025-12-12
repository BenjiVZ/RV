import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final _usdController = TextEditingController();
  final _vesController = TextEditingController();
  
  double? _exchangeRate;
  bool _isLoading = true;
  String? _error;
  DateTime? _lastUpdate;

  @override
  void initState() {
    super.initState();
    _fetchRate();
  }

  @override
  void dispose() {
    _usdController.dispose();
    _vesController.dispose();
    super.dispose();
  }

  Future<void> _fetchRate() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://ve.dolarapi.com/v1/dolares/oficial'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Expecting: {"promedio": 45.5, ...}
        final rate = (data['promedio'] as num).toDouble();
        final dateStr = data['fechaActualizacion'] as String?;
        
        DateTime? updateTime;
        if (dateStr != null) {
            try {
                updateTime = DateTime.parse(dateStr);
            } catch (_) {}
        }

        if (mounted) {
          setState(() {
            _exchangeRate = rate;
            _lastUpdate = updateTime ?? DateTime.now();
            _isLoading = false;
          });
          // Recalculate if fields have values
          if (_usdController.text.isNotEmpty) _onUsdChanged(_usdController.text);
        }
      } else {
        throw 'Error ${response.statusCode}';
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error obteniendo tasa: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onUsdChanged(String value) {
    if (_exchangeRate == null) return;
    if (value.isEmpty) {
      _vesController.text = '';
      return;
    }
    
    final usd = double.tryParse(value);
    if (usd != null) {
      final ves = usd * _exchangeRate!;
      _vesController.value = TextEditingValue(
        text: ves.toStringAsFixed(2),
        selection: TextSelection.collapsed(offset: ves.toStringAsFixed(2).length),
      );
    }
  }

  void _onVesChanged(String value) {
    if (_exchangeRate == null) return;
    if (value.isEmpty) {
      _usdController.text = '';
      return;
    }

    final ves = double.tryParse(value);
    if (ves != null) {
      final usd = ves / _exchangeRate!;
      _usdController.value = TextEditingValue(
        text: usd.toStringAsFixed(2),
        selection: TextSelection.collapsed(offset: usd.toStringAsFixed(2).length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora Divisas'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRate,
            tooltip: 'Actualizar tasa',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Rate Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade600, Colors.teal.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.shade200,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'TASA BCV OFICIAL',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                     const CircularProgressIndicator(color: Colors.white)
                  else if (_error != null)
                     Text(
                       'Error', 
                       style: const TextStyle(color: Colors.white, fontSize: 24),
                     )
                  else
                     Text(
                       'Bs. ${_exchangeRate?.toStringAsFixed(4)}',
                       style: const TextStyle(
                         color: Colors.white,
                         fontSize: 40,
                         fontWeight: FontWeight.bold,
                       ),
                     ),
                  const SizedBox(height: 8),
                  if (_lastUpdate != null && !_isLoading && _error == null)
                    Text(
                      'Actualizado: ${_lastUpdate!.day}/${_lastUpdate!.month} ${_lastUpdate!.hour}:${_lastUpdate!.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Revisa tu conexión',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Converter Fields
            Text(
              'Convertidor',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 20),

            // USD Input
            TextField(
              controller: _usdController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) {
                // Determine if we should update the other field
                // To avoid infinite loops or fighting, we just trigger logic
                // But since we are updating the text controller of the OTHER field, it shouldn't trigger its onChanged if we are careful?
                // Actually TextField onChanged triggers only on user input, not programmatic code updates.
                // So this is safe.
                _onUsdChanged(val);
              },
              decoration: InputDecoration(
                labelText: 'Dólares (USD)',
                prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                suffixText: 'USD',
                suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            
            const Icon(Icons.swap_vert, size: 32, color: Colors.grey),
            
            const SizedBox(height: 24),

            // VES Input
            TextField(
              controller: _vesController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) {
                 _onVesChanged(val);
              },
              decoration: InputDecoration(
                labelText: 'Bolívares (VES)',
                prefixIcon: const Icon(Icons.money, color: Colors.blue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                suffixText: 'Bs',
                suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
