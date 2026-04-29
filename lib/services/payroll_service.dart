import '../models/models.dart';
import '../repositories/repositories.dart';

/// Service for payroll calculations
class PayrollService {
  final AttendanceRepository _attendanceRepository;
  final MonthlyRateRepository _monthlyRateRepository;

  PayrollService(
    this._attendanceRepository,
    this._monthlyRateRepository,
  );

  /// Calculate payroll for employee in a specific month
  /// Returns PayrollResult with breakdown
  Future<PayrollResult> calculatePayroll(
    String employeeId,
    String month, // Format: YYYY-MM
  ) async {
    try {
      // Get monthly rate for employee
      var rate = await _monthlyRateRepository.getByEmployeeAndMonth(
        employeeId,
        month,
      );

      if (rate == null) {
        // Carry-over logic: Get most recent previous rate
        final latestRate = await _monthlyRateRepository.getLatestRate(employeeId);
        if (latestRate != null) {
          // Create new rate for this month based on latest
          rate = MonthlyRate(
            employeeId: employeeId,
            month: month,
            dailyRate: latestRate.dailyRate,
            nightBonus: latestRate.nightBonus,
          );
          await _monthlyRateRepository.create(rate);
        } else {
          throw PayrollException('Lỗi: Chưa cấu hình lương cho nhân viên này trong tháng $month và không có dữ liệu cũ để kế thừa.');
        }
      }

      // Parse month to get date range
      final parts = month.split('-');
      final year = int.parse(parts[0]);
      final monthNum = int.parse(parts[1]);

      final startDate = DateTime(year, monthNum, 1);
      final endDate = DateTime(year, monthNum + 1, 0); // Last day of month

      // Get attendance counts by type
      final counts = await _attendanceRepository.countByTypeForEmployee(
        employeeId,
        startDate,
        endDate,
      );

      // Calculate totals
      final fullDays = counts['fullDay'] ?? 0;
      final halfDays = counts['halfDay'] ?? 0;
      final nightWorkDays = counts['nightWork'] ?? 0;

      // Calculate payroll with overflow protection
      double fullDayTotal = _safeMultiply(rate.dailyRate, fullDays);
      double halfDayTotal = _safeMultiply(rate.dailyRate / 2, halfDays);
      double nightWorkTotal = _safeMultiply(rate.nightBonus, nightWorkDays);

      double total = fullDayTotal + halfDayTotal + nightWorkTotal;

      // Check for overflow
      if (total.isInfinite || total.isNaN) {
        throw PayrollException('Lỗi: Tổng lương vượt quá giới hạn tính toán');
      }

      return PayrollResult(
        employeeId: employeeId,
        month: month,
        dailyRate: rate.dailyRate,
        nightBonus: rate.nightBonus,
        fullDays: fullDays,
        halfDays: halfDays,
        nightWorkDays: nightWorkDays,
        fullDayTotal: fullDayTotal,
        halfDayTotal: halfDayTotal,
        nightWorkTotal: nightWorkTotal,
        total: total,
      );
    } catch (e) {
      if (e is PayrollException) rethrow;
      throw PayrollException('Lỗi: Không thể tính lương. $e');
    }
  }

  /// Calculate payroll for all employees in a specific month
  /// Returns list of PayrollResult for each employee
  Future<List<PayrollResult>> calculatePayrollForAll(
    List<String> employeeIds,
    String month,
  ) async {
    final List<PayrollResult> results = [];

    for (final employeeId in employeeIds) {
      try {
        final result = await calculatePayroll(employeeId, month);
        results.add(result);
      } catch (e) {
        // Skip employees with errors but continue with others
        continue;
      }
    }

    return results;
  }

  /// Get payroll summary for all employees in a specific month
  /// Returns total payroll amount
  Future<double> getTotalPayroll(
    List<String> employeeIds,
    String month,
  ) async {
    final results = await calculatePayrollForAll(employeeIds, month);
    return results.fold<double>(0, (sum, result) => sum + result.total);
  }

  /// Export payroll data to text format
  Future<String> exportPayroll(
    List<String> employeeIds,
    String month,
  ) async {
    final results = await calculatePayrollForAll(employeeIds, month);
    final buffer = StringBuffer();

    buffer.writeln('Bảng lương tháng $month');
    buffer.writeln('=' * 50);
    buffer.writeln();

    for (final result in results) {
      buffer.writeln('Nhân viên ID: ${result.employeeId}');
      buffer.writeln('  Tỷ lệ ngày: ${_formatCurrency(result.dailyRate)}');
      buffer.writeln('  Tiền thưởng làm tối: ${_formatCurrency(result.nightBonus)}');
      buffer.writeln('  Số ngày làm việc: ${result.fullDays}');
      buffer.writeln('  Số nửa ngày: ${result.halfDays}');
      buffer.writeln('  Số ngày làm tối: ${result.nightWorkDays}');
      buffer.writeln('  Tổng lương: ${_formatCurrency(result.total)}');
      buffer.writeln();
    }

    final total = results.fold<double>(0, (sum, result) => sum + result.total);
    buffer.writeln('=' * 50);
    buffer.writeln('Tổng cộng: ${_formatCurrency(total)}');

    return buffer.toString();
  }

  /// Safe multiplication with overflow protection
  double _safeMultiply(double a, int b) {
    if (b == 0) return 0.0;

    final result = a * b;
    if (result.isInfinite || result.isNaN) {
      throw PayrollException('Lỗi: Tính toán vượt quá giới hạn');
    }

    return result;
  }

  /// Format currency in Vietnamese Dong
  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)} ₫';
  }
}

/// Exception for payroll operations
class PayrollException implements Exception {
  final String message;

  PayrollException(this.message);

  @override
  String toString() => message;
}

/// Result of payroll calculation
class PayrollResult {
  final String employeeId;
  final String month;
  final double dailyRate;
  final double nightBonus;
  final int fullDays;
  final int halfDays;
  final int nightWorkDays;
  final double fullDayTotal;
  final double halfDayTotal;
  final double nightWorkTotal;
  final double total;

  PayrollResult({
    required this.employeeId,
    required this.month,
    required this.dailyRate,
    required this.nightBonus,
    required this.fullDays,
    required this.halfDays,
    required this.nightWorkDays,
    required this.fullDayTotal,
    required this.halfDayTotal,
    required this.nightWorkTotal,
    required this.total,
  });

  /// Get total working days (full days count as 1, half days as 0.5)
  double get totalWorkingDays => fullDays + (halfDays / 2);
}
