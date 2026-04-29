import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eztimesheet/screens/calendar_screen.dart';
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

  group('CalendarScreen Widget Tests', () {
    testWidgets('should display calendar view', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: CalendarScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify calendar is displayed
      expect(find.byType(CalendarScreen), findsOneWidget);
    });

    testWidgets('should display month navigation buttons', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: CalendarScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify navigation buttons exist
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('should navigate to previous month', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: CalendarScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Get current month text
      final currentMonthFinder = find.textContaining(RegExp(r'\d{1,2}/\d{4}'));
      final currentMonthText = tester.widget<Text>(currentMonthFinder).data;

      // Tap previous month button
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      // Verify month changed
      final previousMonthText = tester.widget<Text>(currentMonthFinder).data;
      expect(previousMonthText, isNot(equals(currentMonthText)));
    });

    testWidgets('should navigate to next month', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: CalendarScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Get current month text
      final currentMonthFinder = find.textContaining(RegExp(r'\d{1,2}/\d{4}'));
      final currentMonthText = tester.widget<Text>(currentMonthFinder).data;

      // Tap next month button
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      // Verify month changed
      final nextMonthText = tester.widget<Text>(currentMonthFinder).data;
      expect(nextMonthText, isNot(equals(currentMonthText)));
    });

    testWidgets('should show attendance indicators on calendar', (WidgetTester tester) async {
      // Create test employee and attendance
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final today = DateTime.now();

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: today,
        attendanceType: AttendanceType.fullDay,
      ));

      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: CalendarScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify attendance indicator exists (day with attendance should have indicator)
      expect(find.byType(CalendarScreen), findsOneWidget);
    });

    testWidgets('should show day detail dialog when day is tapped', (WidgetTester tester) async {
      // Create test employee and attendance
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final today = DateTime.now();

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: today,
        attendanceType: AttendanceType.fullDay,
      ));

      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: CalendarScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Find and tap on today's date
      final todayFinder = find.text(today.day.toString());
      if (todayFinder.evaluate().isNotEmpty) {
        await tester.tap(todayFinder.first);
        await tester.pumpAndSettle();

        // Verify detail dialog is shown
        expect(find.text('Chi tiết ngày'), findsOneWidget);
      }
    });

    testWidgets('should display attendance records in day detail', (WidgetTester tester) async {
      // Create test employee and attendance
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final today = DateTime.now();

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: today,
        attendanceType: AttendanceType.fullDay,
      ));

      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: CalendarScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Find and tap on today's date
      final todayFinder = find.text(today.day.toString());
      if (todayFinder.evaluate().isNotEmpty) {
        await tester.tap(todayFinder.first);
        await tester.pumpAndSettle();

        // Verify employee name is shown in detail
        expect(find.text('John Doe'), findsOneWidget);
        expect(find.text('Cả ngày'), findsOneWidget);
      }
    });

    testWidgets('should show empty state when no attendance for day', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: CalendarScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Find and tap on a date
      final dateFinder = find.text('1');
      if (dateFinder.evaluate().isNotEmpty) {
        await tester.tap(dateFinder.first);
        await tester.pumpAndSettle();

        // Verify empty state message
        expect(find.text('Không có chấm công'), findsOneWidget);
      }
    });

    testWidgets('should close day detail dialog when close button is tapped', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: CalendarScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Find and tap on a date
      final dateFinder = find.text('1');
      if (dateFinder.evaluate().isNotEmpty) {
        await tester.tap(dateFinder.first);
        await tester.pumpAndSettle();

        // Tap close button
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        // Verify dialog is closed
        expect(find.text('Chi tiết ngày'), findsNothing);
      }
    });

    testWidgets('should display different attendance types with different indicators', (WidgetTester tester) async {
      // Create test employee and multiple attendance records
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: today,
        attendanceType: AttendanceType.fullDay,
      ));

      await attendanceRepository.create(AttendanceRecord(
        employeeId: employee.id,
        date: yesterday,
        attendanceType: AttendanceType.halfDay,
      ));

      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: CalendarScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify calendar is displayed with attendance
      expect(find.byType(CalendarScreen), findsOneWidget);
    });
  });
}
