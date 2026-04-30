import 'package:flutter/material.dart';
import '../design_system/app_theme.dart';
import '../di/service_locator.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../utils/utils.dart';

class EmployeeHistoryScreen extends StatefulWidget {
  final Employee employee;

  const EmployeeHistoryScreen({super.key, required this.employee});

  @override
  State<EmployeeHistoryScreen> createState() => _EmployeeHistoryScreenState();
}

class _EmployeeHistoryScreenState extends State<EmployeeHistoryScreen> {
  final AttendanceRepository _attendanceRepository =
      getIt<AttendanceRepository>();

  DateTime _currentMonth = DateTime.now();
  List<AttendanceRecord> _records = [];
  Map<String, int> _counts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final startDate = DateFormatters.firstDayOfMonth(_currentMonth);
    final endDate = DateFormatters.lastDayOfMonth(_currentMonth);

    try {
      final records = await _attendanceRepository.getByEmployeeAndDateRange(
        widget.employee.id,
        startDate,
        endDate,
      );

      final counts = await _attendanceRepository.countByTypeForEmployee(
        widget.employee.id,
        startDate,
        endDate,
      );

      setState(() {
        _records = records;
        _counts = counts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lịch sử: ${widget.employee.name}'),
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          if (!_isLoading) _buildSummaryCard(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? _buildEmptyState()
                    : _buildRecordsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: AppTheme.paddingMedium,
      color: AppTheme.surfaceElevated,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            DateFormatters.formatMonth(_currentMonth),
            style: AppTheme.headlineSmall,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      margin: AppTheme.paddingMedium,
      child: Padding(
        padding: AppTheme.paddingMedium,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('Cả ngày', _counts['fullDay'] ?? 0, Colors.green),
            _buildSummaryItem(
                'Nửa ngày', _counts['halfDay'] ?? 0, Colors.orange),
            _buildSummaryItem(
                'Làm tối', _counts['nightShift'] ?? 0, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: AppTheme.headlineMedium.copyWith(color: color),
        ),
        Text(label, style: AppTheme.bodySmall),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 64, color: AppTheme.textTertiary),
          const SizedBox(height: AppTheme.space3),
          Text(
            'Không có dữ liệu trong tháng này',
            style: AppTheme.bodyLarge.copyWith(color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList() {
    // Sort records by date descending
    final sortedRecords = List<AttendanceRecord>.from(_records)
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      padding: AppTheme.paddingSmall,
      itemCount: sortedRecords.length,
      itemBuilder: (context, index) {
        final record = sortedRecords[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: _buildStatusIcon(record.workStatus),
            title: Text(
              '${DateFormatters.getWeekdayName(record.date)}, ${DateFormatters.formatDate(record.date)}',
              style: AppTheme.bodyLarge,
            ),
            trailing: record.hasNightShift
                ? const Chip(
                    label: Text('Làm tối', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.blue,
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(WorkStatus status) {
    switch (status) {
      case WorkStatus.fullDay:
        return const Icon(Icons.check_circle, color: Colors.green);
      case WorkStatus.halfDay:
        return const Icon(Icons.adjust, color: Colors.orange);
      case WorkStatus.none:
        return const Icon(Icons.circle_outlined, color: Colors.grey);
    }
  }
}
