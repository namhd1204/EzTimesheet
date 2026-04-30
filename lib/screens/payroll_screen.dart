import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/app_theme.dart';
import '../di/service_locator.dart';
import '../models/models.dart';
import '../utils/utils.dart';
import '../services/services.dart';
import '../repositories/repositories.dart';
import 'settings_screen.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  final EmployeeRepository _employeeRepository = getIt<EmployeeRepository>();
  final MonthlyRateRepository _monthlyRateRepository =
      getIt<MonthlyRateRepository>();
  final PayrollService _payrollService = getIt<PayrollService>();
  final MonthLockRepository _monthLockRepository = getIt<MonthLockRepository>();

  DateTime _currentMonth = DateTime.now();
  List<Employee> _employees = [];
  Map<String, MonthlyRate?> _rates = {};
  Map<String, PayrollResult?> _payrollResults = {};
  bool _isLoading = true;
  bool _isLocked = false;
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
      _payrollResults = {}; // Clear old results
    });

    try {
      final employees = await _employeeRepository.getAllActive();
      final monthString = DateFormatters.formatMonthForStorage(_currentMonth);
      final employeeIds = employees.map((e) => e.id).toList();

      // Ensure rates exist for carry-over logic
      await _payrollService.ensureRatesForMonth(employeeIds, monthString);
      
      // Batch fetch locked state, rates, and calculate results
      final view = await _payrollService.getPayrollMonthView(
        employeeIds,
        monthString,
      );

      setState(() {
        _employees = employees;
        _rates = view.rates;
        _payrollResults = view.results;
        _isLocked = view.isLocked;
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


  Future<void> _configureRate(Employee employee) async {
    if (_isLocked) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Dữ liệu đã chốt'),
          content: const Text(
              'Tháng này đã được chốt. Bạn có chắc muốn thay đổi cấu hình lương không?'),
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
      if (confirmed != true) return;
    }

    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RateConfigurationDialog(
        employee: employee,
        month: _currentMonth,
        existingRate: _rates[employee.id],
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _toggleLock() async {
    final monthString = DateFormatters.formatMonthForStorage(_currentMonth);
    final monthDisplay = DateFormatters.formatMonth(_currentMonth);

    if (!_isLocked) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Chốt dữ liệu $monthDisplay'),
          content: Text(
              'Sau khi chốt, dữ liệu chấm công và lương của tháng $monthDisplay sẽ được bảo vệ. Bạn có chắc chắn?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Chốt dữ liệu',
                  style: TextStyle(color: AppTheme.primary)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _monthLockRepository.setLock(monthString, true);
        _loadData();
      }
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Mở khóa dữ liệu $monthDisplay'),
          content: const Text(
              'Bạn đang mở khóa dữ liệu đã chốt. Bạn có chắc chắn muốn cho phép sửa đổi dữ liệu tháng này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Mở khóa',
                  style: TextStyle(color: AppTheme.error)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _monthLockRepository.setLock(monthString, false);
        _loadData();
      }
    }
  }

  Future<void> _exportPayroll() async {
    try {
      final monthString = DateFormatters.formatMonthForStorage(_currentMonth);
      final employeeIds = _employees.map((e) => e.id).toList();

      final payrollText = await _payrollService.exportPayroll(
        employeeIds,
        monthString,
      );

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: payrollText));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã sao chép bảng lương vào clipboard'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(ErrorMessages.generalError)),
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
            icon: Icon(_isLocked ? Icons.lock : Icons.lock_open),
            onPressed: _toggleLock,
            tooltip: _isLocked ? 'Mở khóa tháng' : 'Chốt tháng',
            color: _isLocked ? AppTheme.primary : null,
          ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: _goToToday,
            tooltip: 'Hôm nay',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportPayroll,
            tooltip: 'Xuất bảng lương',
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
          ],
        ),
      );
    }

    return Column(
      children: [
        // Month navigation
        _buildMonthNavigation(),
        const Divider(),

        // Payroll summary
        if (_payrollResults.isNotEmpty) _buildPayrollSummary(),

        // Employee list
        Expanded(
          child: _buildEmployeeList(),
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

  Widget _buildPayrollSummary() {
    final total = _payrollResults.values.fold<double>(
      0,
      (sum, result) => sum + (result?.total ?? 0),
    );

    return Container(
      padding: AppTheme.paddingMedium,
      color: AppTheme.primary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Tổng lương:',
            style: AppTheme.bodyLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            CurrencyFormatters.formatVND(total),
            style: AppTheme.headlineMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList() {
    return ListView.builder(
      padding: AppTheme.paddingMedium,
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        final employee = _employees[index];
        final rate = _rates[employee.id];
        final payrollResult = _payrollResults[employee.id];

        return _buildEmployeeCard(employee, rate, payrollResult);
      },
    );
  }

  Widget _buildEmployeeCard(
    Employee employee,
    MonthlyRate? rate,
    PayrollResult? payrollResult,
  ) {
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

            // Rate configuration or payroll result
            if (rate == null)
              _buildConfigureRateButton(employee)
            else if (payrollResult != null)
              _buildPayrollResult(payrollResult)
            else
              _buildRateInfo(rate),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigureRateButton(Employee employee) {
    return OutlinedButton.icon(
      onPressed: () => _configureRate(employee),
      icon: const Icon(Icons.settings),
      label: const Text('Tiền công 1 ngày'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
    );
  }

  Widget _buildRateInfo(MonthlyRate rate) {
    return Container(
      padding: AppTheme.paddingSmall,
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: AppTheme.borderRadiusSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tỷ lệ ngày: ${CurrencyFormatters.formatVND(rate.dailyRate)}',
                style: AppTheme.bodyMedium,
              ),
              Text(
                'Thưởng làm tối: ${CurrencyFormatters.formatVND(rate.nightBonus)}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _configureRate(
              _employees.firstWhere((e) => e.id == rate.employeeId),
            ),
            tooltip: 'Sửa',
          ),
        ],
      ),
    );
  }

  Widget _buildPayrollResult(PayrollResult result) {
    return Container(
      padding: AppTheme.paddingSmall,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withValues(alpha: 0.15),
        borderRadius: AppTheme.borderRadiusSmall,
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng lương:',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                CurrencyFormatters.formatVND(result.total),
                style: AppTheme.headlineSmall.copyWith(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space2),
          _buildPayrollDetailRow('Ngày làm việc:', result.fullDays),
          _buildPayrollDetailRow('Nửa ngày:', result.halfDays),
          _buildPayrollDetailRow('Làm đêm:', result.nightWorkDays),
          const SizedBox(height: AppTheme.space2),
          _buildPayrollDetailRow('Tiền ngày:', result.fullDayTotal, isCurrency: true),
          _buildPayrollDetailRow('Tiền nửa ngày:', result.halfDayTotal, isCurrency: true),
          _buildPayrollDetailRow('Tiền làm đêm:', result.nightWorkTotal, isCurrency: true),
        ],
      ),
    );
  }

  Widget _buildPayrollDetailRow(String label, dynamic value, {bool isCurrency = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            isCurrency
                ? CurrencyFormatters.formatVND((value as num).toDouble())
                : '$value',
            style: AppTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class RateConfigurationDialog extends StatefulWidget {
  final Employee employee;
  final DateTime month;
  final MonthlyRate? existingRate;

  const RateConfigurationDialog({
    super.key,
    required this.employee,
    required this.month,
    this.existingRate,
  });

  @override
  State<RateConfigurationDialog> createState() =>
      _RateConfigurationDialogState();
}

class _RateConfigurationDialogState extends State<RateConfigurationDialog> {
  final MonthlyRateRepository _monthlyRateRepository =
      getIt<MonthlyRateRepository>();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _dailyRateController;
  late TextEditingController _nightBonusController;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _dailyRateController = TextEditingController(
      text: widget.existingRate?.dailyRate.toString() ?? '',
    );
    _nightBonusController = TextEditingController(
      text: widget.existingRate?.nightBonus.toString() ?? '0',
    );
  }

  Future<void> _saveRate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final dailyRate = double.tryParse(_dailyRateController.text);
      final nightBonus = double.tryParse(_nightBonusController.text);

      if (dailyRate == null || nightBonus == null) {
        setState(() {
          _errorMessage = 'Lỗi: Giá trị không hợp lệ';
          _isSaving = false;
        });
        return;
      }

      final monthString = DateFormatters.formatMonthForStorage(widget.month);

      if (widget.existingRate != null) {
        // Update existing rate
        final updated = widget.existingRate!.copyWith(
          dailyRate: dailyRate,
          nightBonus: nightBonus,
          updatedAt: DateTime.now(),
        );
        await _monthlyRateRepository.update(updated);
      } else {
        // Create new rate
        final rate = MonthlyRate(
          employeeId: widget.employee.id,
          month: monthString,
          dailyRate: dailyRate,
          nightBonus: nightBonus,
        );
        await _monthlyRateRepository.create(rate);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = ErrorMessages.generalError;
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _dailyRateController.dispose();
    _nightBonusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Tiền công 1 ngày - ${widget.employee.name}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormatters.formatMonth(widget.month),
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: AppTheme.space4),

              // Daily rate field
              TextFormField(
                controller: _dailyRateController,
                decoration: const InputDecoration(
                  labelText: 'Tỷ lệ ngày (VND)',
                  hintText: 'Nhập tỷ lệ ngày',
                  border: OutlineInputBorder(),
                  suffixText: '₫',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lỗi: Vui lòng nhập tỷ lệ ngày';
                  }
                  final rate = double.tryParse(value);
                  if (rate == null) {
                    return 'Lỗi: Giá trị không hợp lệ';
                  }
                  if (!ValidationUtils.isValidDailyRate(rate)) {
                    return 'Lỗi: Tỷ lệ phải từ 0 đến 100,000,000';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.space3),

              // Night bonus field
              TextFormField(
                controller: _nightBonusController,
                decoration: const InputDecoration(
                  labelText: 'Thưởng làm tối (VND)',
                  hintText: 'Nhập tiền thưởng làm tối',
                  border: OutlineInputBorder(),
                  suffixText: '₫',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lỗi: Vui lòng nhập tiền thưởng làm tối';
                  }
                  final bonus = double.tryParse(value);
                  if (bonus == null) {
                    return 'Lỗi: Giá trị không hợp lệ';
                  }
                  if (bonus < 0) {
                    return 'Lỗi: Tiền thưởng không được âm';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.space3),

              // Error message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppTheme.space2),
                  child: Text(
                    _errorMessage!,
                    style: AppTheme.labelSmall.copyWith(
                      color: AppTheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveRate,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}
