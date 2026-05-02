# EzTimesheet Architecture - Friction Points with Code Examples

## Overview
This document shows concrete code examples of each friction point, making it clear what the problems are and why they matter.

---

## Friction Point #1: Rate Carry-Over Logic Scattered

### Current State: Logic in Service

**File**: `lib/services/payroll_service.dart` (lines 18-56)

```dart
Future<PayrollResult> calculatePayroll(
  String employeeId,
  String month, // Format: YYYY-MM
) async {
  try {
    // Get monthly rate for employee
    var rate = await _monthlyRateRepository.getByEmployeeAndMonth(
      employeeId,
      month,
    );

    if (rate == null) {
      // ❌ PROBLEM: Carry-over logic embedded in business logic
      // Carry-over logic: Get most recent previous rate
      final latestRate = await _monthlyRateRepository.getLatestRate(employeeId);
      if (latestRate != null) {
        // Create new rate for this month based on latest
        rate = MonthlyRate(
          employeeId: employeeId,
          month: month,
          dailyRate: latestRate.dailyRate,
          nightBonus: latestRate.nightBonus,
        );
        await _monthlyRateRepository.create(rate);
      } else {
        throw PayrollException('Lỗi: Chưa cấu hình lương...');
      }
    }
    // ... rest of calculation ...
  }
}
```

### Problem 1: Screen Must Know About It

**File**: `lib/screens/payroll_screen.dart` (lines 40-47)

```dart
Future<void> _loadData() async {
  // ...
  try {
    final employees = await _employeeRepository.getAllActive();
    final monthString = DateFormatters.formatMonthForStorage(_currentMonth);
    final employeeIds = employees.map((e) => e.id).toList();

    // ❌ PROBLEM: Screen must know to call this BEFORE getting payroll
    // This is implementation detail leaking to UI layer
    await _payrollService.ensureRatesForMonth(employeeIds, monthString);
    
    // Only AFTER we ensure rates can we get the payroll
    final view = await _payrollService.getPayrollMonthView(
      employeeIds,
      monthString,
    );
```

### Problem 2: ensureRatesForMonth() Does the Same Thing

**File**: `lib/services/payroll_service.dart` (lines 85-105)

```dart
/// Ensure rates exist for all employees in a month (carry-over logic)
Future<void> ensureRatesForMonth(
  List<String> employeeIds,
  String month,
) async {
  // ❌ PROBLEM: Same logic duplicated in two places!
  final existingRates = await _monthlyRateRepository.getByMonth(month);
  final existingIds = existingRates.map((r) => r.employeeId).toSet();

  for (final id in employeeIds) {
    if (!existingIds.contains(id)) {
      final latestRate = await _monthlyRateRepository.getLatestRate(id);
      if (latestRate != null) {
        final rate = MonthlyRate(
          employeeId: id,
          month: month,
          dailyRate: latestRate.dailyRate,
          nightBonus: latestRate.nightBonus,
        );
        await _monthlyRateRepository.create(rate);
      }
    }
  }
}
```

### Why This Is a Problem

1. **Logic in two places**: Both `calculatePayroll()` and `ensureRatesForMonth()` implement carry-over
2. **Screen knows implementation detail**: Must call `ensureRatesForMonth()` first
3. **Hard to find**: Change carry-over logic? Update both methods
4. **Untestable in isolation**: Tests must set up database state, call screen method, then check service

### How It Should Look

```dart
// ✅ GOOD: Single, testable policy service
class RateCarryOverPolicy {
  final MonthlyRateRepository _repository;

  RateCarryOverPolicy(this._repository);

  Future<MonthlyRate> ensureOrCarryOver(
    String employeeId,
    String month,
  ) async {
    var rate = await _repository.getByEmployeeAndMonth(employeeId, month);
    
    if (rate == null) {
      final latestRate = await _repository.getLatestRate(employeeId);
      if (latestRate != null) {
        rate = MonthlyRate(
          employeeId: employeeId,
          month: month,
          dailyRate: latestRate.dailyRate,
          nightBonus: latestRate.nightBonus,
        );
        await _repository.create(rate);
      } else {
        throw RateNotConfiguredException(employeeId, month);
      }
    }
    return rate;
  }
}

// ✅ GOOD: Service uses policy
class PayrollService {
  final RateCarryOverPolicy _policy;
  
  Future<PayrollResult> calculatePayroll(
    String employeeId,
    String month,
  ) async {
    final rate = await _policy.ensureOrCarryOver(employeeId, month);
    // ... rest of calculation using 'rate' ...
  }
}

// ✅ GOOD: Screen doesn't need to know
class PayrollScreen {
  Future<void> _loadData() async {
    final view = await _payrollService.getPayrollMonthView(employeeIds, month);
    // Done! Service handles carry-over internally
  }
}
```

