import 'package:flutter_test/flutter_test.dart';
import 'package:eztimesheet/models/models.dart';

void main() {
  group('AttendanceRecord Model', () {
    test('should create attendance record with default values', () {
      final now = DateTime.now();
      final record = AttendanceRecord(
        employeeId: 'employee-1',
        date: now,
        attendanceType: AttendanceType.fullDay,
      );

      expect(record.employeeId, 'employee-1');
      expect(record.attendanceType, AttendanceType.fullDay);
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
        attendanceType: AttendanceType.halfDay,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(record.id, 'test-id');
      expect(record.employeeId, 'employee-2');
      expect(record.attendanceType, AttendanceType.halfDay);
      expect(record.createdAt, createdAt);
      expect(record.updatedAt, updatedAt);
    });

    test('should convert to map and back', () {
      final now = DateTime.now();
      final original = AttendanceRecord(
        employeeId: 'employee-1',
        date: now,
        attendanceType: AttendanceType.nightWork,
      );

      final map = original.toMap();
      final restored = AttendanceRecord.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.employeeId, original.employeeId);
      expect(restored.attendanceType, original.attendanceType);
    });

    test('should copy with updated values', () {
      final now = DateTime.now();
      final original = AttendanceRecord(
        employeeId: 'employee-1',
        date: now,
        attendanceType: AttendanceType.fullDay,
      );

      final copied = original.copyWith(
        attendanceType: AttendanceType.halfDay,
        updatedAt: DateTime.now(),
      );

      expect(copied.attendanceType, AttendanceType.halfDay);
      expect(copied.employeeId, original.employeeId);
    });

    test('should validate date correctly', () {
      final today = DateTime.now();
      final future = today.add(const Duration(days: 1));

      final validRecord = AttendanceRecord(
        employeeId: 'employee-1',
        date: today,
        attendanceType: AttendanceType.fullDay,
      );

      // Valid date (today or past)
      expect(validRecord.validateDate(), null);

      // Future date
      final futureRecord = AttendanceRecord(
        employeeId: 'employee-1',
        date: future,
        attendanceType: AttendanceType.fullDay,
      );

      expect(futureRecord.validateDate(), ErrorMessages.attendanceFutureDate);
    });

    test('should get Vietnamese label for attendance type', () {
      final now = DateTime.now();

      final fullDay = AttendanceRecord(
        employeeId: 'employee-1',
        date: now,
        attendanceType: AttendanceType.fullDay,
      );
      expect(fullDay.attendanceTypeLabel, 'Cả ngày');

      final halfDay = AttendanceRecord(
        employeeId: 'employee-1',
        date: now,
        attendanceType: AttendanceType.halfDay,
      );
      expect(halfDay.attendanceTypeLabel, 'Nửa ngày');

      final nightWork = AttendanceRecord(
        employeeId: 'employee-1',
        date: now,
        attendanceType: AttendanceType.nightWork,
      );
      expect(nightWork.attendanceTypeLabel, 'Có làm tối');
    });

    test('should handle date-only storage correctly', () {
      final now = DateTime(2024, 4, 15, 14, 30, 45); // With time
      final record = AttendanceRecord(
        employeeId: 'employee-1',
        date: now,
        attendanceType: AttendanceType.fullDay,
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
