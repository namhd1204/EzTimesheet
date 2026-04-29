import 'dart:convert';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/models.dart';
import '../repositories/repositories.dart';
import 'google_drive_service.dart';

/// Service for data backup and restore operations
class BackupService {
  final EmployeeRepository _employeeRepository;
  final AttendanceRepository _attendanceRepository;
  final MonthlyRateRepository _monthlyRateRepository;
  final MonthLockRepository _monthLockRepository;
  final GoogleDriveService _googleDriveService;
  final Battery? _battery;

  BackupService(
    this._employeeRepository,
    this._attendanceRepository,
    this._monthlyRateRepository,
    this._monthLockRepository,
    this._googleDriveService,
  ) : _battery = kIsWeb ? null : Battery();

  /// Export all data to JSON
  /// Returns JSON string with all data (photos not included)
  Future<String> exportData() async {
    // Check battery level before export (Skip on Web as it may throw/not be supported)
    if (!kIsWeb) {
      final batteryLevel = await _battery!.batteryLevel;
      if (batteryLevel < 20) {
        throw BackupException(
          'Cảnh báo: Pin yếu (<20%). Nên sạc pin trước khi xuất dữ liệu.',
          isWarning: true,
        );
      }
    }

    try {
      // Fetch all data
      final employees = await _employeeRepository.getAll();
      final attendanceRecords = await _attendanceRepository.getAll();
      final monthlyRates = await _monthlyRateRepository.getAll();
      final monthLocks = await _monthLockRepository.getAll(); // Assume getAll added

      // Create export data structure
      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'employees': employees.map((e) => e.toMap()).toList(),
        'attendanceRecords':
            attendanceRecords.map((a) => a.toMap()).toList(),
        'monthlyRates': monthlyRates.map((r) => r.toMap()).toList(),
        'monthLocks': monthLocks.map((l) => l.toMap()).toList(),
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
    // Check battery level before import (Skip on Web)
    if (!kIsWeb) {
      final batteryLevel = await _battery!.batteryLevel;
      if (batteryLevel < 20) {
        throw BackupException(
          'Cảnh báo: Pin yếu (<20%). Nên sạc pin trước khi nhập dữ liệu.',
          isWarning: true,
        );
      }
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
      final List<Map<String, dynamic>> attendanceDataList =
          List<Map<String, dynamic>>.from(data['attendanceRecords']);

      for (final recordData in attendanceDataList) {
        try {
          final record = AttendanceRecord.fromMap(recordData);
          await _attendanceRepository.create(record);
          attendanceImported++;
        } catch (e) {
          attendanceFailed++;
        }
      }

      // Import monthly rates
      int ratesImported = 0;
      int ratesFailed = 0;
      final List<Map<String, dynamic>> ratesDataList =
          List<Map<String, dynamic>>.from(data['monthlyRates']);

      for (final rateData in ratesDataList) {
        try {
          final rate = MonthlyRate.fromMap(rateData);
          await _monthlyRateRepository.create(rate);
          ratesImported++;
        } catch (e) {
          ratesFailed++;
        }
      }

      // Import month locks
      int locksImported = 0;
      int locksFailed = 0;
      if (data.containsKey('monthLocks')) {
        final List<Map<String, dynamic>> locksDataList =
            List<Map<String, dynamic>>.from(data['monthLocks']);

        for (final lockData in locksDataList) {
          try {
            final lock = MonthLock.fromMap(lockData);
            await _monthLockRepository.setLock(lock.month, lock.isLocked);
            locksImported++;
          } catch (e) {
            locksFailed++;
          }
        }
      }

      return BackupSummary(
        employeesImported: employeesImported,
        employeesFailed: employeesFailed,
        attendanceImported: attendanceImported,
        attendanceFailed: attendanceFailed,
        ratesImported: ratesImported,
        ratesFailed: ratesFailed,
        locksImported: locksImported,
        locksFailed: locksFailed,
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

  /// Perform automatic backup to Google Drive if needed
  Future<void> performAutoBackup() async {
    if (await _googleDriveService.isBackupNeeded()) {
      try {
        final content = await exportData();
        await _googleDriveService.uploadBackup(content);
      } catch (e) {
        // Fail silently for auto-backup
      }
    }
  }

  /// Restore data from Google Drive
  Future<BackupSummary?> restoreFromDrive() async {
    final content = await _googleDriveService.downloadBackup();
    if (content == null) return null;
    return await importData(content);
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
  final int locksImported;
  final int locksFailed;

  BackupSummary({
    required this.employeesImported,
    required this.employeesFailed,
    required this.attendanceImported,
    required this.attendanceFailed,
    required this.ratesImported,
    required this.ratesFailed,
    this.locksImported = 0,
    this.locksFailed = 0,
  });

  bool get hasFailures =>
      employeesFailed > 0 ||
      attendanceFailed > 0 ||
      ratesFailed > 0 ||
      locksFailed > 0;

  int get totalImported =>
      employeesImported + attendanceImported + ratesImported + locksImported;

  int get totalFailed =>
      employeesFailed + attendanceFailed + ratesFailed + locksFailed;
}
