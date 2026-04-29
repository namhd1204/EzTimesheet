import '../models/models.dart';

/// Repository interface for MonthlyRate data access
abstract class MonthlyRateRepository {
  /// Get all monthly rates
  Future<List<MonthlyRate>> getAll();

  /// Get monthly rate by ID
  Future<MonthlyRate?> getById(String id);

  /// Get monthly rate by employee and month
  Future<MonthlyRate?> getByEmployeeAndMonth(String employeeId, String month);

  /// Get monthly rates by employee
  Future<List<MonthlyRate>> getByEmployeeId(String employeeId);

  /// Get monthly rates by month
  Future<List<MonthlyRate>> getByMonth(String month);

  /// Create new monthly rate
  Future<MonthlyRate> create(MonthlyRate rate);

  /// Update existing monthly rate
  Future<MonthlyRate> update(MonthlyRate rate);

  /// Delete monthly rate
  Future<void> delete(String id);

  /// Delete monthly rates by employee ID
  Future<void> deleteByEmployeeId(String employeeId);

  /// Check if rate exists for employee and month
  Future<bool> exists(String employeeId, String month);

  /// Get latest monthly rate for employee (any month)
  Future<MonthlyRate?> getLatestRate(String employeeId);
}
