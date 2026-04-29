import 'package:uuid/uuid.dart';

class MonthlyRate {
  final String id;
  final String employeeId;
  final String month; // Format: YYYY-MM
  final double dailyRate;
  final double nightBonus;
  final DateTime createdAt;
  final DateTime updatedAt;

  MonthlyRate({
    String? id,
    required this.employeeId,
    required this.month,
    required this.dailyRate,
    this.nightBonus = 0.0,
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
      'month': month,
      'dailyRate': dailyRate,
      'nightBonus': nightBonus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from database map
  factory MonthlyRate.fromMap(Map<String, dynamic> map) {
    return MonthlyRate(
      id: map['id'] as String,
      employeeId: map['employeeId'] as String,
      month: map['month'] as String,
      dailyRate: (map['dailyRate'] as num).toDouble(),
      nightBonus: (map['nightBonus'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // Create a copy with updated fields
  MonthlyRate copyWith({
    String? id,
    String? employeeId,
    String? month,
    double? dailyRate,
    double? nightBonus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonthlyRate(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      month: month ?? this.month,
      dailyRate: dailyRate ?? this.dailyRate,
      nightBonus: nightBonus ?? this.nightBonus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Validation
  String? validateDailyRate() {
    if (dailyRate < 0) {
      return 'Lỗi: Tỷ lệ ngày không được âm';
    }
    if (dailyRate > 100000000) {
      return 'Lỗi: Tỷ lệ ngày không được quá 100,000,000 VND';
    }
    return null;
  }

  String? validateNightBonus() {
    if (nightBonus < 0) {
      return 'Lỗi: Tiền thưởng làm tối không được âm';
    }
    return null;
  }

  // Full validation
  Map<String, String?> validate() {
    return {
      'dailyRate': validateDailyRate(),
      'nightBonus': validateNightBonus(),
    };
  }

  // Calculate night rate (total for a day with night work)
  double get totalWithNight => dailyRate + nightBonus;

  // Format month for display
  String get monthDisplay {
    final parts = month.split('-');
    return '${parts[1]}/${parts[0]}'; // MM/YYYY format
  }
}
