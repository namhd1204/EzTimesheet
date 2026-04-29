## What to build
Update `AttendanceRecord` and `MonthlyRate` models to match the domain context specified in `CONTEXT.md`.
- `AttendanceRecord`: Change `AttendanceType` enum to support independent state (Full/Half/Off) and a `NightShift` toggle (co-existence).
- `MonthlyRate`: Change `nightRateMultiplier` to `nightBonus` (a fixed monetary amount).
- Ensure database helpers and tests are updated to reflect these schema changes.

## Acceptance criteria
- [ ] `AttendanceRecord` can store `FullDay` + `NightShift` simultaneously.
- [ ] `MonthlyRate` uses a fixed value for night work instead of a multiplier.
- [ ] Database migrations/helpers updated for new fields.
- [ ] Model unit tests passing.

## Blocked by
None - can start immediately.
