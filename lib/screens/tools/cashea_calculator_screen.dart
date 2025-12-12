import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CasheaCalculatorScreen extends StatefulWidget {
  const CasheaCalculatorScreen({super.key});

  @override
  State<CasheaCalculatorScreen> createState() => _CasheaCalculatorScreenState();
}

class _CasheaCalculatorScreenState extends State<CasheaCalculatorScreen> {
  final _amountController = TextEditingController();
  final _customPercentController = TextEditingController(text: '30');
  
  // 0: Nivel 1 (60%), 1: Nivel 3+ (40%), 2: Promo (20%), 3: Custom
  int _mode = 1; 
  int _installments = 3; 

  @override
  void dispose() {
    _amountController.dispose();
    _customPercentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora Cashea'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade100),
              ),
              child: Row(
                children: [
                   Icon(Icons.info_outline, color: Colors.purple.shade700),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Text(
                       'Calcula tu inicial y cuotas según tu nivel en Cashea.',
                       style: TextStyle(color: Colors.purple.shade900),
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Amount Input
            Text(
              'Precio del Producto (\$)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Ej: 100.00',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // Mode Selection
            Text(
              'Condición de Pago',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _LevelSelector(
                        title: 'Nivel 1',
                        subtitle: 'Inicial 60%',
                        isSelected: _mode == 0,
                        onTap: () => setState(() => _mode = 0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LevelSelector(
                        title: 'Nivel 3+',
                        subtitle: 'Inicial 40%',
                        isSelected: _mode == 1,
                        onTap: () => setState(() => _mode = 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _LevelSelector(
                        title: 'Promo',
                        subtitle: 'Inicial 20%',
                        isSelected: _mode == 2,
                        labelColor: Colors.orange.shade800,
                        backgroundColor: _mode == 2 ? Colors.orange.shade50 : Colors.white,
                        borderColor: _mode == 2 ? Colors.orange : Colors.grey.shade300,
                        onTap: () => setState(() => _mode = 2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _LevelSelector(
                        title: 'Manual',
                        subtitle: 'Tu eliges %',
                        isSelected: _mode == 3,
                        onTap: () => setState(() => _mode = 3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Custom Percentage Input
            if (_mode == 3) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Porcentaje Inicial: '),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _customPercentController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        isDense: true,
                        suffixText: '%',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Installments Selection
            Row(
              children: [
                const Text(
                  'Cantidad de Cuotas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: _installments > 1
                            ? () => setState(() => _installments--)
                            : null,
                      ),
                      Text(
                        '$_installments',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _installments < 24
                            ? () => setState(() => _installments++)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Results
            if (_amountController.text.isNotEmpty && double.tryParse(_amountController.text) != null)
              _buildResults(double.parse(_amountController.text)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(double amount) {
    if (amount <= 0) return const SizedBox.shrink();

    // Logic
    double initialPercent;
    switch (_mode) {
      case 0: // Level 1
        initialPercent = 0.60;
        break;
      case 1: // Level 3+
        initialPercent = 0.40;
        break;
      case 2: // Promo 20%
        initialPercent = 0.20;
        break;
      case 3: // Custom
        final val = double.tryParse(_customPercentController.text) ?? 0;
        initialPercent = val / 100.0;
        if (initialPercent < 0) initialPercent = 0;
        if (initialPercent > 1) initialPercent = 1;
        break;
      default:
        initialPercent = 0.40;
    }
    
    final initialPayment = amount * initialPercent;
    final financedAmount = amount - initialPayment;
    final installmentAmount = financedAmount / _installments;

    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM');

    return Column(
      children: [
        // Main Breakdown Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.purple.shade700, Colors.purple.shade500],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.shade200,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'PAGO INICIAL (${(initialPercent * 100).toStringAsFixed(0)}%)',
                style: TextStyle(
                  color: Colors.purple.shade100,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${initialPayment.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.credit_card, color: Colors.purple.shade100, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Financiamiento: \$${financedAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Installments List
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Cronograma de Cuotas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_installments pagos de \$${installmentAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _installments,
          itemBuilder: (ctx, index) {
            final date = now.add(Duration(days: 14 * (index + 1)));
            return _InstallmentItem(
              number: index + 1,
              date: dateFormat.format(date),
              amount: installmentAmount,
              isLast: index == _installments - 1,
            );
          },
        ),
      ],
    );
  }
}

class _LevelSelector extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  final Color? labelColor;
  final Color? backgroundColor;
  final Color? borderColor;

  const _LevelSelector({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.labelColor,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor ?? (isSelected ? Colors.purple.shade50 : Colors.white),
            border: Border.all(
              color: borderColor ?? (isSelected ? Colors.purple : Colors.grey.shade300),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: labelColor ?? (isSelected ? Colors.purple.shade800 : Colors.grey.shade700),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: isSelected ? Colors.purple.shade600 : Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstallmentItem extends StatelessWidget {
  final int number;
  final String date;
  final double amount;
  final bool isLast;

  const _InstallmentItem({
    required this.number,
    required this.date,
    required this.amount,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 5,
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: Colors.purple.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuota $number',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Vence: $date',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
