import 'package:flutter_test/flutter_test.dart';
import 'package:eztimesheet/models/models.dart';
import 'package:eztimesheet/utils/error_messages.dart';

void main() {
  group('AttendanceRecord Model', () {
    test('should create attendance record with default values', () {
      final now = DateTime.now();
      final record = AttendanceRecord(
        employeeId: 'employee-1',
        date: now,
        workStatus: WorkStatus.fullDay,
      );

      expect(record.employeeId, 'employee-1');
      expect(record.workStatus, WorkStatus.fullDay);
      expect(record.id, isNotEmpty);
      expect(record.createdAt, isNotNull);
      expect(record.updatedAt, isNotNull);
    });

    test('should create attendance record with custom values', () {
      final now = DateTime.now();
      final createdAt = now.subtract(const Duration(days: 1));
      final updatedAt = now;

      final record = AttendanceRecord(
        id: 'test-id',
        employeeId: 'employee-2',
        date: now,
        workStatus: WorkStatus.halfDay,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(record.id, 'test-id');
      expect(record.employeeId, 'employee-2');
      expect(record.workStatus, WorkStatus.halfDay);
      expect(record.createdAt, createdAt);
      expect(record.updatedAt, updatedAt);
    });

    test('should convert to map and back', () {
      final now = DateTime.now();
      final original = AttendanceRecord(
        employeeId: 'employee-1',
        date: now,
        workStatus: WorkStatus.none,
        hasNightShift: true,
      );

      final map = original.toMap();
      final restored = AttendanceRecord.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.employeeId, original.employeeId);
      expect(restored.workStatus, original.workStatus);
      expect(restored.hasNightShift, original.hasNightShift);
    });

    test('should copy with updated values', () {
      final now = DateTime.now();
      final original = AttendanceRecord(
        employeeId: 'employee-1',
        date: now,
        workStatus: WorkStatus.fullDay,
      );

      final copied = original.copyWith(
        workStatus: WorkStatus.halfDay,
        updatedAt: DateTime.now(),
      );

      expect(copied.workStatus, WorkStatus.halfDay);
      expect(copied.employeeId, original.employeeId);
    });

    test('should validate date correctly', () {
      final today = DateTime.now();
      final future = today.add(const Duration(days: 1));

      final validRecord = AttendanceRecord(
        employeeId: 'employee-1',
        date: today,
        workStatus: WorkStatus.fullDay,
      );

      // Valid date (today or past)
      expect(validRecord.validateDate(), null);

      // Future date
      final futureRecord = AttendanceRecord(
        employeeId: 'employee-1',
        date: future,
        workStatus: WorkStatus.fullDay,
      );

      expect(futureRecord.validateDate(), ErrorMessages.attendanceFutureDate);
    });

    test('should get Vietnamese label for work status', () {
      final now = DateTime.now();

      final fullDay = AttendanceRecord(
        employeeId: 'employee-1',
        date: now,
        workStatus: WorkStatus.fullDay,
      );
      expect(fullDay.workStatusLabel, 'Cả ngày');

      final halfDay = AttendanceRecord(
        employeeId: 'employee-1',
        date: now,
        workStatus: WorkStatus.halfDay,
      );
      expect(halfDay.workStatusLabel, 'Nửa ngày');

      final none = AttendanceRecord(
        employeeId: 'employee-1',
        date: now,
        workStatus: WorkStatus.none,
      );
      expect(none.workStatusLabel, 'Nghỉ');
    });

    test('should handle date-only storage correctly', () {
      final now = DateTime(2024, 4, 15, 14, 30, 45); // With time
      final record = AttendanceRecord(
        employeeId: 'employee-1',
        date: now,
        workStatus: WorkStatus.fullDay,
      );

      final map = record.toMap();
      final restored = AttendanceRecord.fromMap(map);

      // Date should be stored without time
      expect(restored.date.year, 2024);
      expect(restored.date.month, 4);
      expect(restored.date.day, 15);
      expect(restored.date.hour, 0);
      expect(restored.date.minute, 0);
      expect(restored.date.second, 0);
    });
  });
}