---

## Friction Point #2: Month Lock Enforcement Scattered

### Current State: No Unified Lock Validation

**In PayrollScreen**, lock is checked before UI interaction:
```dart
Future<void> _configureRate(Employee employee) async {
  if (_isLocked) {
    // ❌ PROBLEM: Screen is responsible for checking lock
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dữ liệu đã chốt'),
        content: const Text('Tháng này đã được chốt...'),
        // ...
      ),
    );
    if (confirmed != true) return;
  }
  // ... rest of configuration ...
}
```

**But in AttendanceService**, no lock check exists:
```dart
Future<AttendanceRecord> recordAttendance(
  String employeeId,
  DateTime date, {
  WorkStatus workStatus = WorkStatus.none,
  bool hasNightShift = false,
}) async {
  // ❌ PROBLEM: No lock validation here!
  // Service allows recording attendance on locked month?
  
  // Only employee validation:
  final employee = await _employeeRepository.getById(employeeId);
  if (employee == null) {
    throw AttendanceException('Lỗi: Không tìm thấy nhân viên');
  }
  
  // ... no lock check, so service can be called regardless of lock state
}
```

### Why This Is a Problem

1. **Enforcement is inconsistent**: Screen checks lock, but service doesn't
2. **Business rule spread across layers**: Lock enforcement should be in service, not UI
3. **Multiple callers must know**: Any caller of `recordAttendance()` must check lock first
4. **Hard to test**: Test that lock prevents changes? Must set up screen, trigger dialog, etc.

### How It Should Look

```dart
// ✅ GOOD: Single lock validator service
class LockValidator {
  final MonthLockRepository _repository;

  LockValidator(this._repository);

  Future<void> validateCanEdit(String month) async {
    if (await _repository.isLocked(month)) {
      throw MonthLockedException(month);
    }
  }
}

// ✅ GOOD: Service enforces lock
class AttendanceService {
  final LockValidator _lockValidator;
  
  Future<AttendanceRecord> recordAttendance(
    String employeeId,
    DateTime date, {
    WorkStatus workStatus = WorkStatus.none,
    bool hasNightShift = false,
  }) async {
    // ✅ Always validate lock first
    final month = DateFormatters.formatMonthForStorage(date);
    await _lockValidator.validateCanEdit(month);
    
    // ... rest of logic ...
  }
}

// ✅ GOOD: Screen doesn't need to validate (service will throw)
// But screen can catch exception and show confirmation if needed
class AttendanceScreen {
  Future<void> _updateAttendance(String employeeId, ...) async {
    try {
      await _attendanceService.recordAttendance(...);
    } on MonthLockedException catch (e) {
      // Show confirmation: "Month is locked, sure you want to edit?"
      // If user confirms, call again (service will throw again, or add override)
    }
  }
}
```

---

## Friction Point #3: Batch-Loading Details Leak to Screens

### Current State: View Transfer Objects

**Service returns batch-loaded data in wrapper object**:
```dart
// lib/services/attendance_service.dart
class AttendanceDayView {
  final Map<String, AttendanceRecord?> attendanceMap;
  final bool isMonthLocked;

  const AttendanceDayView({
    required this.attendanceMap,
    required this.isMonthLocked,
  });
}

Future<AttendanceDayView> getAttendanceDayView(
  List<String> employeeIds,
  DateTime date,
) async {
  // ✅ GOOD: Batches queries in parallel
  final results = await Future.wait([
    _attendanceRepository.getByEmployeesAndDateRange(...),
    _monthLockRepository.isLocked(month),
  ]);
  
  // ❌ PROBLEM: Returns in custom view object
  return AttendanceDayView(
    attendanceMap: attendanceMap,
    isMonthLocked: isLocked,
  );
}
```

