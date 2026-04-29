import '../database/database_helper.dart';
import '../models/models.dart';
import 'attendance_repository.dart';

/// SQLite implementation of AttendanceRepository
class AttendanceRepositoryImpl implements AttendanceRepository {
  final DatabaseHelper _databaseHelper;

  AttendanceRepositoryImpl(this._databaseHelper);

  @override
  Future<List<AttendanceRecord>> getAll() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_records',
      orderBy: 'date DESC, createdAt DESC',
    );
    return maps.map((map) => AttendanceRecord.fromMap(map)).toList();
  }

  @override
  Future<AttendanceRecord?> getById(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_records',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return AttendanceRecord.fromMap(maps.first);
  }

  @override
  Future<List<AttendanceRecord>> getByEmployeeId(String employeeId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_records',
      where: 'employeeId = ?',
      whereArgs: [employeeId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => AttendanceRecord.fromMap(map)).toList();
  }

  @override
  Future<List<AttendanceRecord>> getByDate(DateTime date) async {
    final db = await _databaseHelper.database;
    final dateString = _dateToIso8601String(date);
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_records',
      where: 'date = ?',
      whereArgs: [dateString],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => AttendanceRecord.fromMap(map)).toList();
  }

  @override
  Future<List<AttendanceRecord>> getByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseHelper.database;
    final startDateString = _dateToIso8601String(startDate);
    final endDateString = _dateToIso8601String(endDate);
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_records',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDateString, endDateString],
      orderBy: 'date DESC, createdAt DESC',
    );
    return maps.map((map) => AttendanceRecord.fromMap(map)).toList();
  }

  @override
  Future<List<AttendanceRecord>> getByEmployeeAndDateRange(
    String employeeId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseHelper.database;
    final startDateString = _dateToIso8601String(startDate);
    final endDateString = _dateToIso8601String(endDate);
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_records',
      where: 'employeeId = ? AND date >= ? AND date <= ?',
      whereArgs: [employeeId, startDateString, endDateString],
      orderBy: 'date DESC, createdAt DESC',
    );
    return maps.map((map) => AttendanceRecord.fromMap(map)).toList();
  }

  @override
  Future<Map<String, List<AttendanceRecord>>> getByEmployeesAndDateRange(
    List<String> employeeIds,
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (employeeIds.isEmpty) return {};

    final db = await _databaseHelper.database;
    final startDateString = _dateToIso8601String(startDate);
    final endDateString = _dateToIso8601String(endDate);

    // Use IN clause with placeholders
    final placeholders = List.filled(employeeIds.length, '?').join(',');
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM attendance_records
      WHERE employeeId IN ($placeholders)
      AND date >= ? AND date <= ?
      ORDER BY date DESC, createdAt DESC
    ''', [...employeeIds, startDateString, endDateString]);

    // Group by employee ID
    final Map<String, List<AttendanceRecord>> result = {};
    for (final map in maps) {
      final record = AttendanceRecord.fromMap(map);
      result.putIfAbsent(record.employeeId, () => []).add(record);
    }

    return result;
  }

  @override
  Future<AttendanceRecord?> getByEmployeeAndDate(
    String employeeId,
    DateTime date,
  ) async {
    final db = await _databaseHelper.database;
    final dateString = _dateToIso8601String(date);
    final List<Map<String, dynamic>> maps = await db.query(
      'attendance_records',
      where: 'employeeId = ? AND date = ?',
      whereArgs: [employeeId, dateString],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return AttendanceRecord.fromMap(maps.first);
  }

  @override
  Future<AttendanceRecord> create(AttendanceRecord record) async {
    final db = await _databaseHelper.database;
    await db.insert('attendance_records', record.toMap());
    return record;
  }

  @override
  Future<AttendanceRecord> update(AttendanceRecord record) async {
    final db = await _databaseHelper.database;
    await db.update(
      'attendance_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
    return record;
  }

  @override
  Future<void> delete(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'attendance_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteByEmployeeId(String employeeId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'attendance_records',
      where: 'employeeId = ?',
      whereArgs: [employeeId],
    );
  }

  @override
  Future<bool> exists(String employeeId, DateTime date) async {
    final record = await getByEmployeeAndDate(employeeId, date);
    return record != null;
  }

  @override
  Future<Map<String, int>> countByTypeForEmployee(
    String employeeId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _databaseHelper.database;
    final startDateString = _dateToIso8601String(startDate);
    final endDateString = _dateToIso8601String(endDate);

    final result = await db.rawQuery('''
      SELECT 
        SUM(CASE WHEN workStatus = 'fullDay' THEN 1 ELSE 0 END) as fullDayCount,
        SUM(CASE WHEN workStatus = 'halfDay' THEN 1 ELSE 0 END) as halfDayCount,
        SUM(CASE WHEN hasNightShift = 1 THEN 1 ELSE 0 END) as nightShiftCount
      FROM attendance_records
      WHERE employeeId = ? AND date >= ? AND date <= ?
    ''', [employeeId, startDateString, endDateString]);

    if (result.isEmpty || result.first['fullDayCount'] == null) {
      return {
        'fullDay': 0,
        'halfDay': 0,
        'nightWork': 0,
      };
    }

    final row = result.first;
    return {
      'fullDay': row['fullDayCount'] as int,
      'halfDay': row['halfDayCount'] as int,
      'nightWork': row['nightShiftCount'] as int,
    };
  }

  // Helper to convert DateTime to ISO8601 string (date only, no time)
  String _dateToIso8601String(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
