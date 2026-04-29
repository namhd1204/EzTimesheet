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
  late PayrollService payrollService;
  late EmployeeRepository employeeRepository;
  late AttendanceRepository attendanceRepository;
  late MonthlyRateRepository monthlyRateRepository;

  setUpAll(() async {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Setup service locator
    await ServiceLocator.setup();

    databaseHelper = getIt<DatabaseHelper>();
    payrollService = getIt<PayrollService>();
    employeeRepository = getIt<EmployeeRepository>();
    attendanceRepository = getIt<AttendanceRepository>();
    monthlyRateRepository = getIt<MonthlyRateRepository>();

    // Initialize database
    await databaseHelper.database;
  });

  setUp(() async {
    // Clear database before each test
    final db = await databaseHelper.database;
    await db.delete('monthly_rates');
    await db.delete('attendance_records');
    await db.delete('employees');
  });

  tearDownAll(() async {
    // Close database
    await databaseHelper.close();
  });

  group('PayrollService', () {
    test('should calculate payroll for employee', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee.id,
        month: '2024-04',
        dailyRate: 500000,
        nightRateMultiplier: 1.5,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: DateTime(2024, 4, 15),
        attendanceType: AttendanceType.fullDay,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: DateTime(2024, 4, 16),
        attendanceType: AttendanceType.halfDay,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: DateTime(2024, 4, 17),
        attendanceType: AttendanceType.nightWork,
      ));

      final payroll = await payrollService.calculatePayroll(employee.id, '2024-04');

      expect(payroll.employeeId, employee.id);
      expect(payroll.month, '2024-04');
      expect(payroll.fullDayCount, 1);
      expect(payroll.halfDayCount, 1);
      expect(payroll.nightWorkCount, 1);
      expect(payroll.dailyRate, 500000);
      expect(payroll.nightRateMultiplier, 1.5);
      expect(payroll.totalPay, 500000 + 250000 + 750000); // fullDay + halfDay + nightWork
    });

    test('should calculate payroll with zero attendance', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee.id,
        month: '2024-04',
        dailyRate: 500000,
      ));

      final payroll = await payrollService.calculatePayroll(employee.id, '2024-04');

      expect(payroll.fullDayCount, 0);
      expect(payroll.halfDayCount, 0);
      expect(payroll.nightWorkCount, 0);
      expect(payroll.totalPay, 0);
    });

    test('should calculate payroll for all employees', () async {
      final employee1 = await employeeRepository.create(Employee(name: 'Employee 1', phone: '0123456789'));
      final employee2 = await employeeRepository.create(Employee(name: 'Employee 2', phone: '0987654321'));

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee1.id,
        month: '2024-04',
        dailyRate: 500000,
      ));

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee2.id,
        month: '2024-04',
        dailyRate: 600000,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee1.id,
        date: DateTime(2024, 4, 15),
        attendanceType: AttendanceType.fullDay,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee2.id,
        date: DateTime(2024, 4, 15),
        attendanceType: AttendanceType.fullDay,
      ));

      final payrolls = await payrollService.calculatePayrollForAll('2024-04');

      expect(payrolls.length, 2);
    });

    test('should calculate total payroll', () async {
      final employee1 = await employeeRepository.create(Employee(name: 'Employee 1', phone: '0123456789'));
      final employee2 = await employeeRepository.create(Employee(name: 'Employee 2', phone: '0987654321'));

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee1.id,
        month: '2024-04',
        dailyRate: 500000,
      ));

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee2.id,
        month: '2024-04',
        dailyRate: 600000,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee1.id,
        date: DateTime(2024, 4, 15),
        attendanceType: AttendanceType.fullDay,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee2.id,
        date: DateTime(2024, 4, 15),
        attendanceType: AttendanceType.fullDay,
      ));

      final totalPayroll = await payrollService.getTotalPayroll('2024-04');

      expect(totalPayroll, 1100000); // 500000 + 600000
    });

    test('should export payroll to text', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee.id,
        month: '2024-04',
        dailyRate: 500000,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: DateTime(2024, 4, 15),
        attendanceType: AttendanceType.fullDay,
      ));

      final payrolls = await payrollService.calculatePayrollForAll('2024-04');
      final exportedText = await payrollService.exportPayroll(payrolls);

      expect(exportedText, isNotEmpty);
      expect(exportedText.contains('Bảng lương tháng 04/2024'), true);
      expect(exportedText.contains('John Doe'), true);
      expect(exportedText.contains('500.000'), true);
    });

    test('should handle overflow in payroll calculation', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee.id,
        month: '2024-04',
        dailyRate: 100000000, // Maximum rate
        nightRateMultiplier: 3.0, // Maximum multiplier
      ));

      // Create many attendance records to test overflow protection
      for (int i = 0; i < 30; i++) {
        await attendanceRepository.create(AttendanceRecord(
          employeeId: employee.id,
          date: DateTime(2024, 4, 1 + i),
          attendanceType: AttendanceType.nightWork,
        ));
      }

      final payroll = await payrollService.calculatePayroll(employee.id, '2024-04');

      // Should not throw overflow exception
      expect(payroll.totalPay, isNotNull);
      expect(payroll.totalPay, greaterThan(0));
    });

    test('should calculate payroll with different attendance types', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee.id,
        month: '2024-04',
        dailyRate: 500000,
        nightRateMultiplier: 2.0,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: DateTime(2024, 4, 15),
        attendanceType: AttendanceType.fullDay,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: DateTime(2024, 4, 16),
        attendanceType: AttendanceType.halfDay,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: DateTime(2024, 4, 17),
        attendanceType: AttendanceType.nightWork,
      ));

      final payroll = await payrollService.calculatePayroll(employee.id, '2024-04');

      expect(payroll.fullDayCount, 1);
      expect(payroll.halfDayCount, 1);
      expect(payroll.nightWorkCount, 1);
      expect(payroll.totalPay, 500000 + 250000 + 1000000); // fullDay + halfDay + nightWork (2.0x)
    });

    test('should return empty list when no employees have rates', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      final payrolls = await payrollService.calculatePayrollForAll('2024-04');

      expect(payrolls, isEmpty);
    });

    test('should return 0 for total payroll when no data', () async {
      final totalPayroll = await payrollService.getTotalPayroll('2024-04');

      expect(totalPayroll, 0);
    });

    test('should handle employees without monthly rate', () async {
      final employee1 = await employeeRepository.create(Employee(name: 'Employee 1', phone: '0123456789'));
      final employee2 = await employeeRepository.create(Employee(name: 'Employee 2', phone: '0987654321'));

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee1.id,
        month: '2024-04',
        dailyRate: 500000,
      ));

      // Employee 2 has no monthly rate

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee1.id,
        date: DateTime(2024, 4, 15),
        attendanceType: AttendanceType.fullDay,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee2.id,
        date: DateTime(2024, 4, 15),
        attendanceType: AttendanceType.fullDay,
      ));

      final payrolls = await payrollService.calculatePayrollForAll('2024-04');

      expect(payrolls.length, 1); // Only employee 1 has a rate
      expect(payrolls.first.employeeId, employee1.id);
    });

    test('should calculate payroll with custom night rate multiplier', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee.id,
        month: '2024-04',
        dailyRate: 500000,
        nightRateMultiplier: 2.5,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: DateTime(2024, 4, 15),
        attendanceType: AttendanceType.nightWork,
      ));

      final payroll = await payrollService.calculatePayroll(employee.id, '2024-04');

      expect(payroll.nightWorkCount, 1);
      expect(payroll.totalPay, 1250000); // 500000 * 2.5
    });
  });
}
