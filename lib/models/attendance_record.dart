import 'package:uuid/uuid.dart';

enum WorkStatus {
  none,
  fullDay,
  halfDay,
}

class AttendanceRecord {
  final String id;
  final String employeeId;
  final DateTime date;
  final WorkStatus workStatus;
  final bool hasNightShift;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttendanceRecord({
    String? id,
    required this.employeeId,
    required this.date,
    this.workStatus = WorkStatus.none,
    this.hasNightShift = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'date': _dateToIso8601String(date),
      'workStatus': workStatus.name,
      'hasNightShift': hasNightShift ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from database map
  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as String,
      employeeId: map['employeeId'] as String,
      date: _parseIso8601Date(map['date'] as String),
      workStatus: WorkStatus.values.firstWhere(
        (type) => type.name == map['workStatus'],
        orElse: () => WorkStatus.none,
      ),
      hasNightShift: (map['hasNightShift'] as int?) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // Create a copy with updated fields
  AttendanceRecord copyWith({
    String? id,
    String? employeeId,
    DateTime? date,
    WorkStatus? workStatus,
    bool? hasNightShift,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      workStatus: workStatus ?? this.workStatus,
      hasNightShift: hasNightShift ?? this.hasNightShift,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper to convert DateTime to ISO8601 string (date only, no time)
  static String _dateToIso8601String(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Helper to parse ISO8601 string to DateTime (date only, no time)
  static DateTime _parseIso8601Date(String dateString) {
    final parts = dateString.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  // Validation
  String? validateDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (date.isAfter(today)) {
      return 'Lỗi: Không thể ghi nhận chấm công cho ngày tương lai';
    }
    return null;
  }

  // Get Vietnamese label for attendance type
  String get workStatusLabel {
    switch (workStatus) {
      case WorkStatus.fullDay:
        return 'Cả ngày';
      case WorkStatus.halfDay:
        return 'Nửa ngày';
      case WorkStatus.none:
        return 'Nghỉ';
    }
  }
}
