import 'package:flutter_test/flutter_test.dart';
import 'package:eztimesheet/models/models.dart';
import 'package:eztimesheet/repositories/repositories.dart';
import 'package:eztimesheet/services/services.dart';
import 'package:eztimesheet/database/database_helper.dart';
import 'package:eztimesheet/di/service_locator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper databaseHelper;
  late AttendanceService attendanceService;
  late EmployeeRepository employeeRepository;
  late AttendanceRepository attendanceRepository;

  setUpAll(() async {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Setup service locator
    await ServiceLocator.setup();

    databaseHelper = getIt<DatabaseHelper>();
    attendanceService = getIt<AttendanceService>();
    employeeRepository = getIt<EmployeeRepository>();
    attendanceRepository = getIt<AttendanceRepository>();

    // Initialize database
    await databaseHelper.database;
  });

  setUp(() async {
    // Clear database before each test
    final db = await databaseHelper.database;
    await db.delete('attendance_records');
    await db.delete('employees');
  });

  tearDownAll(() async {
    // Close database
    await databaseHelper.close();
  });

  group('AttendanceService', () {
    test('should record attendance', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final date = DateTime(2024, 4, 15);

      final record = await attendanceService.recordAttendance(
        employeeId: employee.id,
        date: date,
        attendanceType: AttendanceType.fullDay,
      );

      expect(record.employeeId, employee.id);
      expect(record.attendanceType, AttendanceType.fullDay);
      expect(record.date.year, 2024);
      expect(record.date.month, 4);
      expect(record.date.day, 15);
    });

    test('should prevent duplicate attendance for same employee and date', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final date = DateTime(2024, 4, 15);

      await attendanceService.recordAttendance(
        employeeId: employee.id,
        date: date,
        attendanceType: AttendanceType.fullDay,
      );

      expect(
        () => attendanceService.recordAttendance(
          employeeId: employee.id,
          date: date,
          attendanceType: AttendanceType.halfDay,
        ),
        throwsA(isA<AttendanceException>()),
      );
    });

    test('should update existing attendance', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final date = DateTime(2024, 4, 15);

      final created = await attendanceService.recordAttendance(
        employeeId: employee.id,
        date: date,
        attendanceType: AttendanceType.fullDay,
      );

      final updated = await attendanceService.updateAttendance(
        created.id,
        attendanceType: AttendanceType.halfDay,
      );

      expect(updated.attendanceType, AttendanceType.halfDay);
      expect(updated.id, created.id);
    });

    test('should delete attendance', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final date = DateTime(2024, 4, 15);

      final created = await attendanceService.recordAttendance(
        employeeId: employee.id,
        date: date,
        attendanceType: AttendanceType.fullDay,
      );

      await attendanceService.deleteAttendance(created.id);

      final retrieved = await attendanceRepository.getById(created.id);

      expect(retrieved, isNull);
    });

    test('should get attendance by id', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final date = DateTime(2024, 4, 15);

      final created = await attendanceService.recordAttendance(
        employeeId: employee.id,
        date: date,
        attendanceType: AttendanceType.fullDay,
      );

      final retrieved = await attendanceService.getAttendance(created.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, created.id);
    });

    test('should get attendance for date', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final date = DateTime(2024, 4, 15);

      await attendanceService.recordAttendance(
        employeeId: employee.id,
        date: date,
        attendanceType: AttendanceType.fullDay,
      );

      final records = await attendanceService.getAttendanceForDate(date);

      expect(records.length, 1);
      expect(records.first.employeeId, employee.id);
    });

    test('should get attendance for employee in date range', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      await attendanceService.recordAttendance(
        employeeId: employee.id,
        date: DateTime(2024, 4, 15),
        attendanceType: AttendanceType.fullDay,
      );

      await attendanceService.recordAttendance(
        employeeId: employee.id,
        date: DateTime(2024, 4, 16),
        attendanceType: AttendanceType.halfDay,
      );

      await attendanceService.recordAttendance(
        employeeId: employee.id,
        date: DateTime(2024, 4, 20),
        attendanceType: AttendanceType.nightWork,
      );

      final startDate = DateTime(2024, 4, 14);
      final endDate = DateTime(2024, 4, 18);

      final records = await attendanceService.getAttendanceForEmployeeInRange(
        employee.id,
        startDate,
        endDate,
      );

      expect(records.length, 2);
    });

    test('should get attendance for all employees in date range', () async {
      final employee1 = await employeeRepository.create(Employee(name: 'Employee 1', phone: '0123456789'));
      final employee2 = await employeeRepository.create(Employee(name: 'Employee 2', phone: '0987654321'));

      await attendanceService.recordAttendance(
        employeeId: employee1.id,
        date: DateTime(2024, 4, 15),
        attendanceType: AttendanceType.fullDay,
      );

      await attendanceService.recordAttendance(
        employeeId: employee2.id,
        date: DateTime(2024, 4, 15),
        attendanceType: AttendanceType.fullDay,
      );

      await attendanceService.recordAttendance(
        employeeId: employee1.id,
        date: DateTime(2024, 4, 16),
        attendanceType: AttendanceType.halfDay,
      );

      final startDate = DateTime(2024, 4, 14);
      final endDate = DateTime(2024, 4, 18);

      final records = await attendanceService.getAttendanceForAllInRange(startDate, endDate);

      expect(records.length, 3);
    });

    test('should check if attendance exists for employee and date', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final date = DateTime(2024, 4, 15);

      final existsBefore = await attendanceService.hasAttendance(employee.id, date);
      expect(existsBefore, false);

      await attendanceService.recordAttendance(
        employeeId: employee.id,
        date: date,
        attendanceType: AttendanceType.fullDay,
      );

      final existsAfter = await attendanceService.hasAttendance(employee.id, date);
      expect(existsAfter, true);
    });

    test('should get last attendance for employee', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      await attendanceService.recordAttendance(
        employeeId: employee.id,
        date: DateTime(2024, 4, 15),
        attendanceType: AttendanceType.fullDay,
      );

      await attendanceService.recordAttendance(
        employeeId: employee.id,
        date: DateTime(2024, 4, 16),
        attendanceType: AttendanceType.halfDay,
      );

      await attendanceService.recordAttendance(
        employeeId: employee.id,
        date: DateTime(2024, 4, 17),
        attendanceType: AttendanceType.nightWork,
      );

      final lastAttendance = await attendanceService.getLastAttendance(employee.id);

      expect(lastAttendance, isNotNull);
      expect(lastAttendance!.date.day, 17);
      expect(lastAttendance.attendanceType, AttendanceType.nightWork);
    });

    test('should return null when no last attendance exists', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      final lastAttendance = await attendanceService.getLastAttendance(employee.id);

      expect(lastAttendance, isNull);
    });

    test('should undo last attendance', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      await attendanceService.recordAttendance(
        employeeId: employee.id,
        date: DateTime(2024, 4, 15),
        attendanceType: AttendanceType.fullDay,
      );

      await attendanceService.recordAttendance(
        employeeId: employee.id,
        date: DateTime(2024, 4, 16),
        attendanceType: AttendanceType.halfDay,
      );

      await attendanceService.recordAttendance(
        employeeId: employee.id,
        date: DateTime(2024, 4, 17),
        attendanceType: AttendanceType.nightWork,
      );

      final undone = await attendanceService.undoLastAttendance(employee.id);

      expect(undone, isNotNull);
      expect(undone!.date.day, 17);
      expect(undone.attendanceType, AttendanceType.nightWork);

      // Verify it was deleted
      final exists = await attendanceService.hasAttendance(employee.id, DateTime(2024, 4, 17));
      expect(exists, false);
    });

    test('should return null when undoing last attendance with no records', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      final undone = await attendanceService.undoLastAttendance(employee.id);

      expect(undone, isNull);
    });

    test('should handle different attendance types', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      final fullDay = await attendanceService.recordAttendance(
        employeeId: employee.id,
        date: DateTime(2024, 4, 15),
        attendanceType: AttendanceType.fullDay,
      );

      final halfDay = await attendanceService.recordAttendance(
        employeeId: employee.id,
        date: DateTime(2024, 4, 16),
        attendanceType: AttendanceType.halfDay,
      );

      final nightWork = await attendanceService.recordAttendance(
        employeeId: employee.id,
        date: DateTime(2024, 4, 17),
        attendanceType: AttendanceType.nightWork,
      );

      expect(fullDay.attendanceType, AttendanceType.fullDay);
      expect(halfDay.attendanceType, AttendanceType.halfDay);
      expect(nightWork.attendanceType, AttendanceType.nightWork);
    });

    test('should return empty list when no attendance for date', () async {
      final date = DateTime(2024, 4, 15);

      final records = await attendanceService.getAttendanceForDate(date);

      expect(records, isEmpty);
    });

    test('should return empty list when no attendance for employee in range', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      final startDate = DateTime(2024, 4, 14);
      final endDate = DateTime(2024, 4, 18);

      final records = await attendanceService.getAttendanceForEmployeeInRange(
        employee.id,
        startDate,
        endDate,
      );

      expect(records, isEmpty);
    });

    test('should return empty list when no attendance for all employees in range', () async {
      final startDate = DateTime(2024, 4, 14);
      final endDate = DateTime(2024, 4, 18);

      final records = await attendanceService.getAttendanceForAllInRange(startDate, endDate);

      expect(records, isEmpty);
    });
  });
}
