import 'dart:convert';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';

/// Service for data backup and restore operations
class BackupService {
  final EmployeeRepository _employeeRepository;
  final AttendanceRepository _attendanceRepository;
  final MonthlyRateRepository _monthlyRateRepository;
  final Battery _battery;

  BackupService(
    this._employeeRepository,
    this._attendanceRepository,
    this._monthlyRateRepository,
  ) : _battery = Battery();

  /// Export all data to JSON
  /// Returns JSON string with all data (photos not included)
  Future<String> exportData() async {
    // Check battery level before export
    final batteryLevel = await _battery.batteryLevel;
    if (batteryLevel < 20) {
      throw BackupException(
        'Cảnh báo: Pin yếu (<20%). Nên sạc pin trước khi xuất dữ liệu.',
        isWarning: true,
      );
    }

    try {
      // Fetch all data
      final employees = await _employeeRepository.getAll();
      final attendanceRecords = await _attendanceRepository.getAll();
      final monthlyRates = await _monthlyRateRepository.getAll();

      // Create export data structure
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'employees': employees.map((e) => e.toMap()).toList(),
        'attendanceRecords':
            attendanceRecords.map((a) => a.toMap()).toList(),
        'monthlyRates': monthlyRates.map((r) => r.toMap()).toList(),
      };

      // Convert to JSON
      return jsonEncode(exportData);
    } catch (e) {
      throw BackupException('Lỗi: Không thể xuất dữ liệu. $e');
    }
  }

  /// Import data from JSON
  /// Returns summary of imported data
  Future<BackupSummary> importData(String jsonData) async {
    // Check battery level before import
    final batteryLevel = await _battery.batteryLevel;
    if (batteryLevel < 20) {
      throw BackupException(
        'Cảnh báo: Pin yếu (<20%). Nên sạc pin trước khi nhập dữ liệu.',
        isWarning: true,
      );
    }

    try {
      // Parse JSON
      final Map<String, dynamic> data = jsonDecode(jsonData);

      // Validate data structure
      if (!data.containsKey('employees') ||
          !data.containsKey('attendanceRecords') ||
          !data.containsKey('monthlyRates')) {
        throw BackupException('Lỗi: Dữ liệu không hợp lệ - thiếu trường bắt buộc');
      }

      // Import employees
      int employeesImported = 0;
      int employeesFailed = 0;
      final List<Map<String, dynamic>> employeesData =
          List<Map<String, dynamic>>.from(data['employees']);

      for (final employeeData in employeesData) {
        try {
          final employee = Employee.fromMap(employeeData);
          await _employeeRepository.create(employee);
          employeesImported++;
        } catch (e) {
          employeesFailed++;
        }
      }

      // Import attendance records
      int attendanceImported = 0;
      int attendanceFailed = 0;
      final List<Map<String, dynamic>> attendanceData =
          List<Map<String, dynamic>>.from(data['attendanceRecords']);

      for (final attendanceData in attendanceData) {
        try {
          final attendance = AttendanceRecord.fromMap(attendanceData);
          await _attendanceRepository.create(attendance);
          attendanceImported++;
        } catch (e) {
          attendanceFailed++;
        }
      }

      // Import monthly rates
      int ratesImported = 0;
      int ratesFailed = 0;
      final List<Map<String, dynamic>> ratesData =
          List<Map<String, dynamic>>.from(data['monthlyRates']);

      for (final rateData in ratesData) {
        try {
          final rate = MonthlyRate.fromMap(rateData);
          await _monthlyRateRepository.create(rate);
          ratesImported++;
        } catch (e) {
          ratesFailed++;
        }
      }

      return BackupSummary(
        employeesImported: employeesImported,
        employeesFailed: employeesFailed,
        attendanceImported: attendanceImported,
        attendanceFailed: attendanceFailed,
        ratesImported: ratesImported,
        ratesFailed: ratesFailed,
      );
    } catch (e) {
      if (e is BackupException) rethrow;
      throw BackupException('Lỗi: Không thể nhập dữ liệu. $e');
    }
  }

  /// Validate JSON data structure
  /// Returns true if valid, false otherwise
  Future<bool> validateJson(String jsonData) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonData);
      return data.containsKey('employees') &&
          data.containsKey('attendanceRecords') &&
          data.containsKey('monthlyRates');
    } catch (e) {
      return false;
    }
  }
}

/// Exception for backup operations
class BackupException implements Exception {
  final String message;
  final bool isWarning;

  BackupException(this.message, {this.isWarning = false});

  @override
  String toString() => message;
}

/// Summary of backup/import operation
class BackupSummary {
  final int employeesImported;
  final int employeesFailed;
  final int attendanceImported;
  final int attendanceFailed;
  final int ratesImported;
  final int ratesFailed;

  BackupSummary({
    required this.employeesImported,
    required this.employeesFailed,
    required this.attendanceImported,
    required this.attendanceFailed,
    required this.ratesImported,
    required this.ratesFailed,
  });

  bool get hasFailures =>
      employeesFailed > 0 ||
      attendanceFailed > 0 ||
      ratesFailed > 0;

  int get totalImported =>
      employeesImported + attendanceImported + ratesImported;

  int get totalFailed =>
      employeesFailed + attendanceFailed + ratesFailed;
}
