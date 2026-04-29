import 'package:flutter_test/flutter_test.dart';
import 'package:eztimesheet/models/models.dart';
import 'package:eztimesheet/repositories/repositories.dart';
import 'package:eztimesheet/database/database_helper.dart';
import 'package:eztimesheet/di/service_locator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper databaseHelper;
  late AttendanceRepository attendanceRepository;
  late EmployeeRepository employeeRepository;

  setUpAll(() async {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Setup service locator
    await setupServiceLocator();

    databaseHelper = getIt<DatabaseHelper>();
    attendanceRepository = getIt<AttendanceRepository>();
    employeeRepository = getIt<EmployeeRepository>();

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

  group('AttendanceRepository', () {
    test('should create attendance record', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final date = DateTime(2024, 4, 15);

      final record = AttendanceRecord(
        employeeId: employee.id,
        date: date,
        workStatus: WorkStatus.fullDay,
      );

      final created = await attendanceRepository.create(record);

      expect(created.id, isNotEmpty);
      expect(created.employeeId, employee.id);
      expect(created.workStatus, WorkStatus.fullDay);
    });

    test('should get attendance record by id', () async {
      final employee = await employeeRepository.create(Employee(name: 'Jane Smith', phone: '0987654321'));
      final date = DateTime(2024, 4, 16);

      final record = AttendanceRecord(
        employeeId: employee.id,
        date: date,
        workStatus: WorkStatus.halfDay,
      );

      final created = await attendanceRepository.create(record);
      final retrieved = await attendanceRepository.getById(created.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, created.id);
      expect(retrieved.workStatus, WorkStatus.halfDay);
    });

    test('should get all attendance records', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: DateTime(2024, 4, 15),
        workStatus: WorkStatus.fullDay,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: DateTime(2024, 4, 16),
        workStatus: WorkStatus.halfDay,
      ));

      final records = await attendanceRepository.getAll();

      expect(records.length, 2);
    });

    test('should get attendance records by employee id', () async {
      final employee1 = await employeeRepository.create(Employee(name: 'Employee 1', phone: '0123456789'));
      final employee2 = await employeeRepository.create(Employee(name: 'Employee 2', phone: '0987654321'));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee1.id,
        date: DateTime(2024, 4, 15),
        workStatus: WorkStatus.fullDay,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee1.id,
        date: DateTime(2024, 4, 16),
        workStatus: WorkStatus.halfDay,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee2.id,
        date: DateTime(2024, 4, 15),
        workStatus: WorkStatus.fullDay,
      ));

      final employee1Records = await attendanceRepository.getByEmployeeId(employee1.id);

      expect(employee1Records.length, 2);
      expect(employee1Records.every((r) => r.employeeId == employee1.id), true);
    });

    test('should get attendance records by date', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final date = DateTime(2024, 4, 15);

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: date,
        workStatus: WorkStatus.fullDay,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: DateTime(2024, 4, 16),
        workStatus: WorkStatus.halfDay,
      ));

      final records = await attendanceRepository.getByDate(date);

      expect(records.length, 1);
      expect(records.first.date.year, 2024);
      expect(records.first.date.month, 4);
      expect(records.first.date.day, 15);
    });

    test('should get attendance records by date range', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: DateTime(2024, 4, 10),
        workStatus: WorkStatus.fullDay,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: DateTime(2024, 4, 15),
        workStatus: WorkStatus.halfDay,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: DateTime(2024, 4, 20),
        workStatus: WorkStatus.none,
      ));

      final startDate = DateTime(2024, 4, 12);
      final endDate = DateTime(2024, 4, 18);

      final records = await attendanceRepository.getByDateRange(startDate, endDate);

      expect(records.length, 1);
      expect(records.first.date.day, 15);
    });

    test('should get attendance record by employee and date', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final date = DateTime(2024, 4, 15);

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: date,
        workStatus: WorkStatus.fullDay,
      ));

      final record = await attendanceRepository.getByEmployeeAndDate(employee.id, date);

      expect(record, isNotNull);
      expect(record!.employeeId, employee.id);
      expect(record.workStatus, WorkStatus.fullDay);
    });

    test('should return null when attendance not found by employee and date', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final date = DateTime(2024, 4, 15);

      final record = await attendanceRepository.getByEmployeeAndDate(employee.id, date);

      expect(record, isNull);
    });

    test('should update attendance record', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final date = DateTime(2024, 4, 15);

      final record = AttendanceRecord(
        employeeId: employee.id,
        date: date,
        workStatus: WorkStatus.fullDay,
      );

      final created = await attendanceRepository.create(record);
      final updated = await attendanceRepository.update(
        created.copyWith(
          workStatus: WorkStatus.halfDay,
        ),
      );

      expect(updated.workStatus, WorkStatus.halfDay);
    });

    test('should delete attendance record', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final date = DateTime(2024, 4, 15);

      final record = AttendanceRecord(
        employeeId: employee.id,
        date: date,
        workStatus: WorkStatus.fullDay,
      );

      final created = await attendanceRepository.create(record);
      await attendanceRepository.delete(created.id);

      final retrieved = await attendanceRepository.getById(created.id);

      expect(retrieved, isNull);
    });

    test('should check if attendance exists for employee and date', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final date = DateTime(2024, 4, 15);

      final existsBefore = await attendanceRepository.exists(employee.id, date);
      expect(existsBefore, false);

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: date,
        workStatus: WorkStatus.fullDay,
      ));

      final existsAfter = await attendanceRepository.exists(employee.id, date);
      expect(existsAfter, true);
    });

    test('should count attendance by type for employee', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: DateTime(2024, 4, 15),
        workStatus: WorkStatus.fullDay,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: DateTime(2024, 4, 16),
        workStatus: WorkStatus.fullDay,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: DateTime(2024, 4, 17),
        workStatus: WorkStatus.halfDay,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: DateTime(2024, 4, 18),
        workStatus: WorkStatus.none,
        hasNightShift: true,
      ));

      final startDate = DateTime(2024, 4, 1);
      final endDate = DateTime(2024, 4, 30);
      final counts = await attendanceRepository.countByTypeForEmployee(employee.id, startDate, endDate);

      expect(counts['fullDay'], 2);
      expect(counts['halfDay'], 1);
      expect(counts['none'], 1);
      expect(counts['nightShift'], 1);
    });

    test('should get attendance records for multiple employees and date range', () async {
      final employee1 = await employeeRepository.create(Employee(name: 'Employee 1', phone: '0123456789'));
      final employee2 = await employeeRepository.create(Employee(name: 'Employee 2', phone: '0987654321'));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee1.id,
        date: DateTime(2024, 4, 15),
        workStatus: WorkStatus.fullDay,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee1.id,
        date: DateTime(2024, 4, 16),
        workStatus: WorkStatus.halfDay,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee2.id,
        date: DateTime(2024, 4, 15),
        workStatus: WorkStatus.fullDay,
      ));

      final startDate = DateTime(2024, 4, 14);
      final endDate = DateTime(2024, 4, 17);

      final records = await attendanceRepository.getByEmployeesAndDateRange(
        [employee1.id, employee2.id],
        startDate,
        endDate,
      );

      expect(records.length, 3);
    });

    test('should return empty list when no attendance records exist', () async {
      final records = await attendanceRepository.getAll();

      expect(records, isEmpty);
    });

    test('should return 0 when counting attendance by type with no data', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      final counts = await attendanceRepository.countByTypeForEmployee(
        employee.id,
        DateTime(2024, 4, 1),
        DateTime(2024, 4, 30),
      );

      expect(counts['fullDay'], 0);
    });
  });
}
