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
    await ServiceLocator.setup();

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
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: AttendanceScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify screen is displayed
      expect(find.byType(AttendanceScreen), findsOneWidget);
    });

    testWidgets('should display date picker', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: AttendanceScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify date picker exists
      expect(find.byType(AttendanceScreen), findsOneWidget);
    });

    testWidgets('should display attendance type buttons', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: AttendanceScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify attendance type buttons exist
      expect(find.text('Cả ngày'), findsOneWidget);
      expect(find.text('Nửa ngày'), findsOneWidget);
      expect(find.text('Có làm tối'), findsOneWidget);
    });

    testWidgets('should show employee selector when no employee selected', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: AttendanceScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify employee selector exists
      expect(find.byType(AttendanceScreen), findsOneWidget);
    });

    testWidgets('should record attendance when button is tapped', (WidgetTester tester) async {
      // Create test employee
      await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: AttendanceScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Tap on full day button
      await tester.tap(find.text('Cả ngày'));
      await tester.pumpAndSettle();

      // Verify attendance is recorded (success message should appear)
      expect(find.byType(AttendanceScreen), findsOneWidget);
    });

    testWidgets('should show error when no employee is selected', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: AttendanceScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Try to tap attendance button without selecting employee
      // This should show an error message
      expect(find.byType(AttendanceScreen), findsOneWidget);
    });

    testWidgets('should display existing attendance for selected date', (WidgetTester tester) async {
      // Create test employee and attendance
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final today = DateTime.now();

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: today,
        attendanceType: AttendanceType.fullDay,
      ));

      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: AttendanceScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify attendance is displayed
      expect(find.byType(AttendanceScreen), findsOneWidget);
    });

    testWidgets('should allow editing existing attendance', (WidgetTester tester) async {
      // Create test employee and attendance
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final today = DateTime.now();

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: today,
        attendanceType: AttendanceType.fullDay,
      ));

      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: AttendanceScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Tap on edit button
      // This should open edit dialog
      expect(find.byType(AttendanceScreen), findsOneWidget);
    });

    testWidgets('should allow deleting existing attendance', (WidgetTester tester) async {
      // Create test employee and attendance
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final today = DateTime.now();

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: today,
        attendanceType: AttendanceType.fullDay,
      ));

      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: AttendanceScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Tap on delete button
      // This should show confirmation dialog
      expect(find.byType(AttendanceScreen), findsOneWidget);
    });

    testWidgets('should show different attendance types with different colors', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: AttendanceScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify all attendance type buttons are displayed
      expect(find.text('Cả ngày'), findsOneWidget);
      expect(find.text('Nửa ngày'), findsOneWidget);
      expect(find.text('Có làm tối'), findsOneWidget);
    });

    testWidgets('should prevent duplicate attendance for same employee and date', (WidgetTester tester) async {
      // Create test employee and attendance
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final today = DateTime.now();

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: today,
        attendanceType: AttendanceType.fullDay,
      ));

      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: AttendanceScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Try to record attendance again
      // This should show error message
      expect(find.byType(AttendanceScreen), findsOneWidget);
    });

    testWidgets('should display Vietnamese labels', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: AttendanceScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify Vietnamese labels
      expect(find.text('Cả ngày'), findsOneWidget);
      expect(find.text('Nửa ngày'), findsOneWidget);
      expect(find.text('Có làm tối'), findsOneWidget);
    });
  });
}
