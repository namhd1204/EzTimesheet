# EzTimesheet Architecture - Key Findings Summary

## 📊 Overall Health: **GOOD WITH EMERGING DEBT**

The codebase has a solid foundation but shows signs of architectural friction that will compound if not addressed.

---

## 🎯 Critical Friction Points (Must Address)

### 1. ❌ Rate Carry-Over Logic Scattered Across Layers
**Location**: `PayrollService.calculatePayroll()` + `PayrollScreen.initState()`
- Screen must call `ensureRatesForMonth()` before rendering
- Carry-over logic auto-creates rates if missing
- Multiple callers know this implementation detail

**Impact**: Hard to understand; knowledge spread across layers
**Fix**: Extract `RateCarryOverPolicy` service with single responsibility

---

### 2. ❌ Month Lock Enforcement Scattered Everywhere
**Locations**: 
- `PayrollService` (implicit checks)
- `PayrollScreen` (explicit confirmation dialog)
- Services should validate before mutations

**Impact**: Enforcement is inconsistent; intent is unclear
**Fix**: Create `LockValidator` service; all mutations call `canEditMonth()`

---

### 3. ❌ Batch-Loading Optimization Leaks to UI Layer
**Problem**: Screens import view transfer objects (`AttendanceDayView`, `PayrollMonthView`)
- Screens know to call `getAttendanceDayView()` instead of individual queries
- Services expose batch-loading as API detail instead of hiding it
- View objects exist only to avoid N+1 queries

**Impact**: Screens are tightly coupled to service optimization; hard to change
**Fix**: Services handle batching internally; return domain objects directly

---

