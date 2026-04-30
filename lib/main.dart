import 'package:flutter/material.dart';
import 'design_system/app_theme.dart';
import 'screens/employee_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/payroll_screen.dart';
import 'di/service_locator.dart';
import 'services/services.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    databaseFactory = createDatabaseFactoryFfiWeb(
      options: SqfliteFfiWebOptions(
        // ignore: invalid_use_of_visible_for_testing_member
        forceAsBasicWorker: true,
        indexedDbName: 'eztimesheet_v2', // Đổi sang v2
      ),
    );
  }

  // Set up service locator
  await setupServiceLocator();

  // Restore Google Sign-In session
  getIt<GoogleDriveService>().signInSilently();

  // Perform auto-backup in background
  getIt<BackupService>().performAutoBackup();

  runApp(const EzTimesheetApp());
}

class EzTimesheetApp extends StatelessWidget {
  const EzTimesheetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EzTimesheet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const AttendanceScreen(),
    const EmployeeScreen(),
    const PayrollScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Chấm công',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Nhân viên',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Lương & Báo cáo',
          ),
        ],
      ),
    );
  }
}
