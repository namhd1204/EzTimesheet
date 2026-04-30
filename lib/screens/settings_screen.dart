import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/app_theme.dart';
import '../di/service_locator.dart';
import '../utils/utils.dart';
import '../services/services.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BackupService _backupService = getIt<BackupService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        padding: AppTheme.paddingMedium,
        children: [
          // Data backup section
          _buildSectionHeader('Sao lưu dữ liệu'),
          const SizedBox(height: AppTheme.space3),
          _buildExportButton(),
          const SizedBox(height: AppTheme.space2),
          _buildImportButton(),
          const SizedBox(height: AppTheme.space4),

          // App info section
          _buildSectionHeader('Thông tin ứng dụng'),
          const SizedBox(height: AppTheme.space3),
          _buildAppInfo(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: AppTheme.space2),
      child: Text(
        title,
        style: AppTheme.labelLarge.copyWith(
          color: AppTheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.file_upload, color: AppTheme.primary),
        title: const Text('Xuất dữ liệu'),
        subtitle: const Text('Sao lưu dữ liệu ra file JSON'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _exportData,
      ),
    );
  }

  Widget _buildImportButton() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.file_download, color: AppTheme.secondary),
        title: const Text('Nhập dữ liệu'),
        subtitle: const Text('Khôi phục dữ liệu từ file JSON'),
        trailing: const Icon(Icons.chevron_right),
        onTap: _importData,
      ),
    );
  }

  Widget _buildAppInfo() {
    return Card(
      child: Padding(
        padding: AppTheme.paddingMedium,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Tên ứng dụng', 'EzTimesheet'),
            const SizedBox(height: AppTheme.space2),
            _buildInfoRow('Phiên bản', '1.0.0'),
            const SizedBox(height: AppTheme.space2),
            _buildInfoRow('Mô tả', 'Quản lý chấm công và tính lương'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Future<void> _exportData() async {
    try {
      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Export data
      final jsonData = await _backupService.exportData();

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: jsonData));

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xuất dữ liệu thành công'),
            content: const Text(
              'Dữ liệu đã được sao chép vào clipboard. Bạn có thể dán vào file JSON để lưu trữ.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } on BackupException catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show error or warning
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(e.isWarning ? 'Cảnh báo' : 'Lỗi'),
            content: Text(e.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show error
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Lỗi'),
            content: const Text(ErrorMessages.dataExportFailed),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _importData() async {
    // Show input dialog
    if (!mounted) return;
    final jsonData = await showDialog<String>(
      context: context,
      builder: (context) => const ImportDataDialog(),
    );

    if (jsonData == null || jsonData.isEmpty) {
      return;
    }

    try {
      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Import data
      final summary = await _backupService.importData(jsonData);

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => ImportSummaryDialog(summary: summary),
        );
      }
    } on BackupException catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show error or warning
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(e.isWarning ? 'Cảnh báo' : 'Lỗi'),
            content: Text(e.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Show error
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Lỗi'),
            content: const Text(ErrorMessages.dataImportFailed),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      }
    }
  }
}

class ImportDataDialog extends StatefulWidget {
  const ImportDataDialog({super.key});

  @override
  State<ImportDataDialog> createState() => _ImportDataDialogState();
}

class _ImportDataDialogState extends State<ImportDataDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isValidating = false;
  String? _errorMessage;

  Future<void> _validateAndImport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      // Validate JSON structure
      final jsonData = _controller.text.trim();
      if (jsonData.isEmpty) {
        setState(() {
          _errorMessage = 'Lỗi: Vui lòng dán dữ liệu JSON';
          _isValidating = false;
        });
        return;
      }

      // Close dialog and return data
      if (mounted) {
        Navigator.pop(context, jsonData);
      }
    } catch (e) {
      setState(() {
        _errorMessage = ErrorMessages.dataInvalidFormat;
        _isValidating = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nhập dữ liệu'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dán dữ liệu JSON từ file sao lưu vào đây:',
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.space2),
              TextFormField(
                controller: _controller,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: 'Dán dữ liệu JSON vào đây...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lỗi: Vui lòng dán dữ liệu JSON';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.space2),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.error,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isValidating ? null : () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isValidating ? null : _validateAndImport,
          child: _isValidating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Nhập'),
        ),
      ],
    );
  }
}

class ImportSummaryDialog extends StatelessWidget {
  final BackupSummary summary;

  const ImportSummaryDialog({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nhập dữ liệu hoàn tất'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummarySection('Nhân viên', summary.employeesImported,
                summary.employeesFailed),
            _buildSummarySection('Bản ghi chấm công',
                summary.attendanceImported, summary.attendanceFailed),
            _buildSummarySection(
                'Tỷ lệ lương', summary.ratesImported, summary.ratesFailed),
            const SizedBox(height: AppTheme.space3),
            if (summary.hasFailures)
              Text(
                'Một số mục không thể nhập. Vui lòng kiểm tra dữ liệu và thử lại.',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.error,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
      ],
    );
  }

  Widget _buildSummarySection(String title, int imported, int failed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.space1),
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: AppTheme.space1),
            Text(
              'Đã nhập: $imported',
              style: AppTheme.bodySmall,
            ),
          ],
        ),
        if (failed > 0)
          Row(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 16),
              const SizedBox(width: AppTheme.space1),
              Text(
                'Thất bại: $failed',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.error,
                ),
              ),
            ],
          ),
        const SizedBox(height: AppTheme.space2),
      ],
    );
  }
}
