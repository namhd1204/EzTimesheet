import 'package:sqflite/sqflite.dart';
import 'package:sqflite_migration/sqflite_migration.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final String dbPath = join(appDocumentsDir.path, 'eztimesheet.db');

    // Define migrations
    final migrations = [
      // Migration 1: Create initial tables
      Migration(
        id: 1,
        up: (Database db) async {
          // Create employees table
          await db.execute('''
            CREATE TABLE employees (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              phone TEXT,
              photoPath TEXT,
              createdAt TEXT NOT NULL,
              isActive INTEGER NOT NULL DEFAULT 1
            )
          ''');

          // Create attendance_records table
          await db.execute('''
            CREATE TABLE attendance_records (
              id TEXT PRIMARY KEY,
              employeeId TEXT NOT NULL,
              date TEXT NOT NULL,
              attendanceType TEXT NOT NULL,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL,
              FOREIGN KEY (employeeId) REFERENCES employees (id) ON DELETE CASCADE
            )
          ''');

          // Create monthly_rates table
          await db.execute('''
            CREATE TABLE monthly_rates (
              id TEXT PRIMARY KEY,
              employeeId TEXT NOT NULL,
              month TEXT NOT NULL,
              dailyRate REAL NOT NULL,
              nightRateMultiplier REAL NOT NULL DEFAULT 1.5,
              createdAt TEXT NOT NULL,
              updatedAt TEXT NOT NULL,
              FOREIGN KEY (employeeId) REFERENCES employees (id) ON DELETE CASCADE,
              UNIQUE(employeeId, month)
            )
          ''');

          // Create indexes for better query performance
          await db.execute('CREATE INDEX idx_attendance_employee_date ON attendance_records(employeeId, date)');
          await db.execute('CREATE INDEX idx_attendance_date ON attendance_records(date)');
          await db.execute('CREATE INDEX idx_rates_employee_month ON monthly_rates(employeeId, month)');
        },
        down: (Database db) async {
          await db.execute('DROP INDEX IF EXISTS idx_rates_employee_month');
          await db.execute('DROP INDEX IF EXISTS idx_attendance_date');
          await db.execute('DROP INDEX IF EXISTS idx_attendance_employee_date');
          await db.execute('DROP TABLE IF EXISTS monthly_rates');
          await db.execute('DROP TABLE IF EXISTS attendance_records');
          await db.execute('DROP TABLE IF EXISTS employees');
        },
      ),
    ];

    // Open database with migrations
    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (Database db, int version) async {
        // Run all migrations
        for (final migration in migrations) {
          await migration.up(db);
        }
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        // Run migrations for each version
        for (final migration in migrations) {
          if (migration.id > oldVersion && migration.id <= newVersion) {
            await migration.up(db);
          }
        }
      },
    );
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Clear all data (for testing)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('attendance_records');
    await db.delete('monthly_rates');
    await db.delete('employees');
  }
}
