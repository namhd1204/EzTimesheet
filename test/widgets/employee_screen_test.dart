import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eztimesheet/screens/employee_screen.dart';
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
    await ServiceLocator.setup();

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

  group('EmployeeScreen Widget Tests', () {
    testWidgets('should display employee list', (WidgetTester tester) async {
      // Create test employees
      await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));
      await employeeRepository.create(Employee(name: 'Jane Smith', phone: '0987654321'));

      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: EmployeeScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify employees are displayed
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
    });

    testWidgets('should display empty state when no employees', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: EmployeeScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify empty state message
      expect(find.text('Chưa có nhân viên'), findsOneWidget);
    });

    testWidgets('should show add employee dialog when FAB is tapped', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: EmployeeScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Tap the FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Thêm nhân viên'), findsOneWidget);
      expect(find.text('Họ và tên'), findsOneWidget);
      expect(find.text('Số điện thoại'), findsOneWidget);
    });

    testWidgets('should add employee when form is submitted', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: EmployeeScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Tap the FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Enter employee name
      await tester.enterText(find.widgetWithText(TextField, 'Họ và tên'), 'John Doe');

      // Enter phone number
      await tester.enterText(find.widgetWithText(TextField, 'Số điện thoại'), '0123456789');

      // Tap the save button
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      // Verify employee is added
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('0123456789'), findsOneWidget);
    });

    testWidgets('should show validation error for empty name', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: EmployeeScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Tap the FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Enter phone number only
      await tester.enterText(find.widgetWithText(TextField, 'Số điện thoại'), '0123456789');

      // Tap the save button
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      // Verify validation error
      expect(find.text('Họ và tên là bắt buộc'), findsOneWidget);
    });

    testWidgets('should show validation error for invalid phone', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: EmployeeScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Tap the FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Enter employee name
      await tester.enterText(find.widgetWithText(TextField, 'Họ và tên'), 'John Doe');

      // Enter invalid phone number
      await tester.enterText(find.widgetWithText(TextField, 'Số điện thoại'), '123456789');

      // Tap the save button
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();

      // Verify validation error
      expect(find.text('Số điện thoại không hợp lệ'), findsOneWidget);
    });

    testWidgets('should show employee details when tapped', (WidgetTester tester) async {
      // Create test employee
      await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: EmployeeScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Tap on employee
      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      // Verify details dialog is shown
      expect(find.text('Thông tin nhân viên'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('0123456789'), findsOneWidget);
    });

    testWidgets('should delete employee when delete button is tapped', (WidgetTester tester) async {
      // Create test employee
      await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: EmployeeScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Tap on employee
      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      // Tap delete button
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();

      // Confirm deletion
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();

      // Verify employee is deleted
      expect(find.text('John Doe'), findsNothing);
      expect(find.text('Chưa có nhân viên'), findsOneWidget);
    });

    testWidgets('should cancel delete when cancel button is tapped', (WidgetTester tester) async {
      // Create test employee
      await employeeRepository.create(Employee(name: 'John Doe', phone: '0123456789'));

      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: EmployeeScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Tap on employee
      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      // Tap delete button
      await tester.tap(find.text('Xóa'));
      await tester.pumpAndSettle();

      // Tap cancel button
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      // Verify employee still exists
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('should close dialog when cancel button is tapped', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(const MaterialApp(home: EmployeeScreen()));

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Tap the FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Tap cancel button
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      // Verify dialog is closed
      expect(find.text('Thêm nhân viên'), findsNothing);
    });
  });
}
