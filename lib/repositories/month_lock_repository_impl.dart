import '../database/database_helper.dart';
import '../models/models.dart';
import 'month_lock_repository.dart';

class MonthLockRepositoryImpl implements MonthLockRepository {
  final DatabaseHelper _databaseHelper;

  MonthLockRepositoryImpl(this._databaseHelper);

  @override
  Future<MonthLock?> getLock(String month) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'month_locks',
      where: 'month = ?',
      whereArgs: [month],
    );

    if (maps.isEmpty) return null;
    return MonthLock.fromMap(maps.first);
  }

  @override
  Future<List<MonthLock>> getAll() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('month_locks');
    return List.generate(maps.length, (i) => MonthLock.fromMap(maps[i]));
  }

  @override
  Future<bool> isLocked(String month) async {
    final lock = await getLock(month);
    return lock?.isLocked ?? false;
  }

  @override
  Future<void> setLock(String month, bool isLocked) async {
    final db = await _databaseHelper.database;
    final existing = await getLock(month);

    if (existing == null) {
      await db.insert('month_locks', {
        'month': month,
        'isLocked': isLocked ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } else {
      await db.update(
        'month_locks',
        {
          'isLocked': isLocked ? 1 : 0,
          'updatedAt': DateTime.now().toIso8601String(),
        },
        where: 'month = ?',
        whereArgs: [month],
      );
    }
  }
}
