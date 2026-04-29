## What to build
Implement the redesigned Attendance screen with persistent toggle buttons.
- Display each employee with 3 large buttons: **[Cả ngày]**, **[Nửa ngày]**, and **[Làm tối]**.
- Implement mutual exclusivity: tapping [Cả ngày] turns off [Nửa ngày] and vice versa.
- [Làm tối] is an independent toggle.
- Tapping an active button sets the state to "Off".
- Clicking the employee's name or photo navigates to their monthly Calendar View.

## Acceptance criteria
- [ ] 3 persistent buttons visible per employee row.
- [ ] High contrast colors for active states (Green, Yellow, Purple).
- [ ] Button interactions correctly update the `AttendanceRecord`.
- [ ] Navigation to Calendar View works.

## Blocked by
- .scratch/align-models/ticket.md
- .scratch/nav-refactor/ticket.md
