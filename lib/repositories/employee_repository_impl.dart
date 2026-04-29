import '../database/database_helper.dart';
import '../models/models.dart';
import 'employee_repository.dart';

/// SQLite implementation of EmployeeRepository
class EmployeeRepositoryImpl implements EmployeeRepository {
  final DatabaseHelper _databaseHelper;

  EmployeeRepositoryImpl(this._databaseHelper);

  @override
  Future<List<Employee>> getAllActive() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Employee.fromMap(map)).toList();
  }

  @override
  Future<List<Employee>> getAll() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Employee.fromMap(map)).toList();
  }

  @override
  Future<Employee?> getById(String id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Employee.fromMap(maps.first);
  }

  @override
  Future<Employee?> getByNameAndPhone(String name, String phone) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'employees',
      where: 'name = ? AND phone = ? AND isActive = ?',
      whereArgs: [name, phone, 1],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Employee.fromMap(maps.first);
  }

  @override
  Future<Employee> create(Employee employee) async {
    final db = await _databaseHelper.database;
    await db.insert('employees', employee.toMap());
    return employee;
  }

  @override
  Future<Employee> update(Employee employee) async {
    final db = await _databaseHelper.database;
    await db.update(
      'employees',
      employee.toMap(),
      where: 'id = ?',
      whereArgs: [employee.id],
    );
    return employee;
  }

  @override
  Future<void> delete(String id) async {
    final db = await _databaseHelper.database;
    await db.update(
      'employees',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> permanentDelete(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<int> countActive() async {
    final db = await _databaseHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM employees WHERE isActive = ?',
      [1],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
