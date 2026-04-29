import 'package:flutter_test/flutter_test.dart';
import 'package:eztimesheet/models/models.dart';
import 'package:eztimesheet/repositories/repositories.dart';
import 'package:eztimesheet/database/database_helper.dart';
import 'package:eztimesheet/di/service_locator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper databaseHelper;
  late MonthlyRateRepository monthlyRateRepository;
  late EmployeeRepository employeeRepository;

  setUpAll(() async {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Setup service locator
    await setupServiceLocator();

    databaseHelper = getIt<DatabaseHelper>();
    monthlyRateRepository = getIt<MonthlyRateRepository>();
    employeeRepository = getIt<EmployeeRepository>();

    // Initialize database
    await databaseHelper.database;
  });

  setUp(() async {
    // Clear database before each test
    final db = await databaseHelper.database;
    await db.delete('monthly_rates');
    await db.delete('employees');
  });

  tearDownAll(() async {
    // Close database
    await databaseHelper.close();
  });

  group('MonthlyRateRepository', () {
    test('should create monthly rate', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      final rate = MonthlyRate(
        employeeId: employee.id,
        month: '2024-04',
        dailyRate: 500000,
      );

      final created = await monthlyRateRepository.create(rate);

      expect(created.id, isNotEmpty);
      expect(created.employeeId, employee.id);
      expect(created.month, '2024-04');
      expect(created.dailyRate, 500000);
    });

    test('should get monthly rate by id', () async {
      final employee = await employeeRepository.create(Employee(name: 'Jane Smith', phone: '0987654321'));

      final rate = MonthlyRate(
        employeeId: employee.id,
        month: '2024-05',
        dailyRate: 600000,
      );

      final created = await monthlyRateRepository.create(rate);
      final retrieved = await monthlyRateRepository.getById(created.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, created.id);
      expect(retrieved.month, '2024-05');
    });

    test('should get all monthly rates', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee.id,
        month: '2024-04',
        dailyRate: 500000,
      ));

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee.id,
        month: '2024-05',
        dailyRate: 600000,
      ));

      final rates = await monthlyRateRepository.getAll();

      expect(rates.length, 2);
    });

    test('should get monthly rate by employee and month', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee.id,
        month: '2024-04',
        dailyRate: 500000,
      ));

      final rate = await monthlyRateRepository.getByEmployeeAndMonth(employee.id, '2024-04');

      expect(rate, isNotNull);
      expect(rate!.employeeId, employee.id);
      expect(rate.month, '2024-04');
    });

    test('should return null when monthly rate not found by employee and month', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      final rate = await monthlyRateRepository.getByEmployeeAndMonth(employee.id, '2024-04');

      expect(rate, isNull);
    });

    test('should get monthly rates by employee id', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee.id,
        month: '2024-04',
        dailyRate: 500000,
      ));

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee.id,
        month: '2024-05',
        dailyRate: 600000,
      ));

      final rates = await monthlyRateRepository.getByEmployeeId(employee.id);

      expect(rates.length, 2);
      expect(rates.every((r) => r.employeeId == employee.id), true);
    });

    test('should get monthly rates by month', () async {
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

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee1.id,
        month: '2024-05',
        dailyRate: 550000,
      ));

      final rates = await monthlyRateRepository.getByMonth('2024-04');

      expect(rates.length, 2);
      expect(rates.every((r) => r.month == '2024-04'), true);
    });

    test('should update monthly rate', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      final rate = MonthlyRate(
        employeeId: employee.id,
        month: '2024-04',
        dailyRate: 500000,
      );

      final created = await monthlyRateRepository.create(rate);
      final updated = await monthlyRateRepository.update(
        created.copyWith(
          dailyRate: 600000,
          nightBonus: 2.0,
        ),
      );

      expect(updated.dailyRate, 600000);
      expect(updated.nightBonus, 2.0);
    });

    test('should delete monthly rate', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      final rate = MonthlyRate(
        employeeId: employee.id,
        month: '2024-04',
        dailyRate: 500000,
      );

      final created = await monthlyRateRepository.create(rate);
      await monthlyRateRepository.delete(created.id);

      final retrieved = await monthlyRateRepository.getById(created.id);

      expect(retrieved, isNull);
    });

    test('should check if monthly rate exists for employee and month', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      final existsBefore = await monthlyRateRepository.exists(employee.id, '2024-04');
      expect(existsBefore, false);

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee.id,
        month: '2024-04',
        dailyRate: 500000,
      ));

      final existsAfter = await monthlyRateRepository.exists(employee.id, '2024-04');
      expect(existsAfter, true);
    });

    test('should prevent duplicate monthly rate for same employee and month', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee.id,
        month: '2024-04',
        dailyRate: 500000,
      ));

      expect(
        () => monthlyRateRepository.create(MonthlyRate(
          employeeId: employee.id,
          month: '2024-04',
          dailyRate: 600000,
        )),
        throwsA(isA<Exception>()),
      );
    });

    test('should allow different monthly rates for same employee in different months', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee.id,
        month: '2024-04',
        dailyRate: 500000,
      ));

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee.id,
        month: '2024-05',
        dailyRate: 600000,
      ));

      final rates = await monthlyRateRepository.getByEmployeeId(employee.id);

      expect(rates.length, 2);
    });

    test('should allow different monthly rates for different employees in same month', () async {
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

      final rates = await monthlyRateRepository.getByMonth('2024-04');

      expect(rates.length, 2);
    });

    test('should return empty list when no monthly rates exist', () async {
      final rates = await monthlyRateRepository.getAll();

      expect(rates, isEmpty);
    });

    test('should return empty list when getting rates by employee with no data', () async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      final rates = await monthlyRateRepository.getByEmployeeId(employee.id);

      expect(rates, isEmpty);
    });

    test('should return empty list when getting rates by month with no data', () async {
      final rates = await monthlyRateRepository.getByMonth('2024-04');

      expect(rates, isEmpty);
    });
  });
}
