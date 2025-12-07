import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/invoice.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = isSmallScreen ? 12.0 : 20.0;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<AppProvider>(
            builder: (context, provider, child) {
              final dateFormat = DateFormat('dd/MM/yy');
              final today = dateFormat.format(DateTime.now());

              return Stack(
                children: [
                  Column(
                    children: [
                      // Header
                      Padding(
                        padding: EdgeInsets.all(horizontalPadding),
                        child: Row(
                          children: [
                            // Profile icon - tappable to edit
                            GestureDetector(
                              onTap: () => _showEditProfileDialog(context, provider),
                              child: Container(
                                padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: isSmallScreen ? 24 : 28,
                                ),
                              ),
                            ),
                            SizedBox(width: isSmallScreen ? 10 : 16),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showEditProfileDialog(context, provider),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'Hola, ${provider.user?.name ?? ""}',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 16 : 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.edit,
                                          size: isSmallScreen ? 12 : 14,
                                          color: Colors.white.withValues(alpha: 0.6),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Fecha: $today',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 12 : 14,
                                        color: Colors.white.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Report Status Badge
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 8 : 12,
                                vertical: isSmallScreen ? 4 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: provider.isReportOpen
                                    ? Colors.green
                                    : Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    provider.isReportOpen ? 'ABIERTO' : 'CERRADO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isSmallScreen ? 10 : 12,
                                    ),
                                  ),
                                  if (provider.currentReport != null)
                                    Text(
                                      'Caja #${provider.currentReport!.sessionNumber}',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: isSmallScreen ? 8 : 10,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Action Buttons
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                icon: provider.isReportOpen
                                    ? Icons.lock
                                    : Icons.lock_open,
                                label: provider.isReportOpen
                                    ? 'Cerrar Caja'
                                    : 'Abrir Caja',
                                color: provider.isReportOpen
                                    ? Colors.red.shade400
                                    : Colors.green.shade400,
                                onTap: () async {
                                  if (provider.isReportOpen) {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('¿Cerrar caja?'),
                                        content: const Text(
                                          'Se cerrará el reporte del día. ¿Deseas ver el resumen?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancelar'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Cerrar y Ver'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      final reportToShow = provider.currentReport;
                                      await provider.closeReport();
                                      if (context.mounted && reportToShow != null) {
                                        Navigator.pushNamed(
                                          context,
                                          '/report',
                                          arguments: reportToShow.id,
                                        );
                                      }
                                    }
                                  } else {
                                    await provider.openReport();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.people,
                                label: 'Clientes',
                                color: Colors.teal.shade400,
                                onTap: () {
                                  Navigator.pushNamed(context, '/clients');
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.history,
                                label: 'Historial',
                                color: Colors.purple.shade400,
                                onTap: () {
                                  _showHistoryBottomSheet(context, provider);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Invoice List
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Facturas',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                        if (provider.currentReport != null)
                                          Text(
                                            ' (Caja #${provider.currentReport!.sessionNumber})',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${provider.currentInvoices.length}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: !provider.isReportOpen
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.lock_outline,
                                              size: 64,
                                              color: Colors.grey.shade300,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Caja cerrada',
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 8),
                                              child: Text(
                                                'Abre una nueva caja para registrar facturas',
                                                style: TextStyle(
                                                  color: Colors.grey.shade400,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : provider.currentInvoices.isEmpty
                                        ? Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.receipt_long,
                                                  size: 64,
                                                  color: Colors.grey.shade300,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'No hay facturas en esta caja',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only(
                                                      top: 8),
                                                  child: Text(
                                                    'Toca + para agregar una',
                                                    style: TextStyle(
                                                      color: Colors.grey.shade400,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : ListView.builder(
                                            padding: const EdgeInsets.only(
                                              left: 16,
                                              right: 16,
                                              bottom: 100, // Space for floating total
                                            ),
                                            itemCount:
                                                provider.currentInvoices.length,
                                            itemBuilder: (context, index) {
                                              final invoice =
                                                  provider.currentInvoices[index];
                                              return _InvoiceCard(
                                                invoice: invoice,
                                                canDelete: provider.isReportOpen,
                                              );
                                            },
                                          ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Floating Total - only when cash register is open
                  if (provider.isReportOpen && provider.currentInvoices.isNotEmpty)
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 90,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade700,
                              Colors.purple.shade700,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.shade900.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Total del día',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '\$${provider.grandTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${provider.currentInvoices.length} facturas',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '\$${provider.totalContado.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '\$${provider.totalCashea.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (!provider.isReportOpen) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/add-invoice');
            },
            backgroundColor: Colors.blue.shade700,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, AppProvider provider) {
    final controller = TextEditingController(text: provider.user?.name ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Nombre',
            hintText: 'Tu nombre',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await provider.updateUser(controller.text.trim());
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Nombre actualizado'),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showHistoryBottomSheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final closedReports = provider.closedReports;
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.history, color: Colors.purple.shade700),
                      const SizedBox(width: 12),
                      Text(
                        'Cajas Cerradas de Hoy',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: closedReports.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox,
                                size: 48,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No hay cajas cerradas hoy',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: closedReports.length,
                          itemBuilder: (context, index) {
                            final report = closedReports[index];
                            final canEdit = report.canEdit;
                            final timeRemaining = report.editTimeRemaining;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.receipt,
                                    color: Colors.purple.shade700,
                                  ),
                                ),
                                title: Text(
                                  'Caja #${report.sessionNumber}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('dd/MM/yy HH:mm').format(report.closedAt ?? report.date),
                                    ),
                                    if (canEdit && timeRemaining != null)
                                      Text(
                                        'Editable por ${timeRemaining.inHours}h ${timeRemaining.inMinutes % 60}m',
                                        style: TextStyle(
                                          color: Colors.green.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    if (!canEdit)
                                      Text(
                                        'Solo lectura',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (canEdit)
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: Colors.blue.shade600,
                                        ),
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          // Reopen the report for editing
                                          await provider.reopenReport(report.id!);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Caja #${report.sessionNumber} reabierta para editar'),
                                                backgroundColor: Colors.blue.shade600,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        },
                                        tooltip: 'Reabrir para editar',
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.visibility),
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pushNamed(
                                          context,
                                          '/report',
                                          arguments: report.id,
                                        );
                                      },
                                      tooltip: 'Ver reporte',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final bool canDelete;

  const _InvoiceCard({
    required this.invoice,
    required this.canDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCashea = invoice.paymentType == PaymentType.cashea;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCashea ? Colors.purple.shade200 : Colors.green.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: canDelete ? () => _editInvoice(context) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCashea
                      ? Colors.purple.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isCashea ? Icons.credit_card : Icons.attach_money,
                  color: isCashea ? Colors.purple : Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '\$${invoice.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isCashea
                                ? Colors.purple.shade100
                                : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isCashea ? 'Cashea' : 'Contado',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isCashea
                                  ? Colors.purple.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${invoice.productCount} producto${invoice.productCount > 1 ? "s" : ""}${invoice.invoiceNumber != null ? " • Factura #${invoice.invoiceNumber}" : ""}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (canDelete) ...[
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: Colors.blue.shade400),
                  onPressed: () => _editInvoice(context),
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                  onPressed: () => _deleteInvoice(context),
                  tooltip: 'Eliminar',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _editInvoice(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/edit-invoice',
      arguments: invoice,
    );
  }

  Future<void> _deleteInvoice(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar factura?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      context.read<AppProvider>().deleteInvoice(invoice.id!);
    }
  }
}
