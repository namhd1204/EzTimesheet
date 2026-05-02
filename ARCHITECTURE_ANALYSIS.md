# EzTimesheet Architecture Analysis

## Executive Summary

EzTimesheet is a moderately well-structured Dart/Flutter timesheet and payroll application. It demonstrates **good separation of concerns** at the repository/service layer but has emerging friction points around:

1. **Service layer fragmentation**: Domain logic scattered across AttendanceService and PayrollService without clear ownership
2. **Testability extraction without locality**: Multiple helper classes (PayrollResult, AttendanceDayView, EmployeeMonthHistory) exist solely for test/interface clarity, leaking across module boundaries
3. **Shallow modules in critical paths**: MonthLock is underspecified; its enforcement logic lives in services, not in a dedicated module
4. **Cross-service knowledge**: Services know too much about each other's models and constraints
5. **Test coverage gaps**: Repository tests are integration tests (hit DB), not unit tests; service tests couple to DB

---

## 1. Overall Architecture Structure

### Layering Model

```
Presentation Layer (Screens)
    ↓ (depends on)
Service Layer (AttendanceService, PayrollService, BackupService, GoogleDriveService)
    ↓ (depends on)
Repository Layer (EmployeeRepository, AttendanceRepository, MonthlyRateRepository, MonthLockRepository)
    ↓ (depends on)
Data Layer (DatabaseHelper, SQLite)

Models (shared across layers)
Utils (shared across layers)
```

### Dependency Injection

**File**: [lib/di/service_locator.dart](lib/di/service_locator.dart)

- Uses `GetIt` singleton pattern for dependency injection
- All dependencies registered at app startup via `setupServiceLocator()`
- Repositories registered as singletons
- Services registered as singletons with explicit constructor dependencies
- **Strength**: Clear dependency graph; no hidden circular dependencies
- **Weakness**: No test-friendly registration mechanism; tests must use `resetServiceLocator()` which is error-prone

### Domain Models

**Files**: 
- [lib/models/employee.dart](lib/models/employee.dart)
- [lib/models/attendance_record.dart](lib/models/attendance_record.dart)
- [lib/models/monthly_rate.dart](lib/models/monthly_rate.dart)
- [lib/models/month_lock.dart](lib/models/month_lock.dart)

Models are **well-designed**:
- Each model is a data class with `toMap()` / `fromMap()` methods for persistence
- Validation logic lives inside models (e.g., `Employee.validateName()`)
- Models have `copyWith()` for immutable updates
- Domain enums (`WorkStatus`) are cleanly defined in AttendanceRecord

**Key domain concepts**:
- **Employee**: Person whose labor is tracked
- **AttendanceRecord**: Labor entry for a date (work status + night shift flag)
- **MonthlyRate**: Salary configuration per employee per month (carry-over logic)
- **MonthLock**: Month-level data freeze (prevents edits after lock)

---

## 2. Domain Separation & Modeling

### Concept Ownership

| Concept | Owned By | Issues |
|---------|----------|--------|
| **Employee lifecycle** | EmployeeRepository + EmployeeScreen | Owned cleanly; soft/hard delete distinction |
| **Attendance state** | AttendanceService + AttendanceRepository | Dual responsibility for business logic (service) vs. persistence (repo) |
| **Payroll calculation** | PayrollService + repositories (read-only) | Logic split between service (calculation) and repository (rate lookups) |
| **Month lock enforcement** | MonthLockRepository (storage) + Services (enforcement) | **PROBLEM**: Services must check lock before modifying; lock intent is implicit |

### Attendance Workflow Fragmentation

**AttendanceRecord** represents labor on a single date:
- `workStatus` (none, fullDay, halfDay)
- `hasNightShift` (boolean flag)

**But**: No business rule prevents invalid combinations. Example:
- Can you have both `fullDay` + `halfDay` on the same date? → No (implied by Enum, but not enforced at model level)
- Can `workStatus = none` + `hasNightShift = true`? → Yes (allowed, but semantically odd)

