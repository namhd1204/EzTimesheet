import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../design_system/app_theme.dart';
import '../di/service_locator.dart';
import '../models/models.dart';
import '../utils/utils.dart';
import '../repositories/repositories.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final EmployeeRepository _employeeRepository = getIt<EmployeeRepository>();
  final AttendanceRepository _attendanceRepository =
      getIt<AttendanceRepository>();

  DateTime _currentMonth = DateTime.now();
  List<Employee> _employees = [];
  Map<String, List<AttendanceRecord>> _attendanceData = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load employees
      final employees = await _employeeRepository.getAllActive();
      final employeeIds = employees.map((e) => e.id).toList();

      // Load attendance data for current month
      final startDate = DateFormatters.firstDayOfMonth(_currentMonth);
      final endDate = DateFormatters.lastDayOfMonth(_currentMonth);

      final attendanceData =
          await _attendanceRepository.getByEmployeesAndDateRange(
        employeeIds,
        startDate,
        endDate,
      );

      setState(() {
        _employees = employees;
        _attendanceData = attendanceData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ErrorMessages.generalError;
        _isLoading = false;
      });
    }
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _loadData();
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _loadData();
  }

  void _goToToday() {
    setState(() {
      _currentMonth = DateTime.now();
    });
    _loadData();
  }

  Future<void> _showDayDetails(DateTime date) async {
    final dateString = DateFormatters.formatDateForStorage(date);
    final dayAttendance = _attendanceData[dateString] ?? [];

    if (dayAttendance.isEmpty) {
      // Show empty state dialog
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(DateFormatters.formatDate(date)),
            content: const Text('Chưa có bản ghi chấm công cho ngày này'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context, date); // close calendar and pass date
                },
                child: const Text('Chấm công ngay'),
              ),
            ],
          ),
        );
      }
    } else {
      // Show attendance details
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => DayAttendanceDialog(
            date: date,
            attendanceRecords: dayAttendance,
            employees: _employees,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormatters.formatMonth(_currentMonth)),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
            tooltip: 'Hôm nay',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: AppTheme.space4),
            Text(
              _errorMessage!,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.space4),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_employees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: AppTheme.textTertiary,
            ),
            const SizedBox(height: AppTheme.space4),
            Text(
              'Chưa có nhân viên nào',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Month navigation
        _buildMonthNavigation(),
        const Divider(),

        // Calendar grid
        Expanded(
          child: _buildCalendarGrid(),
        ),
      ],
    );
  }

  Widget _buildMonthNavigation() {
    return Padding(
      padding: AppTheme.paddingMedium,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
            tooltip: 'Tháng trước',
          ),
          Text(
            DateFormatters.getMonthName(_currentMonth.month),
            style: AppTheme.headlineMedium,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
            tooltip: 'Tháng sau',
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateFormatters.daysInMonth(_currentMonth);
    final firstDayOfMonth = DateFormatters.firstDayOfMonth(_currentMonth);
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    return GridView.builder(
      padding: AppTheme.paddingMedium,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0,
        crossAxisSpacing: AppTheme.space2,
        mainAxisSpacing: AppTheme.space2,
      ),
      itemCount: daysInMonth + startingWeekday,
      itemBuilder: (context, index) {
        if (index < startingWeekday) {
          // Empty cells before first day
          return const SizedBox.shrink();
        }

        final day = index - startingWeekday + 1;
        final date = DateTime(_currentMonth.year, _currentMonth.month, day);
        final dateString = DateFormatters.formatDateForStorage(date);
        final dayAttendance = _attendanceData[dateString] ?? [];

        return _buildDayCell(day, date, dayAttendance);
      },
    );
  }

  Widget _buildDayCell(
      int day, DateTime date, List<AttendanceRecord> attendance) {
    final isToday = DateFormatters.isToday(date);

    return GestureDetector(
      onTap: () => _showDayDetails(date),
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? AppTheme.primaryLight : AppTheme.surfaceElevated,
          borderRadius: AppTheme.borderRadiusMedium,
          border: Border.all(
            color: isToday ? AppTheme.primary : AppTheme.border,
            width: isToday ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Day number
            Center(
              child: Text(
                '$day',
                style: AppTheme.bodyLarge.copyWith(
                  color: isToday ? AppTheme.primary : AppTheme.textPrimary,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),

            // Attendance indicators
            if (attendance.isNotEmpty)
              Positioned(
                bottom: 2,
                right: 2,
                child: _buildAttendanceIndicator(attendance.length),
              ),

            // Weekday label
            Positioned(
              top: 2,
              left: 4,
              child: Text(
                DateFormatters.getShortWeekdayName(date),
                style: AppTheme.labelSmall.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceIndicator(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.secondary,
        borderRadius: AppTheme.borderRadiusSmall,
      ),
      child: Text(
        '$count',
        style: AppTheme.labelSmall.copyWith(
          color: AppTheme.textInverse,
          fontSize: 10,
        ),
      ),
    );
  }
}

class DayAttendanceDialog extends StatelessWidget {
  final DateTime date;
  final List<AttendanceRecord> attendanceRecords;
  final List<Employee> employees;

  const DayAttendanceDialog({
    super.key,
    required this.date,
    required this.attendanceRecords,
    required this.employees,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(DateFormatters.formatDate(date)),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: attendanceRecords.length,
          itemBuilder: (context, index) {
            final record = attendanceRecords[index];
            final employee = employees.firstWhere(
              (e) => e.id == record.employeeId,
              orElse: () => Employee(
                name: 'Unknown',
                phone: '',
              ),
            );

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primary,
                child: employee.photoPath != null
                    ? ClipOval(
                        child: kIsWeb
                            ? Image.network(
                                employee.photoPath!,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(employee.photoPath!),
                                fit: BoxFit.cover,
                              ),
                      )
                    : Text(
                        employee.name[0].toUpperCase(),
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.textInverse,
                        ),
                      ),
              ),
              title: Text(employee.name),
              subtitle: Text(record.workStatusLabel +
                  (record.hasNightShift ? ' + Làm tối' : '')),
              trailing: _buildWorkStatusIcon(record.workStatus),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // close dialog
            Navigator.pop(context, date); // close calendar and pass date
          },
          child: const Text('Chỉnh sửa'),
        ),
      ],
    );
  }

  Widget _buildWorkStatusIcon(WorkStatus type) {
    IconData icon;
    Color color;

    switch (type) {
      case WorkStatus.fullDay:
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case WorkStatus.halfDay:
        icon = Icons.adjust;
        color = Colors.orange;
        break;
      case WorkStatus.none:
        icon = Icons.circle_outlined;
        color = Colors.grey;
        break;
    }

    return Icon(icon, color: color);
  }
}
