class DailyReport {
  final int? id;
  final DateTime date;
  final int sessionNumber;
  final bool isOpen;
  final DateTime? closedAt; // Timestamp when the report was closed

  DailyReport({
    this.id,
    required this.date,
    required this.sessionNumber,
    required this.isOpen,
    this.closedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String().split('T')[0],
      'sessionNumber': sessionNumber,
      'isOpen': isOpen ? 1 : 0,
      'closedAt': closedAt?.toIso8601String(),
    };
  }

  factory DailyReport.fromMap(Map<String, dynamic> map) {
    return DailyReport(
      id: map['id'],
      date: DateTime.parse(map['date']),
      sessionNumber: map['sessionNumber'],
      isOpen: map['isOpen'] == 1,
      closedAt: map['closedAt'] != null ? DateTime.parse(map['closedAt']) : null,
    );
  }

  // Check if the report can still be edited (within 6 hours of closing)
  bool get canEdit {
    if (isOpen) return true;
    if (closedAt == null) return false;
    final hoursSinceClosed = DateTime.now().difference(closedAt!).inHours;
    return hoursSinceClosed < 6;
  }

  // Time remaining to edit
  Duration? get editTimeRemaining {
    if (isOpen || closedAt == null) return null;
    final sixHoursAfterClose = closedAt!.add(const Duration(hours: 6));
    final remaining = sixHoursAfterClose.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }
}
