import '../models/models.dart';
import '../repositories/repositories.dart';

/// Service for attendance management
class AttendanceService {
  final AttendanceRepository _attendanceRepository;
  final EmployeeRepository _employeeRepository;

  AttendanceService(
    this._attendanceRepository,
    this._employeeRepository,
  );

  /// Record attendance for employee
  /// Returns the created attendance record
  Future<AttendanceRecord> recordAttendance(
    String employeeId,
    DateTime date,
    AttendanceType type,
  ) async {
    try {
      // Validate employee exists
      final employee = await _employeeRepository.getById(employeeId);
      if (employee == null) {
        throw AttendanceException('Lỗi: Không tìm thấy nhân viên');
      }

      // Validate date
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final attendanceDate = DateTime(date.year, date.month, date.day);

      if (attendanceDate.isAfter(today)) {
        throw AttendanceException('Lỗi: Không thể ghi nhận chấm công cho ngày tương lai');
      }

      // Check for duplicate attendance
      final existing = await _attendanceRepository.getByEmployeeAndDate(
        employeeId,
        attendanceDate,
      );

      if (existing != null) {
        throw AttendanceException(
          'Lỗi: Đã có bản ghi chấm công cho nhân viên này vào ngày này',
        );
      }

      // Create attendance record
      final record = AttendanceRecord(
        employeeId: employeeId,
        date: attendanceDate,
        attendanceType: type,
      );

      return await _attendanceRepository.create(record);
    } catch (e) {
      if (e is AttendanceException) rethrow;
      throw AttendanceException('Lỗi: Không thể ghi nhận chấm công. $e');
    }
  }

  /// Update attendance record
  /// Returns the updated attendance record
  Future<AttendanceRecord> updateAttendance(
    String recordId,
    AttendanceType newType,
  ) async {
    try {
      // Get existing record
      final existing = await _attendanceRepository.getById(recordId);
      if (existing == null) {
        throw AttendanceException('Lỗi: Không tìm thấy bản ghi chấm công');
      }

      // Update record
      final updated = existing.copyWith(
        attendanceType: newType,
        updatedAt: DateTime.now(),
      );

      return await _attendanceRepository.update(updated);
    } catch (e) {
      if (e is AttendanceException) rethrow;
      throw AttendanceException('Lỗi: Không thể cập nhật chấm công. $e');
    }
  }

  /// Delete attendance record
  Future<void> deleteAttendance(String recordId) async {
    try {
      final existing = await _attendanceRepository.getById(recordId);
      if (existing == null) {
        throw AttendanceException('Lỗi: Không tìm thấy bản ghi chấm công');
      }

      await _attendanceRepository.delete(recordId);
    } catch (e) {
      if (e is AttendanceException) rethrow;
      throw AttendanceException('Lỗi: Không thể xóa chấm công. $e');
    }
  }

  /// Get attendance for employee on specific date
  Future<AttendanceRecord?> getAttendance(
    String employeeId,
    DateTime date,
  ) async {
    final attendanceDate = DateTime(date.year, date.month, date.day);
    return await _attendanceRepository.getByEmployeeAndDate(
      employeeId,
      attendanceDate,
    );
  }

  /// Get attendance for all employees on specific date
  Future<List<AttendanceRecord>> getAttendanceForDate(DateTime date) async {
    final attendanceDate = DateTime(date.year, date.month, date.day);
    return await _attendanceRepository.getByDate(attendanceDate);
  }

  /// Get attendance for employee in date range
  Future<List<AttendanceRecord>> getAttendanceForEmployeeInRange(
    String employeeId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _attendanceRepository.getByDateRange(startDate, endDate);
  }

  /// Get attendance summary for employee in month
  /// Returns map of attendance type to count
  Future<Map<String, int>> getAttendanceSummary(
    String employeeId,
    String month, // Format: YYYY-MM
  ) async {
    final parts = month.split('-');
    final year = int.parse(parts[0]);
    final monthNum = int.parse(parts[1]);

    final startDate = DateTime(year, monthNum, 1);
    final endDate = DateTime(year, monthNum + 1, 0);

    return await _attendanceRepository.countByTypeForEmployee(
      employeeId,
      startDate,
      endDate,
    );
  }

  /// Get attendance for all employees in date range (batch query)
  /// Returns map of employee ID to list of attendance records
  Future<Map<String, List<AttendanceRecord>>> getAttendanceForAllInRange(
    List<String> employeeIds,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _attendanceRepository.getByEmployeesAndDateRange(
      employeeIds,
      startDate,
      endDate,
    );
  }

  /// Check if attendance exists for employee on date
  Future<bool> hasAttendance(String employeeId, DateTime date) async {
    final attendanceDate = DateTime(date.year, date.month, date.day);
    return await _attendanceRepository.exists(employeeId, attendanceDate);
  }

  /// Get last attendance record for employee
  Future<AttendanceRecord?> getLastAttendance(String employeeId) async {
    final records = await _attendanceRepository.getByEmployeeId(employeeId);
    if (records.isEmpty) return null;
    return records.first; // Records are ordered by date DESC
  }

  /// Undo last attendance record for employee
  Future<AttendanceRecord?> undoLastAttendance(String employeeId) async {
    try {
      final lastRecord = await getLastAttendance(employeeId);
      if (lastRecord == null) {
        throw AttendanceException('Lỗi: Không có bản ghi chấm công để hoàn tác');
      }

      await _attendanceRepository.delete(lastRecord.id);
      return lastRecord;
    } catch (e) {
      if (e is AttendanceException) rethrow;
      throw AttendanceException('Lỗi: Không thể hoàn tác chấm công. $e');
    }
  }
}

/// Exception for attendance operations
class AttendanceException implements Exception {
  final String message;

  AttendanceException(this.message);

  @override
  String toString() => message;
}