**Impact**: Services must validate state (see [AttendanceService.recordAttendance](lib/services/attendance_service.dart#L26)); models should encode these constraints.

### PayrollResult: A Shallow View-Transfer Object

**File**: [lib/services/payroll_service.dart](lib/services/payroll_service.dart#L245)

```dart
class PayrollResult {
  final String employeeId;
  final String month;
  final double dailyRate;
  final double nightBonus;
  // ... 7 more fields ...
  final double total;
}
```

**Problems**:
1. **Created only for interface clarity**: Exists so `calculatePayroll()` can return a structured result
2. **Low cohesion**: Mixes input (rates) with output (calculated totals)
3. **Leaks across seams**: Screens import and display individual fields instead of letting service present pre-formatted results
4. **Calculation logic split**: Service computes totals; PayrollResult only holds them
5. **Hard to test through interface**: Tests must construct PayrollResult objects to verify calculations, but can't mock the calculation itself

**Friction**: Screen needs:
```dart
_payrollResults[id] = PayrollResult(...);
// Then later renders:
CurrencyFormatters.formatCurrency(result.fullDayTotal)
```

Instead of asking for `screen-ready` data, screen receives raw numbers and formats them.

---

## 3. Dependencies & Coupling

### Service-to-Repository Coupling

**AttendanceService**:
```dart
class AttendanceService {
  final AttendanceRepository _attendanceRepository;
  final EmployeeRepository _employeeRepository;
  final MonthLockRepository _monthLockRepository;
  
  // Knows it needs to:
  // - Validate employee exists
  // - Check if month is locked
  // - Fetch/update attendance in batches
}
```

**Impact**: Service is tightly bound to three repository interfaces. Changes to any repository's interface cascade to service tests and screen-level mocking.

### PayrollService's Implicit Rate Carry-Over

**File**: [lib/services/payroll_service.dart](lib/services/payroll_service.dart#L18)

```dart
if (rate == null) {
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
  }
}
```

**Friction**: This is **domain knowledge embedded in a service**. But:
1. Screen calls `ensureRatesForMonth()` before rendering to trigger this logic
2. Screen must know this service detail
3. No dedicated "Rate Policy" or "RateCarryOverService" module
4. Multiple callers (screen, service itself) know about this implementation detail
5. **Tight coupling**: If carry-over logic changes, multiple places must be updated

### BackupService: Everything-Knows-Everything

**File**: [lib/services/backup_service.dart](lib/services/backup_service.dart#L14)

```dart
class BackupService {
  final EmployeeRepository _employeeRepository;
  final AttendanceRepository _attendanceRepository;
  final MonthlyRateRepository _monthlyRateRepository;
  final MonthLockRepository _monthLockRepository;
  final GoogleDriveService _googleDriveService;
  final Battery? _battery;
```

**Problem**: BackupService depends on all repositories + external service. It's a "God Service":
- Responsible for export/import orchestration
- Knows how to serialize all models
- Knows battery constraints
- Knows Google Drive API specifics

**Impact**: Hard to test; test needs to mock 5 complex dependencies. Tests must use real database (no good mock repositories available in codebase).

### Screens Know Service Details

**[AttendanceScreen](lib/screens/attendance_screen.dart)**:
```dart
final dayView = await _attendanceService.getAttendanceDayView(
  employeeIds,
  _selectedDate,
);
setState(() {
  _attendanceMap = dayView.attendanceMap;
  _isMonthLocked = dayView.isMonthLocked;
});
```

**[PayrollScreen](lib/screens/payroll_screen.dart)**:
```dart
await _payrollService.ensureRatesForMonth(employeeIds, monthString);
final view = await _payrollService.getPayrollMonthView(
  employeeIds,
  monthString,
);
setState(() {
  _rates = view.rates;
  _payrollResults = view.results;
  _isLocked = view.isLocked;
});
```

**Friction**:
1. Screens must know the service API well enough to call in the right order
2. Screens must import view transfer objects (AttendanceDayView, PayrollMonthView)
3. Any service refactoring breaks screens directly

---

## 4. Testing Coverage & Test Interfaces

### Test Architecture

**Files**:
- [test/widget_test.dart](test/widget_test.dart) — Smoke test (minimal)
- [test/models/](test/models/) — Model unit tests
- [test/repositories/](test/repositories/) — Repository integration tests (hit DB)
- [test/services/](test/services/) — Service integration tests (hit DB)
- [test/widgets/](test/widgets/) — Screen tests (minimal)

### Repository Tests: Integration, Not Unit

**[test/repositories/attendance_repository_test.dart](test/repositories/attendance_repository_test.dart)**:

```dart
setUpAll(() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  await setupServiceLocator();
  databaseHelper = getIt<DatabaseHelper>();
  attendanceRepository = getIt<AttendanceRepository>();
  await databaseHelper.database;  // Initialize DB
});

test('should create attendance record', () async {
  final employee = await employeeRepository.create(...);  // Real DB write
  final created = await attendanceRepository.create(record);
  expect(created.id, isNotEmpty);
});
```

**Problems**:
1. Tests are **integration tests masquerading as unit tests**
2. They hit the real SQLite database (via FFI)
3. No mock repositories exist for service testing
4. Slow (DB init, I/O)
5. Can't test error conditions that require mocking (e.g., DB connection failure)

### Service Tests: Coupled to Database

**[test/services/attendance_service_test.dart](test/services/attendance_service_test.dart)**:

```dart
test('should record attendance', () async {
  final employee = await employeeRepository.create(Employee(...));  // Real DB
  final record = await attendanceService.recordAttendance(...);     // Real DB
  expect(record.employeeId, employee.id);
});
```

**Problems**:
1. No way to test service logic in isolation
2. Mutation in one test affects others (requires `setUp()` to clear DB)
3. Can't test exception handling from repositories (no mocks)
4. Tests are slow because of DB operations
5. Hard to add permission-based tests (e.g., "What if employee doesn't exist?") because you must construct valid DB state

### View Transfer Objects Extracted for Tests

**AttendanceDayView** and **PayrollMonthView** exist primarily because:
1. Services return structured results to screens
2. Tests want to verify the structure
3. No alternative exists (can't use custom matchers in Dart)

This is **test-driven extraction without clear business value**: screens don't need the object; they just unpack it immediately.

---

## 5. Shallow Modules

### MonthLock: All Concept, No Implementation

**[lib/models/month_lock.dart](lib/models/month_lock.dart)**:

```dart
class MonthLock {
  final String month; // YYYY-MM
  final bool isLocked;
  final DateTime updatedAt;
}
```

**[lib/repositories/month_lock_repository.dart](lib/repositories/month_lock_repository.dart)**:

```dart
abstract class MonthLockRepository {
  Future<MonthLock?> getLock(String month);
  Future<List<MonthLock>> getAll();
  Future<bool> isLocked(String month);
  Future<void> setLock(String month, bool isLocked);
}
```

**The Problem**:
- Repository interface has **4 methods** for a **data class with 3 fields**
- **No business logic**: Repository just stores/retrieves the boolean
- **No enforcement**: Services must check `isLocked()` before every mutation
- **Scattered validation**: Lock enforcement logic lives in:
  - AttendanceService (line ~checks before recordAttendance)
  - PayrollService (implicit assumption that payroll screen won't call if locked)
  - PayrollScreen (shows confirmation dialog before locking)

**Example friction**: To understand "what prevents me from editing a locked month," you must trace across three files.

### Shallow Methods in Services

**PayrollService.ensureRatesForMonth()** [lib/services/payroll_service.dart](lib/services/payroll_service.dart#L85):

```dart
Future<void> ensureRatesForMonth(
  List<String> employeeIds,
  String month,
) async {
  final existingRates = await _monthlyRateRepository.getByMonth(month);
  final existingIds = existingRates.map((r) => r.employeeId).toSet();

  for (final id in employeeIds) {
    if (!existingIds.contains(id)) {
      final latestRate = await _monthlyRateRepository.getLatestRate(id);
      if (latestRate != null) {
        // ... create new rate using carry-over logic
      }
    }
  }
}
```

**Problem**:
- Method does exactly what its name says (ensures rates exist)
- But the real business intent is **"prepare payroll view with carry-over logic"**
- This is a helper extracted because PayrollScreen needed it
- Interface complexity = Implementation complexity (1:1 ratio)
- Multiple callers know they must call this before calling getPayrollMonthView()

---

## 6. Tight Coupling Across Seams

### Service-to-Service Knowledge

**AttendanceService** checks `MonthLockRepository` in `recordAttendance()`:
```dart
// NO EXPLICIT CHECK, but service ALLOWS changes to locked months
// Instead, the check happens in SERVICE-level validation (future work)
```

**PayrollScreen** checks `MonthLockRepository` directly:
```dart
final confirmed = await showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Dữ liệu đã chốt'),
    content: const Text('Tháng này đã được chốt...'),
  ),
);
```

**Friction**: Lock enforcement is split between screen UI and (potentially) service business logic. There's no single "LockValidator" service.

### Rate Carry-Over Knowledge Spread

1. **PayrollService** implements carry-over in `calculatePayroll()`
2. **PayrollScreen** calls `ensureRatesForMonth()` to prepare state
3. **Payroll tests** expect carry-over to happen automatically

**Multiple callers know this detail**; no encapsulation.

### Batch-Loading Anti-Pattern

Both services provide batch-load methods:

- **AttendanceService.getAttendanceDayView()** — Batch load for a single date
- **PayrollService.getPayrollMonthView()** — Batch load for a month

**Why**: To avoid N+1 queries in screens. **But**: This couples service interface to screen's optimization needs. Screens know:
1. They should call the batch method, not individual ones
2. The batch method returns a view object
3. They must unpack the view object fields

This is **leaky abstraction**: Screens shouldn't know about DB query optimization; services should handle it internally.

---

## 7. Code Extracted Primarily for Testability

### View Transfer Objects

1. **AttendanceDayView** [lib/services/attendance_service.dart](lib/services/attendance_service.dart#L7):
   ```dart
   class AttendanceDayView {
     final Map<String, AttendanceRecord?> attendanceMap;
     final bool isMonthLocked;
   }
   ```
   - Created so `getAttendanceDayView()` can return (attendance + lock state) in one call
   - Screens unpack it immediately: `_attendanceMap = dayView.attendanceMap`
   - Tests verify its structure

2. **PayrollMonthView** [lib/services/payroll_service.dart](lib/services/payroll_service.dart#L217):
   ```dart
   return PayrollMonthView(
     isLocked: isLocked,
     rates: rateMap,
     results: payrollResults,
   );
   ```
   - Same pattern: batches three related queries into one return object

3. **EmployeeMonthHistory** [lib/services/attendance_service.dart](lib/services/attendance_service.dart#L250):
   ```dart
   class EmployeeMonthHistory {
     final List<AttendanceRecord> records;
     final Map<String, int> counts;
   }
   ```
   - Returned by `getEmployeeMonthHistory()`
   - Screens use both fields, but coupling is still tight

**Why This Is a Friction Point**:
- These objects exist **only to avoid N+1 queries**
- Screens immediately unpack them
- Tests verify fields individually
- No business domain mapping (not like DTOs in real domain-driven design)
- They're **boilerplate** extracted for optimization and test convenience

---

## 8. Hard-to-Test Interfaces

### Service Constructor Dependencies Hard to Mock

**PayrollService**:
```dart
PayrollService(
  this._attendanceRepository,
  this._monthlyRateRepository,
  this._monthLockRepository,
);
```

**Testing this**:
- No mock repositories provided in codebase
- Tests must use real service locator and real database
- Can't easily test "What if attendance repository throws an error?"

**Why**: All repository interfaces are abstract, but tests use real implementations because mocking them would require:
1. Creating mock classes for each repository
2. Handling Future returns and state
3. Coordinating mock state across multiple tests

### Batch Methods Hard to Test

**getAttendanceDayView()** combines two queries:
```dart
final results = await Future.wait([
  _attendanceRepository.getByEmployeesAndDateRange(...),
  _monthLockRepository.isLocked(month),
]);
```

**To test correctly**, you must:
1. Set up attendance records in the DB
2. Set up month lock state in the DB
3. Call the method
4. Verify both fields of the result

You can't easily test the **parallel fetch logic** without a database.

### Carry-Over Logic Hard to Test in Isolation

**PayrollService.calculatePayroll()** auto-creates rates if missing. To test:
1. Create employee
2. DON'T create rate
3. Call calculatePayroll()
4. Expect rate to be created and used

This **works** but couples the test to persistence layer.

---

## 9. Module Friction Heat Map

| Module | Friction Level | Root Cause |
|--------|---|---|
| **Models** | 🟢 Low | Well-designed data classes; validation co-located |
| **Repositories** | 🟡 Medium | No mock implementations; tests hit DB |
| **AttendanceService** | 🟡 Medium | Knows about MonthLock; validates employee existence |
| **PayrollService** | 🔴 High | Carry-over logic scattered; batch loading optimization leaks to screens |
| **BackupService** | 🔴 High | Depends on all repositories + external service; no mocks available |
| **Screens** | 🟡 Medium | Know service batch-load details; import view objects; call methods in specific order |
| **MonthLock** | 🔴 High | Enforcement split across services and screens; no unified validation |

---

## 10. Architectural Improvements Roadmap

### Quick Wins (Low Risk)

1. **Create Mock Repositories for Testing**
   - Add `MockAttendanceRepository extends AttendanceRepository`
   - Allows service tests to avoid database
   - Tests become faster and more focused

2. **Consolidate Month Lock Logic**
   - Create `LockValidator` service
   - Services should call `LockValidator.canEditMonth()` before mutations
   - Screens show confirmation; service enforces lock

3. **Extract Carry-Over Policy**
   - Create `RateCarryOverPolicy` or `RateService`
   - `PayrollService` should call `policy.ensureRate(employeeId, month)`
   - Encapsulates when/how rates are created

### Medium Effort (Medium Risk)

4. **Hide Batch-Loading Details Behind Service Facade**
   - Screens should ask: `service.getAttendanceForDate(employeeIds, date)` → returns ready-to-render data
   - Service decides internally whether to batch-load or not
   - Eliminates view transfer objects

5. **Add Business Rules to Models**
   - `AttendanceRecord` should forbid invalid work status combinations at construction time
   - Use private constructors + factory methods for validation

6. **Create Service Layer Tests That Don't Hit DB**
   - Write 50% of service tests with mocks
   - 50% integration tests with DB
   - Good mix of coverage

### Larger Refactoring (High Risk)

7. **Introduce Command/Query Separation**
   - `RecordAttendanceCommand` (write operation)
   - `GetPayrollQuery` (read operation)
   - Makes it explicit what mutates and what observes

8. **Extract Domain Events**
   - `MonthLockedEvent`, `AttendanceRecordedEvent`
   - Services emit events; screens subscribe
   - Decouples presentation from service details

---

## 11. Strengths to Preserve

1. ✅ **Clear layering**: Screens → Services → Repositories → DB
2. ✅ **Dependency injection**: GetIt makes dependencies explicit
3. ✅ **No circular dependencies**: Code flows one direction
4. ✅ **Model validation**: Business rules live in models
5. ✅ **Batch loading awareness**: Services recognize N+1 problem and solve it (even if imperfectly)
6. ✅ **Test coverage exists**: Models, repositories, services all have tests

---

## 12. Conclusion

EzTimesheet has a **solid foundation** but shows emerging signs of architectural debt:

### Red Flags 🚩
- View transfer objects extracted for convenience, not design
- Batch-loading optimization details leak to screens
- Carry-over logic (rate policy) spread across multiple modules
- Month lock enforcement scattered across service and screen layers
- No mock repositories; tests couple to database

### Good Patterns ✅
- Clear layering and dependency flow
- Models with co-located validation
- Service interfaces well-defined
- Repository abstraction used consistently

### Most Urgent Refactoring
1. **Create `RatePolicy` service** — Centralize carry-over logic
2. **Create `LockValidator` service** — Centralize lock enforcement
3. **Add mock repositories** — Make service tests faster and more focused
4. **Eliminate view transfer objects** — Services should return domain objects directly

The codebase is **maintainable now but will become harder to navigate** if batch-loading optimization and policy logic continue to spread across layers.