### 4. ❌ No Mock Repositories → Tests Couple to Database
**Current State**: 
- All repository tests hit real SQLite database (integration tests)
- Service tests depend on working database
- No way to test error scenarios (can't mock failures)

**Impact**: Tests are slow; fragile; can't test exception handling
**Fix**: Create `MockAttendanceRepository`, etc. for unit testing

---

### 5. ❌ View Transfer Objects Extracted for Test Convenience
**Objects**: `AttendanceDayView`, `PayrollMonthView`, `EmployeeMonthHistory`

**Problem**:
- Created to return batched queries from services
- Screens immediately unpack them (no value-add)
- Tests verify fields individually (boilerplate)
- Low cohesion: mix input and output

**Impact**: Boilerplate; screens must know structure
**Fix**: Eliminate after fixing batch-loading (item #3)

---

## 📈 Friction Heat Map

| Component | Friction | Reason |
|-----------|----------|--------|
| **Models** | 🟢 LOW | Well-designed data classes with co-located validation |
| **Repositories** | 🟡 MEDIUM | No mocks available; tests hit database |
| **AttendanceService** | 🟡 MEDIUM | Knows about MonthLock; validates employee; batch-loads |
| **PayrollService** | 🔴 HIGH | Carry-over logic mixed with calculations; batch-loading leaks |
| **BackupService** | 🔴 HIGH | Depends on all 4 repositories + GoogleDriveService; no mocks |
| **Screens** | 🟡 MEDIUM | Import view objects; must call services in specific order |
| **MonthLock** | 🔴 HIGH | Enforcement split across service + screen; no unified validation |

---

## 📑 Module Separation Analysis

### What's Done Well ✅
1. **Clear layering**: Screens → Services → Repositories → DB (no cycles)
2. **Dependency injection**: GetIt makes dependencies explicit
3. **Model validation**: Business rules co-located with models
4. **Batch-loading awareness**: Services recognize N+1 and try to solve it
5. **Test coverage exists**: Models, repos, services all tested

### What Needs Work ❌
1. **Service layer fragmentation**: Domain logic scattered across services
2. **Policy logic not extracted**: Carry-over, lock validation should be services
3. **Testability without isolation**: Can't test without database
4. **N+1 optimization exposed**: Screens shouldn't know about batching
5. **Shallow modules**: MonthLock, helper methods exist but do little

---

## 🔧 Refactoring Priority

### Phase 1: Foundation (HIGH PRIORITY)
- [ ] Create `MockAttendanceRepository` + others
- [ ] Move all service tests off database
- [ ] Verify tests still pass

**Impact**: Enables better service testing; unblocks other refactorings

### Phase 2: Consolidate Policy Logic (HIGH PRIORITY)
- [ ] Extract `RateCarryOverPolicy` service
- [ ] Extract `LockValidator` service
- [ ] Update services to use them
- [ ] Update screens to call services instead of doing their own logic

**Impact**: Centralizes domain knowledge; easier to maintain and understand

### Phase 3: Hide Optimization Details (MEDIUM PRIORITY)
- [ ] Remove batch-load methods from public API
- [ ] Services handle batching internally
- [ ] Screens request simple queries; services optimize transparently
- [ ] Delete view transfer objects

**Impact**: Reduces coupling between layers; easier to change storage strategy

### Phase 4: Enhance Models (MEDIUM PRIORITY)
- [ ] Add factory methods to models for validation
- [ ] Use private constructors + factories
- [ ] Prevent invalid state at construction time

**Impact**: Safer models; less validation code in services

---

## 📊 Dependency Graph Summary

```
AttendanceScreen → AttendanceService → {AttendanceRepository, EmployeeRepository, MonthLockRepository}
PayrollScreen → PayrollService → {AttendanceRepository, MonthlyRateRepository, MonthLockRepository}
EmployeeScreen → EmployeeRepository

BackupService → ALL repositories + GoogleDriveService
```

**Red flag**: `BackupService` knows about everything. When backup fails, need to understand all 4 repositories + Google Drive + models.

---

## 🎓 Code Quality Observations

### Good Patterns
- ✅ Immutable models with `copyWith()`
- ✅ `toMap()` / `fromMap()` for persistence
- ✅ Validation methods on models
- ✅ Abstract repository interfaces
- ✅ Exception classes for error handling
- ✅ Batch query methods to avoid N+1

### Anti-Patterns
- ❌ View transfer objects with low cohesion
- ❌ Multiple callers knowing business policy details
- ❌ Lock validation scattered across layers
- ❌ Tests coupling to database
- ❌ No mock implementations

---

## 📝 Testing Architecture

### Current State
- **Model tests**: 3 (unit tests on Employee, AttendanceRecord, MonthlyRate)
- **Repository tests**: 3 (integration tests that hit SQLite)
- **Service tests**: 3 (integration tests that hit SQLite)
- **Widget tests**: ~3 (smoke tests; minimal coverage)
- **Total coverage**: ~12 test files, all integration-based

### Issues
1. Tests use real database (slow, fragile)
2. No way to test error scenarios
3. Mock objects would unlock better unit testing
4. View transfer objects exist partly because tests wanted them

### Recommendation
- Keep 20% integration tests (full flow verification)
- Move 80% to unit tests with mocks (fast feedback loop)

---

## 🚀 Next Steps

1. **Read the full analysis**: See `ARCHITECTURE_ANALYSIS.md` for detailed discussion of each point
2. **Create mock repositories**: Start with `MockAttendanceRepository` as a template
3. **Extract `RateCarryOverPolicy`**: Move carry-over logic out of PayrollService
4. **Extract `LockValidator`**: Consolidate lock enforcement
5. **Refactor service batch methods**: Hide batching from screens

---

## 🎯 Success Criteria

- [ ] All service tests can run without database
- [ ] Rate carry-over logic testable in isolation
- [ ] Lock enforcement validated before all mutations
- [ ] Screens don't import view transfer objects
- [ ] No multiple callers knowing policy details

---

## 📚 Key Files to Review

When implementing fixes, start here:
- [lib/services/payroll_service.dart](../lib/services/payroll_service.dart) — Carry-over logic (lines 18-70)
- [lib/services/attendance_service.dart](../lib/services/attendance_service.dart) — Lock checks (implicit)
- [lib/screens/payroll_screen.dart](../lib/screens/payroll_screen.dart) — Rate policy knowledge (lines 35-45)
- [lib/repositories/](../lib/repositories/) — Mock these for tests
- [test/services/](../test/services/) — Convert to unit tests with mocks

---

## 💡 Key Insight

**The codebase is at an inflection point**: It's well-structured enough to extend safely, but the leaks (view objects, batch-loading details, scattered policy) are starting to compound. The next 2-3 refactorings will determine whether this stays maintainable or becomes hard to navigate.

**Most impactful single change**: Create mock repositories. This unblocks all other improvements and gives immediate test speed improvement.
