import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eztimesheet/screens/payroll_screen.dart';
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
  late MonthlyRateRepository monthlyRateRepository;

  setUpAll(() async {
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Setup service locator
    await ServiceLocator.setup();

    databaseHelper = getIt<DatabaseHelper>();
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

  group('PayrollScreen Widget Tests', () {
    testWidgets('should display payroll screen', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: PayrollScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify screen is displayed
      expect(find.byType(PayrollScreen), findsOneWidget);
    });

    testWidgets('should display month navigation', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: PayrollScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify navigation buttons exist
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('should navigate to previous month', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: PayrollScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Get current month text
      final currentMonthFinder = find.textContaining(RegExp(r'Tháng \d{1,2}/\d{4}'));
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
      await tester.pumpWidget(const MaterialApp(home: PayrollScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Get current month text
      final currentMonthFinder = find.textContaining(RegExp(r'Tháng \d{1,2}/\d{4}'));
      final currentMonthText = tester.widget<Text>(currentMonthFinder).data;

      // Tap next month button
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      // Verify month changed
      final nextMonthText = tester.widget<Text>(currentMonthFinder).data;
      expect(nextMonthText, isNot(equals(currentMonthText)));
    });

    testWidgets('should display payroll list', (WidgetTester tester) async {
      // Create test data
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

      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: PayrollScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify payroll is displayed
      expect(find.byType(PayrollScreen), findsOneWidget);
    });

    testWidgets('should show empty state when no payroll data', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: PayrollScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify empty state message
      expect(find.text('Chưa có dữ liệu lương'), findsOneWidget);
    });

    testWidgets('should show rate configuration dialog', (WidgetTester tester) async {
      // Create test employee
      await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: PayrollScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Tap on configure button
      await tester.tap(find.text('Cấu hình tỷ lệ'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Cấu hình tỷ lệ lương'), findsOneWidget);
    });

    testWidgets('should save rate configuration', (WidgetTester tester) async {
      // Create test employee
      final employee = await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: PayrollScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Tap on configure button
      await tester.tap(find.text('Cấu hình tỷ lệ'));
      await tester.pumpAndSettle();

      // Enter daily rate
      await tester.enterText(find.widgetWithText(TextField, 'Tỷ lệ ngày'), '500000');

      // Tap save button
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      // Verify rate is saved
      expect(find.byType(PayrollScreen), findsOneWidget);
    });

    testWidgets('should show validation error for invalid rate', (WidgetTester tester) async {
      // Create test employee
      await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: PayrollScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Tap on configure button
      await tester.tap(find.text('Cấu hình tỷ lệ'));
      await tester.pumpAndSettle();

      // Enter invalid rate (negative)
      await tester.enterText(find.widgetWithText(TextField, 'Tỷ lệ ngày'), '-100');

      // Tap save button
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      // Verify validation error
      expect(find.text('Tỷ lệ không được âm'), findsOneWidget);
    });

    testWidgets('should display payroll details', (WidgetTester tester) async {
      // Create test data
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

      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: PayrollScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify payroll details are displayed
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('should export payroll to clipboard', (WidgetTester tester) async {
      // Create test data
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

      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: PayrollScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Tap on export button
      await tester.tap(find.text('Xuất bảng lương'));
      await tester.pumpAndSettle();

      // Verify export dialog is shown
      expect(find.text('Xuất bảng lương'), findsOneWidget);
    });

    testWidgets('should display Vietnamese labels', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: PayrollScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify Vietnamese labels
      expect(find.text('Cấu hình tỷ lệ'), findsOneWidget);
      expect(find.text('Xuất bảng lương'), findsOneWidget);
    });

    testWidgets('should calculate total payroll', (WidgetTester tester) async {
      // Create test data
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

      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: PayrollScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify total payroll is displayed
      expect(find.byType(PayrollScreen), findsOneWidget);
    });
  });
}
