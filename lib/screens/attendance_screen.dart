import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../design_system/app_theme.dart';
import '../di/service_locator.dart';
import '../models/models.dart';
import '../utils/utils.dart';
import '../repositories/repositories.dart';
import '../services/services.dart';
import 'settings_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final EmployeeRepository _employeeRepository = getIt<EmployeeRepository>();
  final AttendanceService _attendanceService = getIt<AttendanceService>();
  final BackupService _backupService = getIt<BackupService>();

  DateTime _selectedDate = DateTime.now();
  List<Employee> _employees = [];
  Map<String, AttendanceRecord?> _attendanceMap = {};
  bool _isMonthLocked = false;
  bool _isLoading = true;
  bool _isRestoring = false;
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
      final employees = await _employeeRepository.getAllActive();
      final employeeIds = employees.map((e) => e.id).toList();

      // Single call: batch attendance + lock check (replaces N+1 + separate lock query)
      final dayView = await _attendanceService.getAttendanceDayView(
        employeeIds,
        _selectedDate,
      );

      setState(() {
        _employees = employees;
        _attendanceMap = dayView.attendanceMap;
        _isMonthLocked = dayView.isMonthLocked;
        _isLoading = false;
      });
    } catch (e, stack) {
      debugPrint('Error loading data: $e');
      debugPrint('Stack trace: $stack');
      setState(() {
        _errorMessage = ErrorMessages.generalError;
        _isLoading = false;
      });
    }
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadData();
  }

  Future<void> _updateAttendance(
    String employeeId, {
    WorkStatus? workStatus,
    bool? hasNightShift,
  }) async {
    try {
      await _attendanceService.updateAttendanceStatus(
        employeeId,
        _selectedDate,
        workStatus: workStatus,
        hasNightShift: hasNightShift,
      );

      // Reload data
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật chấm công')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 32),
              onPressed: () => _selectDate(_selectedDate.subtract(const Duration(days: 1))),
            ),
            Text(DateFormatters.formatDate(_selectedDate)),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 32),
              onPressed: _selectedDate.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
                  ? () => _selectDate(_selectedDate.add(const Duration(days: 1)))
                  : null, // Disable if today
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showDatePicker,
            tooltip: 'Chọn ngày',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
            tooltip: 'Cài đặt',
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
            const SizedBox(height: AppTheme.space4),
            if (_isRestoring)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _restoreFromDrive,
                icon: const Icon(Icons.cloud_download),
                label: const Text('Khôi phục từ Drive'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: AppTheme.paddingMedium,
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        final employee = _employees[index];
        final attendance = _attendanceMap[employee.id];

        return _buildEmployeeCard(employee, attendance);
      },
    );
  }

  Widget _buildEmployeeCard(Employee employee, AttendanceRecord? attendance) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.space3),
      child: Padding(
        padding: AppTheme.paddingMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Employee info
            Row(
              children: [
                CircleAvatar(
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
                          style: AppTheme.headlineSmall.copyWith(
                            color: AppTheme.textInverse,
                          ),
                        ),
                ),
                const SizedBox(width: AppTheme.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.name,
                        style: AppTheme.bodyLarge,
                      ),
                      if (employee.phone.isNotEmpty)
                        Text(
                          employee.phone,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space3),

            // Persistent Toggle Buttons
            _buildPersistentButtons(employee, attendance),
          ],
        ),
      ),
    );
  }

  Widget _buildPersistentButtons(
      Employee employee, AttendanceRecord? attendance) {
    final workStatus = attendance?.workStatus ?? WorkStatus.none;
    final hasNightShift = attendance?.hasNightShift ?? false;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: _buildToggleButton(
            label: 'Cả ngày',
            icon: Icons.wb_sunny,
            isActive: workStatus == WorkStatus.fullDay,
            isDimmed: workStatus == WorkStatus.halfDay,
            activeColor: Colors.green,
            onPressed: () => _toggleWorkStatus(
                employee.id, attendance, WorkStatus.fullDay),
          ),
        ),
        const SizedBox(width: AppTheme.space2),
        Expanded(
          flex: 2,
          child: _buildToggleButton(
            label: 'Nửa ngày',
            icon: Icons.wb_twilight,
            isActive: workStatus == WorkStatus.halfDay,
            isDimmed: workStatus == WorkStatus.fullDay,
            activeColor: Colors.orange,
            onPressed: () => _toggleWorkStatus(
                employee.id, attendance, WorkStatus.halfDay),
          ),
        ),
        const SizedBox(width: AppTheme.space4),
        Expanded(
          flex: 2,
          child: _buildToggleButton(
            label: 'Làm tối',
            icon: Icons.nights_stay,
            isActive: hasNightShift,
            isDimmed: false,
            activeColor: Colors.purple,
            onPressed: () => _toggleNightShift(employee.id, attendance),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isActive,
    bool isDimmed = false,
    required Color activeColor,
    required VoidCallback onPressed,
  }) {
    final displayColor = isDimmed ? activeColor.withValues(alpha: 0.3) : activeColor;
    
    return SizedBox(
      height: 60, // Large button for elders
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(isActive ? Icons.check_circle : icon, size: 20),
        label: Text(
          label,
          style: AppTheme.bodyLarge.copyWith(
            color: isActive ? Colors.white : displayColor,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 14, // reduce size to fit 3 in row
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? displayColor : Colors.transparent,
          foregroundColor: isActive ? Colors.white : displayColor,
          elevation: isActive ? 4 : 0,
          side: BorderSide(color: displayColor, width: isDimmed ? 1 : 2),
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.borderRadiusMedium,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ).copyWith(
          overlayColor:
              WidgetStateProperty.all(displayColor.withValues(alpha: 0.1)),
        ),
      ),
    );
  }

  Future<void> _toggleWorkStatus(String employeeId,
      AttendanceRecord? attendance, WorkStatus targetStatus) async {
    if (!await _checkLock()) return;

    final currentStatus = attendance?.workStatus ?? WorkStatus.none;
    final newStatus =
        currentStatus == targetStatus ? WorkStatus.none : targetStatus;

    await _updateAttendance(
      employeeId,
      workStatus: newStatus,
      hasNightShift: attendance?.hasNightShift,
    );
  }

  Future<void> _toggleNightShift(
      String employeeId, AttendanceRecord? attendance) async {
    if (!await _checkLock()) return;

    final currentNightShift = attendance?.hasNightShift ?? false;

    await _updateAttendance(
      employeeId,
      workStatus: attendance?.workStatus,
      hasNightShift: !currentNightShift,
    );
  }

  Future<bool> _checkLock() async {
    if (_isMonthLocked) {
      if (!mounted) return false;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Dữ liệu đã chốt'),
          content: const Text(
              'Tháng này đã được chốt. Bạn có chắc muốn thay đổi chấm công không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Đồng ý', style: TextStyle(color: AppTheme.error)),
            ),
          ],
        ),
      );
      return confirmed ?? false;
    }
    return true;
  }

  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      _selectDate(picked);
    }
  }

  Future<void> _restoreFromDrive() async {
    setState(() {
      _isRestoring = true;
    });

    try {
      final summary = await _backupService.restoreFromDrive();
      if (summary != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã khôi phục thành công.')),
          );
        }
        _loadData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Không tìm thấy bản sao lưu trên Drive.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khôi phục: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }
}
