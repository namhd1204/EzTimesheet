import 'package:uuid/uuid.dart';

class Employee {
  final String id;
  final String name;
  final String phone;
  final String? photoPath;
  final DateTime createdAt;
  final bool isActive;

  Employee({
    String? id,
    required this.name,
    required this.phone,
    this.photoPath,
    DateTime? createdAt,
    this.isActive = true,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  // Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'photoPath': photoPath,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  // Create from database map
  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      photoPath: map['photoPath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isActive: (map['isActive'] as int) == 1,
    );
  }

  // Create a copy with updated fields
  Employee copyWith({
    String? id,
    String? name,
    String? phone,
    String? photoPath,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Validation
  String? validateName() {
    if (name.trim().isEmpty) {
      return 'Lỗi: Vui lòng nhập tên nhân viên';
    }
    if (name.trim().length < 2) {
      return 'Lỗi: Tên nhân viên phải có ít nhất 2 ký tự';
    }
    if (name.trim().length > 50) {
      return 'Lỗi: Tên nhân viên không được quá 50 ký tự';
    }
    return null;
  }

  String? validatePhone() {
    if (phone.trim().isEmpty) {
      return null; // Phone is optional
    }
    final phoneRegex = RegExp(r'^0\d{9,10}$');
    if (!phoneRegex.hasMatch(phone.trim())) {
      return 'Lỗi: Số điện thoại không hợp lệ (phải bắt đầu bằng 0 và có 10-11 số)';
    }
    return null;
  }

  // Full validation
  Map<String, String?> validate() {
    return {
      'name': validateName(),
      'phone': validatePhone(),
    };
  }
}
