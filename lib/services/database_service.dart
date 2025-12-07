import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/invoice.dart';
import '../models/daily_report.dart';
import '../models/client.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'ventas_v3.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE daily_reports ADD COLUMN closedAt TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE clients(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fullName TEXT NOT NULL,
          cedula TEXT NOT NULL UNIQUE,
          phone TEXT NOT NULL
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_reports(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        sessionNumber INTEGER NOT NULL,
        isOpen INTEGER NOT NULL,
        closedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productCount INTEGER NOT NULL,
        totalAmount REAL NOT NULL,
        paymentType TEXT NOT NULL,
        invoiceNumber TEXT,
        date TEXT NOT NULL,
        reportId INTEGER,
        FOREIGN KEY (reportId) REFERENCES daily_reports (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE clients(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        cedula TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL
      )
    ''');
  }

  // User methods
  Future<User?> getUser() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users', limit: 1);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<int> createUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // Daily report methods
  Future<DailyReport?> getOpenReport() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_reports',
      where: 'isOpen = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DailyReport.fromMap(maps.first);
  }

  Future<int> getNextSessionNumber(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    final result = await db.rawQuery(
      'SELECT MAX(sessionNumber) as maxSession FROM daily_reports WHERE date = ?',
      [dateStr],
    );
    final maxSession = result.first['maxSession'] as int?;
    return (maxSession ?? 0) + 1;
  }

  Future<int> openDailyReport(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    final sessionNumber = await getNextSessionNumber(date);
    
    return await db.insert('daily_reports', {
      'date': dateStr,
      'sessionNumber': sessionNumber,
      'isOpen': 1,
    });
  }

  Future<void> closeDailyReport(int reportId) async {
    final db = await database;
    await db.update(
      'daily_reports',
      {
        'isOpen': 0,
        'closedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [reportId],
    );
  }

  Future<void> reopenDailyReport(int reportId) async {
    final db = await database;
    await db.update(
      'daily_reports',
      {
        'isOpen': 1,
        'closedAt': null,
      },
      where: 'id = ?',
      whereArgs: [reportId],
    );
  }

  Future<DailyReport?> getReportById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_reports',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return DailyReport.fromMap(maps.first);
  }

  Future<List<DailyReport>> getClosedReportsByDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_reports',
      where: 'date = ? AND isOpen = 0',
      whereArgs: [dateStr],
      orderBy: 'sessionNumber DESC',
    );
    return maps.map((map) => DailyReport.fromMap(map)).toList();
  }

  // Invoice methods
  Future<int> createInvoice(Invoice invoice) async {
    final db = await database;
    return await db.insert('invoices', invoice.toMap());
  }

  Future<List<Invoice>> getInvoicesByReportId(int reportId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'invoices',
      where: 'reportId = ?',
      whereArgs: [reportId],
    );
    return maps.map((map) => Invoice.fromMap(map)).toList();
  }

  Future<void> deleteInvoice(int id) async {
    final db = await database;
    await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateInvoice(Invoice invoice) async {
    final db = await database;
    await db.update(
      'invoices',
      invoice.toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
  }

  // Client methods
  Future<List<Client>> getAllClients() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clients',
      orderBy: 'fullName ASC',
    );
    return maps.map((map) => Client.fromMap(map)).toList();
  }

  Future<Client?> getClientByCedula(String cedula) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'clients',
      where: 'cedula = ?',
      whereArgs: [cedula],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Client.fromMap(maps.first);
  }

  Future<int> createClient(Client client) async {
    final db = await database;
    return await db.insert('clients', client.toMap());
  }

  Future<void> updateClient(Client client) async {
    final db = await database;
    await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<void> deleteClient(int id) async {
    final db = await database;
    await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }
}
