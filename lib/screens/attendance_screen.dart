import 'dart:io';
import 'package:flutter/material.dart';
import '../design_system/app_theme.dart';
import '../di/service_locator.dart';
import '../models/models.dart';
import '../utils/utils.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final EmployeeRepository _employeeRepository = getIt<EmployeeRepository>();
  final AttendanceRepository _attendanceRepository = getIt<AttendanceRepository>();
  final AttendanceService _attendanceService = getIt<AttendanceService>();

  DateTime _selectedDate = DateTime.now();
  List<Employee> _employees = [];
  Map<String, AttendanceRecord?> _attendanceMap = {};
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

      // Load attendance for selected date
      final attendanceMap = <String, AttendanceRecord?>{};
      for (final employee in employees) {
        final attendance = await _attendanceRepository.getByEmployeeAndDate(
          employee.id,
          _selectedDate,
        );
        attendanceMap[employee.id] = attendance;
      }

      setState(() {
        _employees = employees;
        _attendanceMap = attendanceMap;
        _isLoading = false;
      });
    } catch (e) {
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

  Future<void> _recordAttendance(
    String employeeId,
    AttendanceType type,
  ) async {
    try {
      await _attendanceService.recordAttendance(employeeId, _selectedDate, type);

      // Reload data
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã ghi nhận chấm công')),
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

  Future<void> _updateAttendance(
    String recordId,
    AttendanceType newType,
  ) async {
    try {
      await _attendanceService.updateAttendance(recordId, newType);

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

  Future<void> _deleteAttendance(String recordId) async {
    try {
      await _attendanceService.deleteAttendance(recordId);

      // Reload data
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa chấm công')),
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
        title: Text(DateFormatters.formatDate(_selectedDate)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _showDatePicker,
            tooltip: 'Chọn ngày',
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
            Icon(
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
                          child: Image.file(
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

            // Attendance status or buttons
            if (attendance != null)
              _buildAttendanceStatus(attendance)
            else
              _buildAttendanceButtons(employee),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceStatus(AttendanceRecord attendance) {
    return Container(
      padding: AppTheme.paddingSmall,
      decoration: BoxDecoration(
        color: _getAttendanceTypeColor(attendance.attendanceType).withOpacity(0.1),
        borderRadius: AppTheme.borderRadiusSmall,
        border: Border.all(
          color: _getAttendanceTypeColor(attendance.attendanceType),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                _getAttendanceTypeIcon(attendance.attendanceType),
                color: _getAttendanceTypeColor(attendance.attendanceType),
                size: 20,
              ),
              const SizedBox(width: AppTheme.space2),
              Text(
                attendance.attendanceTypeLabel,
                style: AppTheme.bodyMedium.copyWith(
                  color: _getAttendanceTypeColor(attendance.attendanceType),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditDialog(attendance),
                tooltip: 'Sửa',
                iconSize: 20,
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteAttendance(attendance.id),
                tooltip: 'Xóa',
                color: AppTheme.error,
                iconSize: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceButtons(Employee employee) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildAttendanceButton(
                label: 'Cả ngày',
                icon: Icons.check_circle,
                color: Colors.green,
                onPressed: () => _recordAttendance(employee.id, AttendanceType.fullDay),
              ),
            ),
            const SizedBox(width: AppTheme.space2),
            Expanded(
              child: _buildAttendanceButton(
                label: 'Nửa ngày',
                icon: Icons.adjust,
                color: Colors.orange,
                onPressed: () => _recordAttendance(employee.id, AttendanceType.halfDay),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space2),
        _buildAttendanceButton(
          label: 'Có làm tối',
          icon: Icons.nights_stay,
          color: Colors.purple,
          onPressed: () => _recordAttendance(employee.id, AttendanceType.nightWork),
        ),
      ],
    );
  }

  Widget _buildAttendanceButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Color _getAttendanceTypeColor(AttendanceType type) {
    switch (type) {
      case AttendanceType.fullDay:
        return Colors.green;
      case AttendanceType.halfDay:
        return Colors.orange;
      case AttendanceType.nightWork:
        return Colors.purple;
    }
  }

  IconData _getAttendanceTypeIcon(AttendanceType type) {
    switch (type) {
      case AttendanceType.fullDay:
        return Icons.check_circle;
      case AttendanceType.halfDay:
        return Icons.adjust;
      case AttendanceType.nightWork:
        return Icons.nights_stay;
    }
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

  Future<void> _showEditDialog(AttendanceRecord attendance) async {
    final result = await showDialog<AttendanceType>(
      context: context,
      builder: (context) => EditAttendanceDialog(currentType: attendance.attendanceType),
    );

    if (result != null) {
      await _updateAttendance(attendance.id, result);
    }
  }
}

class EditAttendanceDialog extends StatelessWidget {
  final AttendanceType currentType;

  const EditAttendanceDialog({super.key, required this.currentType});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sửa chấm công'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAttendanceTypeOption(
            context,
            AttendanceType.fullDay,
            'Cả ngày',
            Icons.check_circle,
            Colors.green,
          ),
          const SizedBox(height: AppTheme.space2),
          _buildAttendanceTypeOption(
            context,
            AttendanceType.halfDay,
            'Nửa ngày',
            Icons.adjust,
            Colors.orange,
          ),
          const SizedBox(height: AppTheme.space2),
          _buildAttendanceTypeOption(
            context,
            AttendanceType.nightWork,
            'Có làm tối',
            Icons.nights_stay,
            Colors.purple,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
      ],
    );
  }

  Widget _buildAttendanceTypeOption(
    BuildContext context,
    AttendanceType type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = type == currentType;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: color)
          : null,
      selected: isSelected,
      onTap: () => Navigator.pop(context, type),
    );
  }
}
