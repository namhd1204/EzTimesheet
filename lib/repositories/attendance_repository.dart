import '../models/models.dart';

/// Repository interface for AttendanceRecord data access
abstract class AttendanceRepository {
  /// Get all attendance records
  Future<List<AttendanceRecord>> getAll();

  /// Get attendance record by ID
  Future<AttendanceRecord?> getById(String id);

  /// Get attendance records by employee ID
  Future<List<AttendanceRecord>> getByEmployeeId(String employeeId);

  /// Get attendance records by employee and date range
  Future<List<AttendanceRecord>> getByEmployeeAndDateRange(
    String employeeId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get attendance records by date
  Future<List<AttendanceRecord>> getByDate(DateTime date);

  /// Get attendance records by date range
  Future<List<AttendanceRecord>> getByDateRange(DateTime startDate, DateTime endDate);

  /// Get attendance records by employee and date range (batch query for calendar)
  Future<Map<String, List<AttendanceRecord>>> getByEmployeesAndDateRange(
    List<String> employeeIds,
    DateTime startDate,
    DateTime endDate,
  );

  /// Get attendance record by employee and date
  Future<AttendanceRecord?> getByEmployeeAndDate(String employeeId, DateTime date);

  /// Create new attendance record
  Future<AttendanceRecord> create(AttendanceRecord record);

  /// Update existing attendance record
  Future<AttendanceRecord> update(AttendanceRecord record);

  /// Delete attendance record
  Future<void> delete(String id);

  /// Delete attendance records by employee ID
  Future<void> deleteByEmployeeId(String employeeId);

  /// Check if attendance record exists for employee and date
  Future<bool> exists(String employeeId, DateTime date);

  /// Count attendance records by type for employee in date range
  Future<Map<String, int>> countByTypeForEmployee(
    String employeeId,
    DateTime startDate,
    DateTime endDate,
  );
}