**Screen imports and unpacks immediately**:
```dart
// lib/screens/attendance_screen.dart
import '../services/services.dart'; // Imports AttendanceDayView

Future<void> _loadData() async {
  final dayView = await _attendanceService.getAttendanceDayView(
    employeeIds,
    _selectedDate,
  );

  setState(() {
    _attendanceMap = dayView.attendanceMap;  // ❌ Unpacks immediately
    _isMonthLocked = dayView.isMonthLocked;   // ❌ Unpacks immediately
  });
}
```

### Why This Is a Problem

1. **Screen imports service internals**: `AttendanceDayView` is not a domain concept
2. **Boilerplate unpacking**: Screen gets object only to extract fields immediately
3. **Optimization detail exposed**: View object exists only because of N+1 optimization
4. **Changes affect UI**: If service changes batching strategy, screen code must change
5. **Tests import the object**: Tests verify `AttendanceDayView` structure, not behavior

### How It Should Look

```dart
// ✅ GOOD: Service decides batching internally
class AttendanceService {
  Future<Map<String, AttendanceRecord?>> getAttendanceForDate(
    List<String> employeeIds,
    DateTime date,
  ) async {
    // Service decides: batch in parallel? sequentially? cache?
    // Screen doesn't care.
    
    final results = await Future.wait([
      _attendanceRepository.getByEmployeesAndDateRange(...),
      _monthLockRepository.isLocked(month),
    ]);
    
    // Return domain objects, not wrapper
    final batchMap = results[0] as Map<String, List<AttendanceRecord>>;
    final isLocked = results[1] as bool;
    
    // Store lock state in cache or context if needed
    _lastMonthLocked = isLocked;
    
    // Return just the records
    return {
      for (final id in employeeIds)
        id: batchMap[id]?.isNotEmpty == true ? batchMap[id]!.first : null,
    };
  }
  
  bool get isCurrentMonthLocked => _lastMonthLocked;
}

// ✅ GOOD: Screen uses domain objects directly
class AttendanceScreen {
  Future<void> _loadData() async {
    final attendanceMap = await _attendanceService.getAttendanceForDate(
      employeeIds,
      _selectedDate,
    );
    
    // No wrapper object, no unpacking
    setState(() {
      _attendanceMap = attendanceMap;
      _isMonthLocked = _attendanceService.isCurrentMonthLocked;
    });
  }
}

// ✅ GOOD: Tests verify behavior, not structure
test('getAttendanceForDate should batch load', () async {
  // Mock repository, verify it's called once (not N times)
  final result = await service.getAttendanceForDate(ids, date);
  verify(mockAttendanceRepository.getByEmployeesAndDateRange(...)).calledOnce;
});
```

---

## Friction Point #4: No Mock Repositories → Tests Couple to Database

### Current State: Tests Hit Real Database

**[test/services/attendance_service_test.dart](test/services/attendance_service_test.dart)**:

```dart
void main() {
  late DatabaseHelper databaseHelper;
  late AttendanceService attendanceService;
  late EmployeeRepository employeeRepository;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;  // ❌ Initialize real DB
    
    await setupServiceLocator();           // ❌ Sets up real repos
    
    databaseHelper = getIt<DatabaseHelper>();
    attendanceService = getIt<AttendanceService>();
    employeeRepository = getIt<EmployeeRepository>();
    
    await databaseHelper.database;         // ❌ Opens real DB
  });

  setUp(() async {
    final db = await databaseHelper.database;
    await db.delete('attendance_records');  // ❌ Clears DB between tests
    await db.delete('employees');
  });

  test('should record attendance', () async {
    // ❌ PROBLEM: Test must create real employee in real DB
    final employee = await employeeRepository.create(
      Employee(name: 'John Doe', phone: '0123456789')
    );
    
    // ❌ PROBLEM: Test calls real service with real repo
    final record = await attendanceService.recordAttendance(
      employee.id,
      date,
      workStatus: WorkStatus.fullDay,
    );

    expect(record.employeeId, employee.id);
  });

  test('should throw error if employee not found', () async {
    // ❌ PROBLEM: Can't test this without mocking
    // Must either:
    // 1. Set up a complex DB state to simulate missing employee
    // 2. Or skip this test (usually what happens)
    
    expect(
      () => attendanceService.recordAttendance(
        'non-existent-id',  // This looks valid to the test
        date,
      ),
      throwsA(isA<AttendanceException>()),
    );
  });
}
```

