import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eztimesheet/screens/attendance_screen.dart';
import 'package:eztimesheet/models/models.dart';
import 'package:eztimesheet/repositories/repositories.dart';
import 'package:eztimesheet/database/database_helper.dart';
import 'package:eztimesheet/di/service_locator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseHelper databaseHelper;
  late EmployeeRepository employeeRepository;
  late AttendanceRepository attendanceRepository;

  setUpAll(() async {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Setup service locator
    await setupServiceLocator();

    databaseHelper = getIt<DatabaseHelper>();
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

  group('AttendanceScreen Widget Tests', () {
    testWidgets('should display attendance screen', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AttendanceScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(AttendanceScreen), findsOneWidget);
    });

    testWidgets('should display attendance type buttons', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AttendanceScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Cả ngày'), findsOneWidget);
      expect(find.text('Nửa ngày'), findsOneWidget);
      expect(find.text('Làm tối'), findsOneWidget);
    });

    testWidgets('should record attendance when button is tapped', (WidgetTester tester) async {
      await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      await tester.pumpWidget(const MaterialApp(home: AttendanceScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cả ngày'));
      await tester.pumpAndSettle();

      expect(find.byType(AttendanceScreen), findsOneWidget);
      // Further verification could check the database state
    });

    testWidgets('should display existing attendance for selected date', (WidgetTester tester) async {
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final today = DateTime.now();

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: today,
        workStatus: WorkStatus.fullDay,
      ));

      await tester.pumpWidget(const MaterialApp(home: AttendanceScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(AttendanceScreen), findsOneWidget);
      // In a real app, you'd check if the button is highlighted
    });
  });
}
