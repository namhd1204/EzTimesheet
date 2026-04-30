import '../models/models.dart';
import '../repositories/repositories.dart';
import '../utils/utils.dart';

/// Result of a single-date attendance load — employees + lock state in one shot
class AttendanceDayView {
  final Map<String, AttendanceRecord?> attendanceMap;
  final bool isMonthLocked;

  const AttendanceDayView({
    required this.attendanceMap,
    required this.isMonthLocked,
  });
}

/// Service for attendance management
class AttendanceService {
  final AttendanceRepository _attendanceRepository;
  final EmployeeRepository _employeeRepository;
  final MonthLockRepository _monthLockRepository;

  AttendanceService(
    this._attendanceRepository,
    this._employeeRepository,
    this._monthLockRepository,
  );

  /// Record attendance for employee
  /// Returns the created attendance record
  Future<AttendanceRecord> recordAttendance(
    String employeeId,
    DateTime date, {
    WorkStatus workStatus = WorkStatus.none,
    bool hasNightShift = false,
  }) async {
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

      // Check for existing attendance
      final existing = await _attendanceRepository.getByEmployeeAndDate(
        employeeId,
        attendanceDate,
      );

      if (existing != null) {
        // Update existing record
        final updated = existing.copyWith(
          workStatus: workStatus,
          hasNightShift: hasNightShift,
          updatedAt: DateTime.now(),
        );
        return await _attendanceRepository.update(updated);
      }

      // Create new attendance record
      final record = AttendanceRecord(
        employeeId: employeeId,
        date: attendanceDate,
        workStatus: workStatus,
        hasNightShift: hasNightShift,
      );

      return await _attendanceRepository.create(record);
    } catch (e) {
      if (e is AttendanceException) rethrow;
      throw AttendanceException('Lỗi: Không thể ghi nhận chấm công. $e');
    }
  }

  /// Update attendance status
  /// Returns the updated attendance record
  Future<AttendanceRecord> updateAttendanceStatus(
    String employeeId,
    DateTime date, {
    WorkStatus? workStatus,
    bool? hasNightShift,
  }) async {
    try {
      final attendanceDate = DateTime(date.year, date.month, date.day);
      final existing = await _attendanceRepository.getByEmployeeAndDate(
        employeeId,
        attendanceDate,
      );

      if (existing == null) {
        // If it doesn't exist, create a new one with the provided values
        return await recordAttendance(
          employeeId,
          attendanceDate,
          workStatus: workStatus ?? WorkStatus.none,
          hasNightShift: hasNightShift ?? false,
        );
      }

      // Update record
      final updated = existing.copyWith(
        workStatus: workStatus ?? existing.workStatus,
        hasNightShift: hasNightShift ?? existing.hasNightShift,
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

  /// Get raw attendance list for all employees on specific date
  Future<List<AttendanceRecord>> getAllRecordsForDate(DateTime date) async {
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

  /// Batch load attendance + month lock for a date — replaces N+1 in Screen.
  Future<AttendanceDayView> getAttendanceDayView(
    List<String> employeeIds,
    DateTime date,
  ) async {
    final attendanceDate = DateTime(date.year, date.month, date.day);
    final month = DateFormatters.formatMonthForStorage(attendanceDate);

    // Parallel: batch attendance + lock check
    final results = await Future.wait([
      _attendanceRepository.getByEmployeesAndDateRange(
        employeeIds,
        attendanceDate,
        attendanceDate,
      ),
      _monthLockRepository.isLocked(month),
    ]);

    final batchMap = results[0] as Map<String, List<AttendanceRecord>>;
    final isLocked = results[1] as bool;

    // Convert list-per-employee to single-record-per-employee
    final attendanceMap = <String, AttendanceRecord?>{
      for (final id in employeeIds)
        id: batchMap[id]?.isNotEmpty == true ? batchMap[id]!.first : null,
    };

    return AttendanceDayView(
      attendanceMap: attendanceMap,
      isMonthLocked: isLocked,
    );
  }
}

/// Exception for attendance operations
class AttendanceException implements Exception {
  final String message;

  AttendanceException(this.message);

  @override
  String toString() => message;
}
