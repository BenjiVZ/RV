import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/invoice.dart';
import '../widgets/animated_bottom_nav.dart';
import 'dart:convert';

import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'history_screen.dart';


class HomeScreen extends StatelessWidget {
  final bool showNav;
  
  const HomeScreen({
    super.key,
    this.showNav = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = isSmallScreen ? 12.0 : 20.0;
    
    return Scaffold(
      // Background handled by Theme (Slate 50)
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, provider, child) {
            final dateFormat = DateFormat('dd/MM/yy');
            final today = dateFormat.format(DateTime.now());

            return Column(
              children: [
                // Elegant Header - Responsive
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding, 
                    isSmallScreen ? 16 : 24, 
                    horizontalPadding, 
                    isSmallScreen ? 16 : 24
                  ),
                  child: Row(
                    children: [
                      // Profile Avatar - Responsive size
                      GestureDetector(
                        onTap: () => _showSettingsDialog(context, provider),
                        child: Container(
                          padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.primary,
                            size: isSmallScreen ? 20 : 24,
                          ),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 12 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hola, ${provider.user?.name ?? "Usuario"}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                                letterSpacing: -0.5,
                                fontSize: isSmallScreen ? 16 : 20,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            Text(
                              'Hoy es $today',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 13,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 8),
                      // Cash Register Button in Header
                      Material(
                        color: provider.isReportOpen
                            ? Colors.red.shade600
                            : Colors.green.shade600,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: () => _handleCashRegister(context, provider),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 12 : 16,
                              vertical: isSmallScreen ? 8 : 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  provider.isReportOpen ? Icons.lock : Icons.lock_open,
                                  color: Colors.white,
                                  size: isSmallScreen ? 18 : 22,
                                ),
                                SizedBox(width: isSmallScreen ? 6 : 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      provider.isReportOpen ? 'Cerrar' : 'Abrir',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmallScreen ? 12 : 14,
                                      ),
                                    ),
                                    Text(
                                      provider.isReportOpen ? 'Abierta' : 'Cerrada',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: isSmallScreen ? 9 : 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Invoice List Header & Content
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x0A000000), // Very subtle shadow
                              blurRadius: 20,
                              offset: Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Facturas Recientes',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), // Slate 900 10%
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${provider.currentInvoices.length}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
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
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: !showNav ? null : Consumer<AppProvider>(
        builder: (context, provider, child) {
          return AnimatedBottomNav(
            items: [
              AnimatedBottomNavItem(
                icon: provider.isReportOpen ? Icons.lock : Icons.lock_open,
                label: provider.isReportOpen ? 'Cerrar' : 'Abrir',
                color: provider.isReportOpen ? Colors.red : Colors.green,
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
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
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
              AnimatedBottomNavItem(
                icon: Icons.people_outline,
                label: 'Clientes',
                color: Colors.teal,
                onTap: () {
                  Navigator.pushNamed(context, '/clients');
                },
              ),
              AnimatedBottomNavItem(
                icon: Icons.history,
                label: 'Historial',
                color: Colors.purple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                },
              ),
              AnimatedBottomNavItem(
                icon: Icons.grid_view_rounded,
                label: 'Herramientas',
                color: Colors.orange,
                onTap: () {
                  Navigator.pushNamed(context, '/tools');
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: !showNav ? null : Consumer<AppProvider>(
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

  Future<void> _handleCashRegister(BuildContext context, AppProvider provider) async {
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
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
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
  }

  Future<void> _exportBackup(BuildContext context, AppProvider provider) async {
    try {
      final jsonString = await provider.exportData();
      final date = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'backup_ventabox_$date.json';
      
      final xFile = XFile.fromData(
        utf8.encode(jsonString),
        name: fileName,
        mimeType: 'application/json',
      );
      
      await SharePlus.instance.share(ShareParams(files: [xFile], text: 'Backup VentaBox $date'));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exportando: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context, AppProvider provider) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        // Warning dialog
        if (context.mounted) {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('⚠️ Restaurar Backup'),
              content: const Text(
                'Esta acción BORRARÁ todos los datos actuales y los reemplazará con el backup.\n\n¿Estás seguro?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('RESTAURAR'),
                ),
              ],
            ),
          );

          if (confirm != true) return;
        }

        // Read file
        // Note: For Android/iOS we often need File object, but for simplicity/web compat we can use bytes if provided, 
        // but FilePicker usually gives path on mobile.
        // Since we are on mobile, we can use standard File io.
        // However, we need to import dart:io.
        // Or simpler: use XFile to read.
        
        final file = XFile(result.files.single.path!);
        final content = await file.readAsString();
        
        if (context.mounted) {
          // Show loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => const Center(child: CircularProgressIndicator()),
          );
          
          final success = await provider.importData(content);
          
          if (context.mounted) {
            Navigator.pop(context); // Pop loading
            Navigator.pop(context); // Pop settings
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? 'Datos restaurados exitosamente' : 'Error al restaurar datos'),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error pick/restore: $e');
    }
  }

  void _showSettingsDialog(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Name Edit
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person, color: Colors.blue.shade700),
              ),
              title: const Text('Editar Nombre'),
              subtitle: Text(provider.user?.name ?? ''),
              onTap: () {
                Navigator.pop(ctx);
                _showEditNameDialog(context, provider);
              },
              trailing: const Icon(Icons.chevron_right),
            ),
            
            const Divider(),
            
            // Backup
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.upload, color: Colors.orange.shade700),
              ),
              title: const Text('Exportar Respaldo (Backup)'),
              subtitle: const Text('Guarda una copia de tus datos'),
              onTap: () {
                Navigator.pop(ctx);
                _exportBackup(context, provider);
              },
            ),
            
            // Restore
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.download, color: Colors.red.shade700),
              ),
              title: const Text('Restaurar Datos'),
              subtitle: const Text('Recupera datos desde un archivo'),
              onTap: () {
                Navigator.pop(ctx);
                _importBackup(context, provider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, AppProvider provider) {
    final controller = TextEditingController(text: provider.user?.name ?? '');
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Nombre'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await provider.updateUser(controller.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
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
    // Helper methods for styling
    MaterialColor getColor(PaymentType type) {
      switch (type) {
        case PaymentType.contado:
          return Colors.green;
        case PaymentType.cashea:
          return Colors.purple;
        case PaymentType.ivoo:
          return Colors.orange;
      }
    }

    IconData getIcon(PaymentType type) {
      switch (type) {
        case PaymentType.contado:
          return Icons.attach_money;
        case PaymentType.cashea:
          return Icons.credit_card;
        case PaymentType.ivoo:
          return Icons.smartphone;
      }
    }

    String getLabel(PaymentType type) {
      switch (type) {
        case PaymentType.contado:
          return 'Contado';
        case PaymentType.cashea:
          return 'Cashea';
        case PaymentType.ivoo:
          return 'IVOO App';
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: getColor(invoice.paymentType).shade200,
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
                  color: getColor(invoice.paymentType).shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  getIcon(invoice.paymentType),
                  color: getColor(invoice.paymentType),
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
                            color: getColor(invoice.paymentType).shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            getLabel(invoice.paymentType),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: getColor(invoice.paymentType).shade700,
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
