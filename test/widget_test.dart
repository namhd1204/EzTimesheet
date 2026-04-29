import 'package:flutter_test/flutter_test.dart';
import 'package:eztimesheet/main.dart';
import 'package:eztimesheet/di/service_locator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() async {
    // Initialize FFI for tests
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    // Setup service locator
    await setupServiceLocator();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EzTimesheetApp());

    // Verify that the app starts
    expect(find.text('Chấm công'), findsWidgets);
  });
}
