# Context: EzTimesheet

A simple timesheet and payroll management application designed for users over 40 (non-tech savvy), prioritizing high visibility and one-touch interactions.

## Glossary

### Employee (Nhân viên)
A person performing labor whose attendance and wages are tracked. Profile includes Name, Phone, and Photo (primarily captured via camera, gallery selection allowed as fallback).

### Timesheet Entry (Chấm công)
A record of labor for an **Employee** on a specific date. Interaction is performed via a **Quick Menu** (Bảng chọn nhanh) - a large overlay appearing upon tapping a date.
- **Full Day (Cả ngày)**: Standard daily labor unit.
- **Half Day (Nửa ngày)**: Half of a standard daily labor unit.
- **Night Shift (Làm tối)**: An additional labor unit that can coexist with Full or Half day.

### Salary Rate (Giá tiền công)
The monetary value assigned to a labor unit.
- **Daily Rate (Giá ngày)**: Defined per **Employee** and can vary month-to-month. By default, it carries over from the previous month.
- **Night Bonus (Tiền làm tối)**: A fixed monetary amount added for a **Night Shift**, regardless of the Daily Rate.

### Locked Month (Khóa dữ liệu)
A state for a specific month's data where no further edits to **Timesheet Entries** or **Salary Rates** are permitted.
- **Constraint**: To change data in a locked month, the user must explicitly perform an "Unlock" action via a **Confirmation Dialog** (Hộp thoại xác nhận) to prevent accidental edits.

### Labor States
- **Off (Nghỉ)**: The default state. No work recorded.
- **Full Day (Cả ngày)**: Standard daily labor. Mutually exclusive with **Half Day**.
- **Half Day (Nửa ngày)**: Half-day labor. Mutually exclusive with **Full Day**.
- **Night Shift (Làm tối)**: A supplemental labor unit. Can be toggled on/off independently of Full/Half day status.

## Navigation Model (Mô hình điều hướng)
To minimize complexity for elderly users, the app uses a 3-tab structure:
1. **Attendance (Chấm công)**: The primary screen showing all employees for a selected date. Each employee row has three large, persistent toggle buttons: **[Full Day]**, **[Half Day]**, and **[Night Shift]**.
   - Tapping an active button deactivates it (setting the state to **Off**).
   - Tapping an employee's name/photo opens their monthly **Calendar View**.
2. **Employees (Nhân viên)**: Management of employee profiles.
3. **Payroll & Reports (Lương & Báo cáo)**: Monthly summaries, salary rate configuration, and the **Lock Month** feature.
- **Settings**: Accessible via a secondary icon (e.g., top corner), not a primary tab.