### Why This Is a Problem

1. **Slow**: Database I/O is orders of magnitude slower than mocked returns
2. **Fragile**: If database initialization fails, all tests fail
3. **Can't test errors**: Hard to test "what if repo throws exception?"
4. **State management**: Must clear DB between tests
5. **Can't test concurrency**: Can't simulate concurrent access

### How It Should Look

```dart
// ✅ GOOD: Mock repositories exist
class MockAttendanceRepository extends Mock implements AttendanceRepository {}
class MockEmployeeRepository extends Mock implements EmployeeRepository {}
class MockMonthLockRepository extends Mock implements MonthLockRepository {}

void main() {
  late AttendanceService attendanceService;
  late MockAttendanceRepository mockAttendanceRepository;
  late MockEmployeeRepository mockEmployeeRepository;
  late MockMonthLockRepository mockMonthLockRepository;

  setUp(() {
    mockAttendanceRepository = MockAttendanceRepository();
    mockEmployeeRepository = MockEmployeeRepository();
    mockMonthLockRepository = MockMonthLockRepository();
    
    attendanceService = AttendanceService(
      mockAttendanceRepository,
      mockEmployeeRepository,
      mockMonthLockRepository,
    );
  });

  test('should record attendance', () async {
    final employee = Employee(id: 'emp1', name: 'John', phone: '123');
    final date = DateTime(2024, 4, 15);

    // ✅ GOOD: Mock returns what we want
    when(mockEmployeeRepository.getById('emp1')).thenAnswer(
      (_) async => employee
    );
    when(mockAttendanceRepository.getByEmployeeAndDate('emp1', date))
      .thenAnswer((_) async => null);
    when(mockAttendanceRepository.create(any))
      .thenAnswer((invocation) async => invocation.positionalArguments[0]);

    final record = await attendanceService.recordAttendance(
      'emp1',
      date,
      workStatus: WorkStatus.fullDay,
    );

    expect(record.employeeId, 'emp1');
    expect(record.workStatus, WorkStatus.fullDay);
  });

  test('should throw if employee not found', () async {
    // ✅ GOOD: Easy to test error path
    when(mockEmployeeRepository.getById('bad-id'))
      .thenAnswer((_) async => null);

    expect(
      () => attendanceService.recordAttendance('bad-id', DateTime.now()),
      throwsA(isA<AttendanceException>()),
    );
  });

  test('should throw if month is locked', () async {
    // ✅ GOOD: Can test business rules without DB setup
    when(mockEmployeeRepository.getById('emp1'))
      .thenAnswer((_) async => Employee(id: 'emp1', name: 'John', phone: '123'));
    when(mockMonthLockRepository.isLocked('2024-04'))
      .thenAnswer((_) async => true);

    expect(
      () => attendanceService.recordAttendance('emp1', DateTime(2024, 4, 15)),
      throwsA(isA<MonthLockedException>()),
    );
  });
}
```

---

## Friction Point #5: View Transfer Objects With Low Cohesion

### Current Problem: PayrollResult

