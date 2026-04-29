import '../models/models.dart';

abstract class MonthLockRepository {
  Future<MonthLock?> getLock(String month);
  Future<List<MonthLock>> getAll();
  Future<bool> isLocked(String month);
  Future<void> setLock(String month, bool isLocked);
}
