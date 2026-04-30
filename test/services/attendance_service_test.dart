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
    await setupServiceLocator();

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
        employee.id,
        date,
        workStatus: WorkStatus.fullDay,
      );

      expect(record.employeeId, employee.id);
      expect(record.workStatus, WorkStatus.fullDay);
      expect(record.date.year, 2024);
      expect(record.date.month, 4);
      expect(record.date.day, 15);
    });

    test('should update existing attendance if recording again', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final date = DateTime(2024, 4, 15);

      await attendanceService.recordAttendance(
        employee.id,
        date,
        workStatus: WorkStatus.fullDay,
      );

      final updated = await attendanceService.recordAttendance(
        employee.id,
        date,
        workStatus: WorkStatus.halfDay,
      );

      expect(updated.workStatus, WorkStatus.halfDay);
    });

    test('should update attendance status', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final date = DateTime(2024, 4, 15);

      await attendanceService.recordAttendance(
        employee.id,
        date,
        workStatus: WorkStatus.fullDay,
      );

      final updated = await attendanceService.updateAttendanceStatus(
        employee.id,
        date,
        workStatus: WorkStatus.halfDay,
      );

      expect(updated.workStatus, WorkStatus.halfDay);
    });

    test('should delete attendance', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final date = DateTime(2024, 4, 15);

      final created = await attendanceService.recordAttendance(
        employee.id,
        date,
        workStatus: WorkStatus.fullDay,
      );

      await attendanceService.deleteAttendance(created.id);

      final retrieved = await attendanceRepository.getById(created.id);

      expect(retrieved, isNull);
    });

    test('should get attendance by employee and date', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final date = DateTime(2024, 4, 15);

      await attendanceService.recordAttendance(
        employee.id,
        date,
        workStatus: WorkStatus.fullDay,
      );

      final retrieved = await attendanceService.getAttendance(employee.id, date);

      expect(retrieved, isNotNull);
      expect(retrieved!.employeeId, employee.id);
    });

    test('should get attendance for date', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final date = DateTime(2024, 4, 15);

      await attendanceService.recordAttendance(
        employee.id,
        date,
        workStatus: WorkStatus.fullDay,
      );

      final records = await attendanceService.getAllRecordsForDate(date);

      expect(records.length, 1);
      expect(records.first.employeeId, employee.id);
    });

    test('should get attendance for employee in date range', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      await attendanceService.recordAttendance(
        employee.id,
        DateTime(2024, 4, 15),
        workStatus: WorkStatus.fullDay,
      );

      await attendanceService.recordAttendance(
        employee.id,
        DateTime(2024, 4, 16),
        workStatus: WorkStatus.halfDay,
      );

      await attendanceService.recordAttendance(
        employee.id,
        DateTime(2024, 4, 20),
        workStatus: WorkStatus.none,
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
        employee1.id,
        DateTime(2024, 4, 15),
        workStatus: WorkStatus.fullDay,
      );

      await attendanceService.recordAttendance(
        employee2.id,
        DateTime(2024, 4, 15),
        workStatus: WorkStatus.fullDay,
      );

      await attendanceService.recordAttendance(
        employee1.id,
        DateTime(2024, 4, 16),
        workStatus: WorkStatus.halfDay,
      );

      final startDate = DateTime(2024, 4, 14);
      final endDate = DateTime(2024, 4, 18);

      final recordsMap = await attendanceService.getAttendanceForAllInRange(
        [employee1.id, employee2.id],
        startDate,
        endDate,
      );

      expect(recordsMap.length, 2);
      expect(recordsMap[employee1.id]!.length, 2);
      expect(recordsMap[employee2.id]!.length, 1);
    });

    test('should check if attendance exists for employee and date', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final date = DateTime(2024, 4, 15);

      final existsBefore = await attendanceService.hasAttendance(employee.id, date);
      expect(existsBefore, false);

      await attendanceService.recordAttendance(
        employee.id,
        date,
        workStatus: WorkStatus.fullDay,
      );

      final existsAfter = await attendanceService.hasAttendance(employee.id, date);
      expect(existsAfter, true);
    });

    test('should get last attendance for employee', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      await attendanceService.recordAttendance(
        employee.id,
        DateTime(2024, 4, 15),
        workStatus: WorkStatus.fullDay,
      );

      await attendanceService.recordAttendance(
        employee.id,
        DateTime(2024, 4, 16),
        workStatus: WorkStatus.halfDay,
      );

      await attendanceService.recordAttendance(
        employee.id,
        DateTime(2024, 4, 17),
        workStatus: WorkStatus.none,
      );

      final lastAttendance = await attendanceService.getLastAttendance(employee.id);

      expect(lastAttendance, isNotNull);
      expect(lastAttendance!.date.day, 17);
      expect(lastAttendance.workStatus, WorkStatus.none);
    });

    test('should undo last attendance', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      await attendanceService.recordAttendance(
        employee.id,
        DateTime(2024, 4, 15),
        workStatus: WorkStatus.fullDay,
      );

      await attendanceService.recordAttendance(
        employee.id,
        DateTime(2024, 4, 16),
        workStatus: WorkStatus.halfDay,
      );

      await attendanceService.recordAttendance(
        employee.id,
        DateTime(2024, 4, 17),
        workStatus: WorkStatus.none,
      );

      final undone = await attendanceService.undoLastAttendance(employee.id);

      expect(undone, isNotNull);
      expect(undone!.date.day, 17);

      // Verify it was deleted
      final exists = await attendanceService.hasAttendance(employee.id, DateTime(2024, 4, 17));
      expect(exists, false);
    });
  });
}
