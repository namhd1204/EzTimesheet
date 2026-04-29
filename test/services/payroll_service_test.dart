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
    await setupServiceLocator();

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
    await db.delete('attendance_records');
    await db.delete('employees');
    await db.delete('monthly_rates');
  });

  tearDownAll(() async {
    // Close database
    await databaseHelper.close();
  });

  group('PayrollService', () {
    test('should calculate payroll for employee', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final month = '2024-04';

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee.id,
        month: month,
        dailyRate: 300000,
        nightBonus: 100000,
      ));

      // 2 full days, 1 half day, 1 night work
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

      final result = await payrollService.calculatePayroll(employee.id, month);

      expect(result.employeeId, employee.id);
      expect(result.month, month);
      expect(result.fullDays, 2);
      expect(result.halfDays, 1);
      expect(result.nightWorkDays, 1);
      
      // (300k * 2) + (300k * 0.5) + (100k * 1) = 600k + 150k + 100k = 850k
      expect(result.total, 850000);
    });

    test('should carry over latest rate if current month not configured', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      
      // Configure for previous month
      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee.id,
        month: '2024-03',
        dailyRate: 350000,
        nightBonus: 120000,
      ));

      final result = await payrollService.calculatePayroll(employee.id, '2024-04');

      expect(result.dailyRate, 350000);
      expect(result.nightBonus, 120000);
      
      // Verify it was saved for current month
      final savedRate = await monthlyRateRepository.getByEmployeeAndMonth(employee.id, '2024-04');
      expect(savedRate, isNotNull);
      expect(savedRate!.dailyRate, 350000);
    });

    test('should throw error if no rate configured and no previous rate', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      
      expect(
        () => payrollService.calculatePayroll(employee.id, '2024-04'),
        throwsA(isA<PayrollException>()),
      );
    });

    test('should calculate payroll for all employees', () async {
      final employee1 = await employeeRepository.create(Employee(name: 'Employee 1', phone: '0123456789'));
      final employee2 = await employeeRepository.create(Employee(name: 'Employee 2', phone: '0987654321'));
      final month = '2024-04';

      await monthlyRateRepository.create(MonthlyRate(employeeId: employee1.id, month: month, dailyRate: 300000));
      await monthlyRateRepository.create(MonthlyRate(employeeId: employee2.id, month: month, dailyRate: 400000));

      final results = await payrollService.calculatePayrollForAll([employee1.id, employee2.id], month);

      expect(results.length, 2);
      expect(results.any((r) => r.employeeId == employee1.id), true);
      expect(results.any((r) => r.employeeId == employee2.id), true);
    });

    test('should get total payroll', () async {
      final employee1 = await employeeRepository.create(Employee(name: 'Employee 1', phone: '0123456789'));
      final employee2 = await employeeRepository.create(Employee(name: 'Employee 2', phone: '0987654321'));
      final month = '2024-04';

      await monthlyRateRepository.create(MonthlyRate(employeeId: employee1.id, month: month, dailyRate: 300000));
      await monthlyRateRepository.create(MonthlyRate(employeeId: employee2.id, month: month, dailyRate: 400000));

      await attendanceRepository.create(AttendanceRecord(employeeId: employee1.id, date: DateTime(2024, 4, 15), workStatus: WorkStatus.fullDay));
      await attendanceRepository.create(AttendanceRecord(employeeId: employee2.id, date: DateTime(2024, 4, 15), workStatus: WorkStatus.fullDay));

      final total = await payrollService.getTotalPayroll([employee1.id, employee2.id], month);

      expect(total, 700000);
    });

    test('should export payroll', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final month = '2024-04';

      await monthlyRateRepository.create(MonthlyRate(employeeId: employee.id, month: month, dailyRate: 300000));
      
      final export = await payrollService.exportPayroll([employee.id], month);

      expect(export, contains('Bảng lương tháng 2024-04'));
      expect(export, contains(employee.id));
    });
  });
}
