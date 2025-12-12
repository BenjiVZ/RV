import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/invoice.dart';

void showInvoiceFormSheet(BuildContext context, {Invoice? invoiceToEdit}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => InvoiceFormSheet(invoiceToEdit: invoiceToEdit),
  );
}

class InvoiceFormSheet extends StatefulWidget {
  final Invoice? invoiceToEdit;

  const InvoiceFormSheet({super.key, this.invoiceToEdit});

  @override
  State<InvoiceFormSheet> createState() => _InvoiceFormSheetState();
}

class _InvoiceFormSheetState extends State<InvoiceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _productCountController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  PaymentType _paymentType = PaymentType.contado;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.invoiceToEdit != null) {
      _isEditing = true;
      _productCountController.text = widget.invoiceToEdit!.productCount.toString();
      _totalAmountController.text = widget.invoiceToEdit!.totalAmount.toString();
      _invoiceNumberController.text = widget.invoiceToEdit!.invoiceNumber ?? '';
      _paymentType = widget.invoiceToEdit!.paymentType;
    }
  }

  @override
  void dispose() {
    _productCountController.dispose();
    _totalAmountController.dispose();
    _invoiceNumberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    if (_isEditing) {
      final updatedInvoice = Invoice(
        id: widget.invoiceToEdit!.id,
        productCount: int.parse(_productCountController.text),
        totalAmount: double.parse(_totalAmountController.text),
        paymentType: _paymentType,
        invoiceNumber: _invoiceNumberController.text.isNotEmpty
            ? _invoiceNumberController.text
            : null,
        date: widget.invoiceToEdit!.date,
        reportId: widget.invoiceToEdit!.reportId,
      );
      await context.read<AppProvider>().updateInvoice(updatedInvoice);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Factura actualizada exitosamente'),
            backgroundColor: Colors.blue.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else {
      final invoice = Invoice(
        productCount: int.parse(_productCountController.text),
        totalAmount: double.parse(_totalAmountController.text),
        paymentType: _paymentType,
        invoiceNumber: _invoiceNumberController.text.isNotEmpty
            ? _invoiceNumberController.text
            : null,
        date: DateTime.now(),
      );

      await context.read<AppProvider>().addInvoice(invoice);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Factura registrada exitosamente'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Container(
      height: isSmallScreen 
          ? screenHeight * 0.90 
          : screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isEditing ? Icons.edit : Icons.receipt_long,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'Editar Factura' : 'Nueva Factura',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isEditing ? 'Modifica los datos' : 'Completa los datos',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(height: isSmallScreen ? 24 : 32),

          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Count
                    _buildLabel('Cantidad de Productos'),
                    _buildTextField(
                      controller: _productCountController,
                      hint: 'Ej: 5',
                      icon: Icons.shopping_cart,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa la cantidad';
                        }
                        if (int.tryParse(value) == null || int.parse(value) <= 0) {
                          return 'Número inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Total Amount
                    _buildLabel('Monto Total (\$)'),
                    _buildTextField(
                      controller: _totalAmountController,
                      hint: 'Ej: 150.00',
                      icon: Icons.attach_money,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el monto';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Monto inválido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Payment Type
                    _buildLabel('Tipo de Pago'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PaymentTypeButton(
                            icon: Icons.attach_money,
                            label: 'Contado',
                            isSelected: _paymentType == PaymentType.contado,
                            color: Colors.green,
                            onTap: () => setState(() => _paymentType = PaymentType.contado),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PaymentTypeButton(
                            icon: Icons.credit_card,
                            label: 'Cashea',
                            isSelected: _paymentType == PaymentType.cashea,
                            color: Colors.purple,
                            onTap: () => setState(() => _paymentType = PaymentType.cashea),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PaymentTypeButton(
                            icon: Icons.smartphone,
                            label: 'IVOO',
                            isSelected: _paymentType == PaymentType.ivoo,
                            color: Colors.orange,
                            onTap: () => setState(() => _paymentType = PaymentType.ivoo),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Invoice Number
                    _buildLabel('Número de Factura (Opcional)'),
                    _buildTextField(
                      controller: _invoiceNumberController,
                      hint: 'Ej: 001234',
                      icon: Icons.receipt,
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),

          // Submit Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEditing ? Colors.blue.shade700 : Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isEditing ? Icons.save : Icons.add),
                          const SizedBox(width: 8),
                          Text(
                            _isEditing ? 'Guardar Cambios' : 'Guardar Factura',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }
}

class _PaymentTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _PaymentTypeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? color.withValues(alpha: 0.15) : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? color : Colors.grey.shade500,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
