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
  late BackupService backupService;
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
    backupService = getIt<BackupService>();
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

  group('BackupService', () {
    test('should export data to JSON', () async {
      // Create test data
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: DateTime(2024, 4, 15),
        attendanceType: AttendanceType.fullDay,
      ));

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee.id,
        month: '2024-04',
        dailyRate: 500000,
      ));

      // Export data
      final jsonData = await backupService.exportData();

      expect(jsonData, isNotEmpty);
      expect(jsonData.contains('"employees"'), true);
      expect(jsonData.contains('"attendance_records"'), true);
      expect(jsonData.contains('"monthly_rates"'), true);
    });

    test('should export empty data', () async {
      // Export data with no records
      final jsonData = await backupService.exportData();

      expect(jsonData, isNotEmpty);
      expect(jsonData.contains('"employees": []'), true);
      expect(jsonData.contains('"attendance_records": []'), true);
      expect(jsonData.contains('"monthly_rates": []'), true);
    });

    test('should import data from JSON', () async {
      // Create test JSON data
      final jsonData = '''
{
  "employees": [
    {
      "id": "emp-1",
      "name": "John Doe",
      "phone": "0123456789",
      "photo_path": null,
      "is_active": true,
      "created_at": "2024-04-15T00:00:00.000Z",
      "updated_at": "2024-04-15T00:00:00.000Z"
    }
  ],
  "attendance_records": [
    {
      "id": "att-1",
      "employee_id": "emp-1",
      "date": "2024-04-15",
      "attendance_type": "fullDay",
      "created_at": "2024-04-15T00:00:00.000Z",
      "updated_at": "2024-04-15T00:00:00.000Z"
    }
  ],
  "monthly_rates": [
    {
      "id": "rate-1",
      "employee_id": "emp-1",
      "month": "2024-04",
      "daily_rate": 500000,
      "night_rate_multiplier": 1.5,
      "created_at": "2024-04-15T00:00:00.000Z",
      "updated_at": "2024-04-15T00:00:00.000Z"
    }
  ]
}
''';

      // Import data
      final summary = await backupService.importData(jsonData);

      expect(summary.employeesImported, 1);
      expect(summary.employeesFailed, 0);
      expect(summary.attendanceImported, 1);
      expect(summary.attendanceFailed, 0);
      expect(summary.ratesImported, 1);
      expect(summary.ratesFailed, 0);
      expect(summary.hasFailures, false);
    });

    test('should import empty JSON', () async {
      final jsonData = '''
{
  "employees": [],
  "attendance_records": [],
  "monthly_rates": []
}
''';

      final summary = await backupService.importData(jsonData);

      expect(summary.employeesImported, 0);
      expect(summary.employeesFailed, 0);
      expect(summary.attendanceImported, 0);
      expect(summary.attendanceFailed, 0);
      expect(summary.ratesImported, 0);
      expect(summary.ratesFailed, 0);
    });

    test('should handle invalid JSON format', () async {
      final jsonData = 'invalid json';

      expect(
        () => backupService.importData(jsonData),
        throwsA(isA<BackupException>()),
      );
    });

    test('should handle missing required fields in JSON', () async {
      final jsonData = '''
{
  "employees": [
    {
      "name": "John Doe"
    }
  ]
}
''';

      final summary = await backupService.importData(jsonData);

      expect(summary.employeesImported, 0);
      expect(summary.employeesFailed, 1);
      expect(summary.hasFailures, true);
    });

    test('should handle duplicate employee IDs during import', () async {
      // Create existing employee
      await employeeRepository.create(Employee(
        id: 'emp-1',
        name: 'Existing Employee',
        phone: '0123456789',
      ));

      final jsonData = '''
{
  "employees": [
    {
      "id": "emp-1",
      "name": "John Doe",
      "phone": "0987654321",
      "is_active": true,
      "created_at": "2024-04-15T00:00:00.000Z",
      "updated_at": "2024-04-15T00:00:00.000Z"
    }
  ],
  "attendance_records": [],
  "monthly_rates": []
}
''';

      final summary = await backupService.importData(jsonData);

      expect(summary.employeesImported, 0);
      expect(summary.employeesFailed, 1);
      expect(summary.hasFailures, true);
    });

    test('should handle invalid attendance record during import', () async {
      final jsonData = '''
{
  "employees": [],
  "attendance_records": [
    {
      "id": "att-1",
      "employee_id": "nonexistent",
      "date": "2024-04-15",
      "attendance_type": "fullDay"
    }
  ],
  "monthly_rates": []
}
''';

      final summary = await backupService.importData(jsonData);

      expect(summary.attendanceImported, 0);
      expect(summary.attendanceFailed, 1);
      expect(summary.hasFailures, true);
    });

    test('should handle invalid monthly rate during import', () async {
      final jsonData = '''
{
  "employees": [],
  "attendance_records": [],
  "monthly_rates": [
    {
      "id": "rate-1",
      "employee_id": "nonexistent",
      "month": "2024-04",
      "daily_rate": 500000
    }
  ]
}
''';

      final summary = await backupService.importData(jsonData);

      expect(summary.ratesImported, 0);
      expect(summary.ratesFailed, 1);
      expect(summary.hasFailures, true);
    });

    test('should export and import data correctly', () async {
      // Create test data
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: DateTime(2024, 4, 15),
        attendanceType: AttendanceType.fullDay,
      ));

      await monthlyRateRepository.create(MonthlyRate(
        employeeId: employee.id,
        month: '2024-04',
        dailyRate: 500000,
      ));

      // Export data
      final jsonData = await backupService.exportData();

      // Clear database
      final db = await databaseHelper.database;
      await db.delete('monthly_rates');
      await db.delete('attendance_records');
      await db.delete('employees');

      // Import data
      final summary = await backupService.importData(jsonData);

      expect(summary.employeesImported, 1);
      expect(summary.attendanceImported, 1);
      expect(summary.ratesImported, 1);
      expect(summary.hasFailures, false);

      // Verify imported data
      final employees = await employeeRepository.getAll();
      expect(employees.length, 1);
      expect(employees.first.name, 'John Doe');

      final attendanceRecords = await attendanceRepository.getAll();
      expect(attendanceRecords.length, 1);

      final monthlyRates = await monthlyRateRepository.getAll();
      expect(monthlyRates.length, 1);
    });

    test('should handle large dataset during export', () async {
      // Create multiple employees
      for (int i = 0; i < 10; i++) {
        final employee = await employeeRepository.create(Employee(name: 'Employee $i', phone: '0123456789'));

        await attendanceRepository.create(AttendanceRecord(
          employeeId: employee.id,
          date: DateTime(2024, 4, 15 + i),
          attendanceType: AttendanceType.fullDay,
        ));

        await monthlyRateRepository.create(MonthlyRate(
          employeeId: employee.id,
          month: '2024-04',
          dailyRate: 500000 + (i * 10000),
        ));
      }

      // Export data
      final jsonData = await backupService.exportData();

      expect(jsonData, isNotEmpty);
      expect(jsonData.contains('"employees"'), true);
      expect(jsonData.contains('"attendance_records"'), true);
      expect(jsonData.contains('"monthly_rates"'), true);
    });
  });
}
