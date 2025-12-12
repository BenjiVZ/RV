import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/invoice.dart';
import '../models/daily_report.dart';
import '../models/client.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final AuthService _authService = AuthService();
  
  User? _user;
  List<Invoice> _currentInvoices = [];
  DailyReport? _currentReport;
  List<DailyReport> _closedReports = [];
  List<DailyReport> _history = [];
  List<Client> _clients = [];
  bool _isLoading = true;
  bool _isActivated = false;

  User? get user => _user;
  List<Invoice> get currentInvoices => _currentInvoices;
  DailyReport? get currentReport => _currentReport;
  List<DailyReport> get closedReports => _closedReports;
  List<DailyReport> get history => _history;
  List<Client> get clients => _clients;
  bool get isLoading => _isLoading;
  bool get isActivated => _isActivated;
  bool get isReportOpen => _currentReport?.isOpen ?? false;

  DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _isActivated = prefs.getBool('is_activated') ?? false;

    if (_isActivated) {
      // Security Check: Verify if still approved
      final status = await _authService.checkStatus();
      if (status == AccessStatus.rejected) {
        // REVOKE ACCESS
        await prefs.setBool('is_activated', false);
        _isActivated = false;
      } else {
        _user = await _db.getUser();
        await loadTodayData();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> activateApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_activated', true);
    _isActivated = true;
    notifyListeners();
  }

  Future<void> loadTodayData() async {
    _currentReport = await _db.getOpenReport();
    if (_currentReport != null) {
      _currentInvoices = await _db.getInvoicesByReportId(_currentReport!.id!);
    } else {
      _currentInvoices = [];
    }
    _closedReports = await _db.getClosedReportsByDate(today);
    notifyListeners();
  }

  Future<void> loadHistory() async {
    _history = await _db.getAllClosedReports();
    notifyListeners();
  }

  // Backup & Restore
  Future<String> exportData() async {
    final data = await _db.getAllData();
    return jsonEncode(data);
  }

  Future<bool> importData(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      await _db.restoreData(data);
      await initialize(); // Reload app state
      return true;
    } catch (e) {
      debugPrint('Error importing data: $e');
      return false;
    }
  }

  Future<void> createUser(String name) async {
    final user = User(name: name);
    await _db.createUser(user);
    _user = await _db.getUser();
    notifyListeners();
  }

  Future<void> updateUser(String newName) async {
    if (_user != null) {
      final updatedUser = User(id: _user!.id, name: newName);
      await _db.updateUser(updatedUser);
      _user = await _db.getUser();
      notifyListeners();
    }
  }

  Future<void> reopenReport(int reportId) async {
    await _db.reopenDailyReport(reportId);
    await loadTodayData();
  }

  // Grand total for current session
  double get grandTotal => totalCashea + totalContado + totalIvoo;

  Future<void> openReport() async {
    final reportId = await _db.openDailyReport(today);
    _currentReport = await _db.getReportById(reportId);
    _currentInvoices = [];
    notifyListeners();
  }

  Future<void> closeReport() async {
    if (_currentReport != null) {
      await _db.closeDailyReport(_currentReport!.id!);
      await loadTodayData();
    }
  }

  Future<void> addInvoice(Invoice invoice) async {
    if (_currentReport != null) {
      final invoiceWithReport = Invoice(
        productCount: invoice.productCount,
        totalAmount: invoice.totalAmount,
        paymentType: invoice.paymentType,
        invoiceNumber: invoice.invoiceNumber,
        date: invoice.date,
        reportId: _currentReport!.id,
      );
      await _db.createInvoice(invoiceWithReport);
      await loadTodayData();
    }
  }

  Future<void> deleteInvoice(int id) async {
    await _db.deleteInvoice(id);
    await loadTodayData();
  }

  Future<void> updateInvoice(Invoice invoice) async {
    await _db.updateInvoice(invoice);
    await loadTodayData();
  }

  // Load invoices for a specific report (for viewing closed reports)
  Future<List<Invoice>> getInvoicesForReport(int reportId) async {
    return await _db.getInvoicesByReportId(reportId);
  }

  // Report calculations for current session
  double get totalCashea => _currentInvoices
      .where((i) => i.paymentType == PaymentType.cashea)
      .fold(0.0, (sum, i) => sum + i.totalAmount);

  int get invoiceCountCashea => _currentInvoices
      .where((i) => i.paymentType == PaymentType.cashea)
      .length;

  int get productCountCashea => _currentInvoices
      .where((i) => i.paymentType == PaymentType.cashea)
      .fold(0, (sum, i) => sum + i.productCount);

  double get totalContado => _currentInvoices
      .where((i) => i.paymentType == PaymentType.contado)
      .fold(0.0, (sum, i) => sum + i.totalAmount);

  int get invoiceCountContado => _currentInvoices
      .where((i) => i.paymentType == PaymentType.contado)
      .length;

  int get productCountContado => _currentInvoices
      .where((i) => i.paymentType == PaymentType.contado)
      .fold(0, (sum, i) => sum + i.productCount);

  // IVOO
  double get totalIvoo => _currentInvoices
      .where((i) => i.paymentType == PaymentType.ivoo)
      .fold(0.0, (sum, i) => sum + i.totalAmount);

  int get invoiceCountIvoo => _currentInvoices
      .where((i) => i.paymentType == PaymentType.ivoo)
      .length;

  int get productCountIvoo => _currentInvoices
      .where((i) => i.paymentType == PaymentType.ivoo)
      .fold(0, (sum, i) => sum + i.productCount);

  // Calculate totals for a list of invoices (for closed reports)
  static Map<String, dynamic> calculateTotals(List<Invoice> invoices) {
    return {
      'totalCashea': invoices
          .where((i) => i.paymentType == PaymentType.cashea)
          .fold(0.0, (sum, i) => sum + i.totalAmount),
      'invoiceCountCashea': invoices
          .where((i) => i.paymentType == PaymentType.cashea)
          .length,
      'productCountCashea': invoices
          .where((i) => i.paymentType == PaymentType.cashea)
          .fold(0, (sum, i) => sum + i.productCount),
      'totalContado': invoices
          .where((i) => i.paymentType == PaymentType.contado)
          .fold(0.0, (sum, i) => sum + i.totalAmount),
      'invoiceCountContado': invoices
          .where((i) => i.paymentType == PaymentType.contado)
          .length,
      'productCountContado': invoices
          .where((i) => i.paymentType == PaymentType.contado)
          .fold(0, (sum, i) => sum + i.productCount),
      'totalIvoo': invoices
          .where((i) => i.paymentType == PaymentType.ivoo)
          .fold(0.0, (sum, i) => sum + i.totalAmount),
      'invoiceCountIvoo': invoices
          .where((i) => i.paymentType == PaymentType.ivoo)
          .length,
      'productCountIvoo': invoices
          .where((i) => i.paymentType == PaymentType.ivoo)
          .fold(0, (sum, i) => sum + i.productCount),
    };
  }

  // Client methods
  Future<void> loadClients() async {
    _clients = await _db.getAllClients();
    notifyListeners();
  }

  Future<Client?> getClientByCedula(String cedula) async {
    return await _db.getClientByCedula(cedula);
  }

  Future<bool> addClient(Client client) async {
    // Check if cedula already exists
    final existing = await _db.getClientByCedula(client.cedula);
    if (existing != null) {
      return false; // Client already exists
    }
    await _db.createClient(client);
    await loadClients();
    return true;
  }

  Future<void> updateClient(Client client) async {
    await _db.updateClient(client);
    await loadClients();
  }

  Future<void> deleteClient(int id) async {
    await _db.deleteClient(id);
    await loadClients();
  }
}
