class MonthLock {
  final String month; // YYYY-MM
  final bool isLocked;
  final DateTime updatedAt;

  MonthLock({
    required this.month,
    required this.isLocked,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'isLocked': isLocked ? 1 : 0,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MonthLock.fromMap(Map<String, dynamic> map) {
    return MonthLock(
      month: map['month'],
      isLocked: map['isLocked'] == 1,
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  MonthLock copyWith({
    String? month,
    bool? isLocked,
    DateTime? updatedAt,
  }) {
    return MonthLock(
      month: month ?? this.month,
      isLocked: isLocked ?? this.isLocked,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
