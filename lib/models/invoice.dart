enum PaymentType { contado, cashea, ivoo }

class Invoice {
  final int? id;
  final int productCount;
  final double totalAmount;
  final PaymentType paymentType;
  final String? invoiceNumber;
  final DateTime date;
  final int? reportId; // Links invoice to specific cash register session

  Invoice({
    this.id,
    required this.productCount,
    required this.totalAmount,
    required this.paymentType,
    this.invoiceNumber,
    required this.date,
    this.reportId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productCount': productCount,
      'totalAmount': totalAmount,
      'paymentType': paymentType.name,
      'invoiceNumber': invoiceNumber,
      'date': date.toIso8601String(),
      'reportId': reportId,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      productCount: map['productCount'],
      totalAmount: map['totalAmount'],
      paymentType: PaymentType.values.firstWhere(
        (e) => e.name == map['paymentType'],
      ),
      invoiceNumber: map['invoiceNumber'],
      date: DateTime.parse(map['date']),
      reportId: map['reportId'],
    );
  }
}
