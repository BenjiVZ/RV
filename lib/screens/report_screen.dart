import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/invoice.dart';
import '../models/daily_report.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<Invoice>? _invoices;
  DailyReport? _report;
  bool _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  Future<void> _loadData() async {
    final reportId = ModalRoute.of(context)?.settings.arguments as int?;
    final provider = context.read<AppProvider>();

    if (reportId != null) {
      // Loading a specific closed report
      _invoices = await provider.getInvoicesForReport(reportId);
      // Get report info from closed reports
      for (var report in provider.closedReports) {
        if (report.id == reportId) {
          _report = report;
          break;
        }
      }
    } else {
      // Current open report
      _invoices = provider.currentInvoices;
      _report = provider.currentReport;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _generateReportText(AppProvider provider) {
    final dateFormat = DateFormat('dd/MM/yy');
    final today = _report?.date ?? DateTime.now();
    final dateStr = dateFormat.format(today);
    
    final invoices = _invoices ?? [];
    final totals = AppProvider.calculateTotals(invoices);
    
    final sessionInfo = _report != null ? ' (Caja #${_report!.sessionNumber})' : '';

    return '''Reporte de ventas$sessionInfo

• Fecha: $dateStr
• Asesor: ${provider.user?.name ?? ''}
• Venta Cashea: \$${(totals['totalCashea'] as double).toStringAsFixed(2)}
• Facturas Cashea: ${totals['invoiceCountCashea']}
• Productos Cashea: ${totals['productCountCashea']}
• Venta contado: \$${(totals['totalContado'] as double).toStringAsFixed(2)}
• Facturas contado: ${totals['invoiceCountContado']}
• Productos contado: ${totals['productCountContado']}

TOTAL DEL DÍA: \$${((totals['totalCashea'] as double) + (totals['totalContado'] as double)).toStringAsFixed(2)}''';
  }

  void _copyReport(AppProvider provider) {
    final text = _generateReportText(provider);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Reporte copiado al portapapeles'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade900,
                Colors.purple.shade800,
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade900,
              Colors.purple.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<AppProvider>(
            builder: (context, provider, child) {
              final dateFormat = DateFormat('dd/MM/yy');
              final today = _report?.date ?? DateTime.now();
              final dateStr = dateFormat.format(today);
              
              final invoices = _invoices ?? [];
              final totals = AppProvider.calculateTotals(invoices);

              return Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Reporte del Día',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (_report != null)
                                Text(
                                  'Caja #${_report!.sessionNumber}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Copy button
                        IconButton(
                          onPressed: () => _copyReport(provider),
                          icon: const Icon(Icons.copy, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                          ),
                          tooltip: 'Copiar reporte',
                        ),
                      ],
                    ),
                  ),

                  // Report Card
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.assessment,
                                      size: 48,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Reporte de Ventas',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_report != null)
                                    Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Caja #${_report!.sessionNumber}',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Report Details
                            _ReportItem(
                              icon: Icons.calendar_today,
                              label: 'Fecha',
                              value: dateStr,
                              color: Colors.blue,
                            ),
                            _ReportItem(
                              icon: Icons.person,
                              label: 'Asesor',
                              value: provider.user?.name ?? '',
                              color: Colors.indigo,
                            ),

                            const SizedBox(height: 16),
                            Divider(color: Colors.grey.shade200, thickness: 2),
                            const SizedBox(height: 16),

                            // Cashea Section
                            _SectionHeader(
                              title: 'Cashea',
                              icon: Icons.credit_card,
                              color: Colors.purple,
                            ),
                            const SizedBox(height: 12),
                            _ReportItem(
                              icon: Icons.attach_money,
                              label: 'Venta Cashea',
                              value: '\$${(totals['totalCashea'] as double).toStringAsFixed(2)}',
                              color: Colors.purple,
                            ),
                            _ReportItem(
                              icon: Icons.receipt_long,
                              label: 'Facturas Cashea',
                              value: '${totals['invoiceCountCashea']}',
                              color: Colors.purple,
                            ),
                            _ReportItem(
                              icon: Icons.shopping_cart,
                              label: 'Productos Cashea',
                              value: '${totals['productCountCashea']}',
                              color: Colors.purple,
                            ),

                            const SizedBox(height: 16),
                            Divider(color: Colors.grey.shade200, thickness: 2),
                            const SizedBox(height: 16),

                            // Contado Section
                            _SectionHeader(
                              title: 'Contado',
                              icon: Icons.money,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 12),
                            _ReportItem(
                              icon: Icons.attach_money,
                              label: 'Venta Contado',
                              value: '\$${(totals['totalContado'] as double).toStringAsFixed(2)}',
                              color: Colors.green,
                            ),
                            _ReportItem(
                              icon: Icons.receipt_long,
                              label: 'Facturas Contado',
                              value: '${totals['invoiceCountContado']}',
                              color: Colors.green,
                            ),
                            _ReportItem(
                              icon: Icons.shopping_cart,
                              label: 'Productos Contado',
                              value: '${totals['productCountContado']}',
                              color: Colors.green,
                            ),

                            const SizedBox(height: 24),
                            Divider(color: Colors.grey.shade200, thickness: 2),
                            const SizedBox(height: 16),

                            // Total
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade700,
                                    Colors.purple.shade700,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'TOTAL DEL DÍA',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '\$${((totals['totalCashea'] as double) + (totals['totalContado'] as double)).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Copy Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _copyReport(provider),
                                icon: const Icon(Icons.copy),
                                label: const Text('Copiar Reporte'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ReportItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ReportItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color.withValues(alpha: 0.6), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }
}