**[lib/services/payroll_service.dart](lib/services/payroll_service.dart#L245)**:

```dart
class PayrollResult {
  final String employeeId;        // Input
  final String month;             // Input
  final double dailyRate;         // Input
  final double nightBonus;        // Input
  final int fullDays;             // Input (count)
  final int halfDays;             // Input (count)
  final int nightWorkDays;        // Input (count)
  final double fullDayTotal;      // Output (calculated)
  final double halfDayTotal;      // Output (calculated)
  final double nightWorkTotal;    // Output (calculated)
  final double total;             // Output (calculated)

  // ❌ PROBLEM: Mixes inputs and outputs
  // Screens don't need all these fields
}
```

**How it's used in screens**:

```dart
// lib/screens/payroll_screen.dart
final view = await _payrollService.getPayrollMonthView(employeeIds, month);

setState(() {
  _payrollResults = view.results;  // Maps employeeId -> PayrollResult
  _isLocked = view.isLocked;
});

// Later in build():
for (final result in _payrollResults.values) {
  // Screen manually formats these
  Text(CurrencyFormatters.formatCurrency(result.fullDayTotal))
  Text('${result.fullDays} ngày')
}
```

### Why This Is a Problem

1. **Low cohesion**: Mixes inputs (dailyRate) with outputs (fullDayTotal)
2. **Boilerplate**: Exists only because service needs to return structured data
3. **Screen formatting**: Screens format raw numbers instead of getting pre-formatted results
4. **Hard to test**: Tests must construct PayrollResult objects with correct state
5. **Leaks model**: Not a domain concept; just a data transfer vessel

### How It Should Look

```dart
// ✅ GOOD: Cohesive result object
class PayrollBreakdown {
  final int fullDays;
  final int halfDays;
  final int nightWorkDays;
  
  final String fullDayAmount;     // Pre-formatted
  final String halfDayAmount;     // Pre-formatted
  final String nightWorkAmount;   // Pre-formatted
  final String total;             // Pre-formatted

  PayrollBreakdown({
    required this.fullDays,
    required this.halfDays,
    required this.nightWorkDays,
    required this.fullDayAmount,
    required this.halfDayAmount,
    required this.nightWorkAmount,
    required this.total,
  });

  // ✅ GOOD: Screen-ready display method
  String formatForDisplay() {
    return '''
Full Days: $fullDays ($fullDayAmount)
Half Days: $halfDays ($halfDayAmount)
Night Work: $nightWorkDays ($nightWorkAmount)
Total: $total
    ''';
  }
}

// ✅ GOOD: Service returns screen-ready objects
class PayrollService {
  Future<Map<String, PayrollBreakdown>> getPayrollForMonth(
    List<String> employeeIds,
    String month,
  ) async {
    // ... calculation ...
    
    // Return pre-formatted, cohesive objects
    return {
      for (final id in employeeIds)
        id: PayrollBreakdown(
          fullDays: fullDays,
          halfDays: halfDays,
          nightWorkDays: nightWorkDays,
          fullDayAmount: CurrencyFormatters.format(fullDayTotal),
          halfDayAmount: CurrencyFormatters.format(halfDayTotal),
          nightWorkAmount: CurrencyFormatters.format(nightWorkTotal),
          total: CurrencyFormatters.format(total),
        ),
    };
  }
}

// ✅ GOOD: Screen just displays what it received
class PayrollScreen {
  Future<void> _loadData() async {
    final breakdown = await _payrollService.getPayrollForMonth(ids, month);
    
    setState(() {
      _breakdown = breakdown;  // No unpacking, no formatting
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final result in _breakdown.values)
          Text(result.formatForDisplay()),  // Screen just displays
      ],
    );
  }
}
```

---

## Summary: Common Thread

All five friction points share a common root cause:

**Optimization details and helper objects are leaking from service layer to presentation layer, creating coupling and boilerplate.**

### What's Happening
1. Services batch-load to avoid N+1 → Returns view wrapper → Screens unpack
2. Services have carry-over logic → Screens must know to call ensureRates first
3. Services can't test without mocks → Tests must hit database
4. Lock validation split → Screens must check before calling service
5. Results have low cohesion → Screens must format and transform data

### Root Cause
The service layer is exposing implementation details instead of **presenting complete, screen-ready abstractions**.

### Solution
Hide optimization, formatting, and policy details **inside** the service layer. Return only what the screen needs to display, in the format it needs.

---

## How to Verify These Issues Exist

Run these commands to see the friction:

```bash
# Friction #1: Find all callers of ensureRatesForMonth
grep -r "ensureRatesForMonth" lib/screens/ lib/services/
# → Should be 1-2 calls; if more, carry-over logic is scattered

# Friction #2: Find lock checks
grep -r "isLocked\|MonthLockRepository" lib/screens/ lib/services/
# → Should be in one service, not multiple places

# Friction #3: Find view object imports
grep -r "AttendanceDayView\|PayrollMonthView" lib/screens/
# → Screens shouldn't import these

# Friction #4: Check test database usage
grep -r "databaseFactory\|setupServiceLocator" test/services/
# → Should use mocks instead

# Friction #5: Check PayrollResult usage
grep -r "PayrollResult" lib/screens/ test/
# → Find all places unpacking fields
```

