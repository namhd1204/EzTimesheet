import 'package:get_it/get_it.dart';
import '../database/database_helper.dart';
import '../repositories/repositories.dart';
import '../services/services.dart';

/// Service locator for dependency injection
final getIt = GetIt.instance;

/// Setup service locator with all dependencies
Future<void> setupServiceLocator() async {
  // Register singletons

  // Database helper
  getIt.registerSingleton<DatabaseHelper>(DatabaseHelper());

  // Repositories
  getIt.registerSingleton<EmployeeRepository>(
    EmployeeRepositoryImpl(getIt<DatabaseHelper>()),
  );
  getIt.registerSingleton<AttendanceRepository>(
    AttendanceRepositoryImpl(getIt<DatabaseHelper>()),
  );
  getIt.registerSingleton<MonthlyRateRepository>(
    MonthlyRateRepositoryImpl(getIt<DatabaseHelper>()),
  );
  getIt.registerSingleton<MonthLockRepository>(
    MonthLockRepositoryImpl(getIt<DatabaseHelper>()),
  );

  // Services
  getIt.registerSingleton<GoogleDriveService>(GoogleDriveService());
  
  getIt.registerSingleton<AttendanceService>(
    AttendanceService(
      getIt<AttendanceRepository>(),
      getIt<EmployeeRepository>(),
      getIt<MonthLockRepository>(),
    ),
  );
  getIt.registerSingleton<PayrollService>(
    PayrollService(
      getIt<AttendanceRepository>(),
      getIt<MonthlyRateRepository>(),
      getIt<MonthLockRepository>(),
    ),
  );
  getIt.registerSingleton<BackupService>(
    BackupService(
      getIt<EmployeeRepository>(),
      getIt<AttendanceRepository>(),
      getIt<MonthlyRateRepository>(),
      getIt<MonthLockRepository>(),
      getIt<GoogleDriveService>(),
    ),
  );
}

/// Reset service locator (for testing)
Future<void> resetServiceLocator() async {
  await getIt.reset();
}
