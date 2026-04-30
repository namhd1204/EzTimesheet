import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../design_system/app_theme.dart';
import '../di/service_locator.dart';
import '../models/models.dart';
import '../utils/utils.dart';
import '../repositories/repositories.dart';
import 'settings_screen.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  final EmployeeRepository _employeeRepository = getIt<EmployeeRepository>();
  List<Employee> _employees = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final employees = await _employeeRepository.getAllActive();
      setState(() {
        _employees = employees;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = ErrorMessages.generalError;
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddEmployeeDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddEmployeeDialog(),
    );

    if (result == true) {
      _loadEmployees();
    }
  }

  Future<void> _showEmployeeDetails(Employee employee) async {
    await showDialog(
      context: context,
      builder: (context) => EmployeeDetailsDialog(employee: employee),
    );
  }

  Future<void> _deleteEmployee(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa nhân viên "${employee.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _employeeRepository.delete(employee.id);
        _loadEmployees();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa nhân viên')),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhân viên'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEmployeeDialog,
            tooltip: 'Thêm nhân viên',
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
              onPressed: _loadEmployees,
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
            ElevatedButton.icon(
              onPressed: _showAddEmployeeDialog,
              icon: const Icon(Icons.add),
              label: const Text('Thêm nhân viên'),
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
        return Card(
          margin: const EdgeInsets.only(bottom: AppTheme.space3),
          child: ListTile(
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
                      style: AppTheme.headlineSmall.copyWith(
                        color: AppTheme.textInverse,
                      ),
                    ),
            ),
            title: Text(
              employee.name,
              style: AppTheme.bodyLarge,
            ),
            subtitle: Text(
              employee.phone.isEmpty ? 'Chưa có số điện thoại' : employee.phone,
              style: AppTheme.bodySmall,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () => _showEmployeeDetails(employee),
                  tooltip: 'Xem chi tiết',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteEmployee(employee),
                  tooltip: 'Xóa',
                  color: AppTheme.error,
                ),
              ],
            ),
            onTap: () => _showEmployeeDetails(employee),
          ),
        );
      },
    );
  }
}

class AddEmployeeDialog extends StatefulWidget {
  const AddEmployeeDialog({super.key});

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final EmployeeRepository _employeeRepository = getIt<EmployeeRepository>();
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _photoPath;
  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _photoPath = image.path;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = ErrorMessages.employeePhotoFailed;
      });
    }
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // Check for duplicate
      final existing = await _employeeRepository.getByNameAndPhone(
        _nameController.text.trim(),
        _phoneController.text.trim(),
      );

      if (existing != null) {
        setState(() {
          _errorMessage = ErrorMessages.employeeDuplicate;
          _isSaving = false;
        });
        return;
      }

      // Create employee
      final employee = Employee(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        photoPath: _photoPath,
      );

      await _employeeRepository.create(employee);

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
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm nhân viên'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Photo picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: AppTheme.borderRadiusMedium,
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: _photoPath != null
                      ? ClipOval(
                          child: kIsWeb
                              ? Image.network(
                                  _photoPath!,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_photoPath!),
                                  fit: BoxFit.cover,
                                ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.camera_alt,
                              size: 32,
                              color: AppTheme.textTertiary,
                            ),
                            const SizedBox(height: AppTheme.space2),
                            Text(
                              'Chụp ảnh',
                              style: AppTheme.labelSmall.copyWith(
                                color: AppTheme.textTertiary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: AppTheme.space4),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên',
                  hintText: 'Nhập tên nhân viên',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return ErrorMessages.employeeNameRequired;
                  }
                  if (value.trim().length < 2) {
                    return ErrorMessages.employeeNameTooShort;
                  }
                  if (value.trim().length > 50) {
                    return ErrorMessages.employeeNameTooLong;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.space3),

              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  hintText: 'Nhập số điện thoại',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!ValidationUtils.isValidPhoneNumber(value)) {
                      return ErrorMessages.employeePhoneInvalid;
                    }
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
          onPressed: _isSaving ? null : _saveEmployee,
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

class EmployeeDetailsDialog extends StatelessWidget {
  final Employee employee;

  const EmployeeDetailsDialog({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chi tiết nhân viên'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: AppTheme.borderRadiusLarge,
                ),
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
                    : Center(
                        child: Text(
                          employee.name[0].toUpperCase(),
                          style: AppTheme.displayLarge.copyWith(
                            color: AppTheme.textInverse,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppTheme.space4),

            // Name
            Text(
              'Tên:',
              style: AppTheme.labelMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.space1),
            Text(
              employee.name,
              style: AppTheme.bodyLarge,
            ),
            const SizedBox(height: AppTheme.space3),

            // Phone
            Text(
              'Số điện thoại:',
              style: AppTheme.labelMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.space1),
            Text(
              employee.phone.isEmpty ? 'Chưa có' : employee.phone,
              style: AppTheme.bodyLarge,
            ),
            const SizedBox(height: AppTheme.space3),

            // Created date
            Text(
              'Ngày tạo:',
              style: AppTheme.labelMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.space1),
            Text(
              DateFormatters.formatDateTime(employee.createdAt),
              style: AppTheme.bodyLarge,
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
}
