import '../database/database_helper.dart';
import '../models/models.dart';
import 'monthly_rate_repository.dart';

/// SQLite implementation of MonthlyRateRepository
class MonthlyRateRepositoryImpl implements MonthlyRateRepository {
  final DatabaseHelper _databaseHelper;

  MonthlyRateRepositoryImpl(this._databaseHelper);

  @override
  Future<List<MonthlyRate>> getAll() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'monthly_rates',
      orderBy: 'month DESC, createdAt DESC',
    );
    return maps.map((map) => MonthlyRate.fromMap(map)).toList();
  }

  @override
  Future<MonthlyRate?> getById(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'monthly_rates',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return MonthlyRate.fromMap(maps.first);
  }

  @override
  Future<MonthlyRate?> getByEmployeeAndMonth(
    String employeeId,
    String month,
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'monthly_rates',
      where: 'employeeId = ? AND month = ?',
      whereArgs: [employeeId, month],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return MonthlyRate.fromMap(maps.first);
  }

  @override
  Future<List<MonthlyRate>> getByEmployeeId(String employeeId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'monthly_rates',
      where: 'employeeId = ?',
      whereArgs: [employeeId],
      orderBy: 'month DESC',
    );
    return maps.map((map) => MonthlyRate.fromMap(map)).toList();
  }

  @override
  Future<List<MonthlyRate>> getByMonth(String month) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'monthly_rates',
      where: 'month = ?',
      whereArgs: [month],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => MonthlyRate.fromMap(map)).toList();
  }

  @override
  Future<MonthlyRate> create(MonthlyRate rate) async {
    final db = await _databaseHelper.database;
    try {
      await db.insert('monthly_rates', rate.toMap());
    } catch (e) {
      // Handle unique constraint violation
      if (e.toString().contains('UNIQUE constraint')) {
        throw Exception('Lỗi: Tỷ lệ cho nhân viên này trong tháng này đã tồn tại');
      }
      rethrow;
    }
    return rate;
  }

  @override
  Future<MonthlyRate> update(MonthlyRate rate) async {
    final db = await _databaseHelper.database;
    await db.update(
      'monthly_rates',
      rate.toMap(),
      where: 'id = ?',
      whereArgs: [rate.id],
    );
    return rate;
  }

  @override
  Future<void> delete(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'monthly_rates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteByEmployeeId(String employeeId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'monthly_rates',
      where: 'employeeId = ?',
      whereArgs: [employeeId],
    );
  }

  @override
  Future<bool> exists(String employeeId, String month) async {
    final rate = await getByEmployeeAndMonth(employeeId, month);
    return rate != null;
  }
}
