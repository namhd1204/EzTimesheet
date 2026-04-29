import 'package:flutter_test/flutter_test.dart';
import 'package:eztimesheet/models/models.dart';
import 'package:eztimesheet/repositories/repositories.dart';
import 'package:eztimesheet/database/database_helper.dart';
import 'package:eztimesheet/di/service_locator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper databaseHelper;
  late EmployeeRepository employeeRepository;

  setUpAll(() async {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Setup service locator
    await setupServiceLocator();

    databaseHelper = getIt<DatabaseHelper>();
    employeeRepository = getIt<EmployeeRepository>();

    // Initialize database
    await databaseHelper.database;
  });

  setUp(() async {
    // Clear database before each test
    final db = await databaseHelper.database;
    await db.delete('employees');
  });

  tearDownAll(() async {
    // Close database
    await databaseHelper.close();
  });

  group('EmployeeRepository', () {
    test('should create employee', () async {
      final employee = Employee(
        name: 'John Doe',
        phone: '0123456789',
      );

      final created = await employeeRepository.create(employee);

      expect(created.id, isNotEmpty);
      expect(created.name, 'John Doe');
      expect(created.phone, '0123456789');
      expect(created.isActive, true);
    });

    test('should get employee by id', () async {
      final employee = Employee(
        name: 'Jane Smith',
        phone: '0987654321',
      );

      final created = await employeeRepository.create(employee);
      final retrieved = await employeeRepository.getById(created.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, created.id);
      expect(retrieved.name, 'Jane Smith');
    });

    test('should get all employees', () async {
      await employeeRepository.create(Employee(name: 'Employee 1', phone: '0123456789'));
      await employeeRepository.create(Employee(name: 'Employee 2', phone: '0987654321'));
      await employeeRepository.create(Employee(name: 'Employee 3', phone: '0111222333'));

      final employees = await employeeRepository.getAll();

      expect(employees.length, 3);
    });

    test('should get only active employees', () async {
      await employeeRepository.create(Employee(name: 'Active 1', phone: '0123456789'));
      await employeeRepository.create(Employee(name: 'Active 2', phone: '0987654321'));
      final inactive = await employeeRepository.create(Employee(name: 'Inactive', phone: '0111222333'));

      await employeeRepository.update(inactive.copyWith(isActive: false));

      final activeEmployees = await employeeRepository.getAllActive();

      expect(activeEmployees.length, 2);
      expect(activeEmployees.any((e) => e.id == inactive.id), false);
    });

    test('should get employee by name and phone', () async {
      final employee = Employee(
        name: 'John Doe',
        phone: '0123456789',
      );

      final created = await employeeRepository.create(employee);
      final retrieved = await employeeRepository.getByNameAndPhone('John Doe', '0123456789');

      expect(retrieved, isNotNull);
      expect(retrieved!.id, created.id);
    });

    test('should return null when employee not found by name and phone', () async {
      final retrieved = await employeeRepository.getByNameAndPhone('Nonexistent', '0000000000');

      expect(retrieved, isNull);
    });

    test('should update employee', () async {
      final employee = Employee(
        name: 'Original Name',
        phone: '0123456789',
      );

      final created = await employeeRepository.create(employee);
      final updated = await employeeRepository.update(
        created.copyWith(
          name: 'Updated Name',
          phone: '0987654321',
        ),
      );

      expect(updated.name, 'Updated Name');
      expect(updated.phone, '0987654321');
    });

    test('should soft delete employee', () async {
      final employee = Employee(
        name: 'To Delete',
        phone: '0123456789',
      );

      final created = await employeeRepository.create(employee);
      await employeeRepository.delete(created.id);

      final retrieved = await employeeRepository.getById(created.id);

      expect(retrieved, isNotNull);
      expect(retrieved!.isActive, false);
    });

    test('should permanently delete employee', () async {
      final employee = Employee(
        name: 'To Delete',
        phone: '0123456789',
      );

      final created = await employeeRepository.create(employee);
      await employeeRepository.permanentDelete(created.id);

      final retrieved = await employeeRepository.getById(created.id);

      expect(retrieved, isNull);
    });

    test('should count active employees', () async {
      await employeeRepository.create(Employee(name: 'Active 1', phone: '0123456789'));
      await employeeRepository.create(Employee(name: 'Active 2', phone: '0987654321'));
      final inactive = await employeeRepository.create(Employee(name: 'Inactive', phone: '0111222333'));

      await employeeRepository.update(inactive.copyWith(isActive: false));

      final count = await employeeRepository.countActive();

      expect(count, 2);
    });

    test('should handle multiple employees with same name but different phone', () async {
      await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      await employeeRepository.create(Employee(name: 'John Doe', phone: '0987654321'));

      final employees = await employeeRepository.getAll();

      expect(employees.length, 2);
      expect(employees.where((e) => e.name == 'John Doe').length, 2);
    });

    test('should return empty list when no employees exist', () async {
      final employees = await employeeRepository.getAll();

      expect(employees, isEmpty);
    });

    test('should return 0 when counting active employees with no data', () async {
      final count = await employeeRepository.countActive();

      expect(count, 0);
    });
  });
}
