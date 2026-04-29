## What to build
Update the payroll calculation logic and salary rate management.
- Use `DailyRate` (per employee) and fixed `NightBonus` for calculations.
- Implement "Carry-over" logic: when starting a new month, default to the rates from the previous month.
- Display a summary of total pay per employee for the month.

## Acceptance criteria
- [ ] Total = (Days * DailyRate) + (NightShifts * NightBonus).
- [ ] New month initialization copies previous rates.
- [ ] Reports screen shows correct totals.

## Blocked by
- .scratch/align-models/ticket.md
