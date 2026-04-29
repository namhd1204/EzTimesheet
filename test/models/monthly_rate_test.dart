import 'package:flutter_test/flutter_test.dart';
import 'package:eztimesheet/models/models.dart';

void main() {
  group('MonthlyRate Model', () {
    test('should create monthly rate with default values', () {
      final rate = MonthlyRate(
        employeeId: 'employee-1',
        month: '2024-04',
        dailyRate: 300000,
      );

      expect(rate.employeeId, 'employee-1');
      expect(rate.month, '2024-04');
      expect(rate.dailyRate, 300000);
      expect(rate.nightBonus, 0.0);
      expect(rate.id, isNotEmpty);
    });

    test('should create monthly rate with custom values', () {
      final rate = MonthlyRate(
        id: 'test-id',
        employeeId: 'employee-2',
        month: '2024-05',
        dailyRate: 350000,
        nightBonus: 100000,
      );

      expect(rate.id, 'test-id');
      expect(rate.employeeId, 'employee-2');
      expect(rate.month, '2024-05');
      expect(rate.dailyRate, 350000);
      expect(rate.nightBonus, 100000);
    });

    test('should convert to map and back', () {
      final original = MonthlyRate(
        employeeId: 'employee-1',
        month: '2024-04',
        dailyRate: 300000,
        nightBonus: 50000,
      );

      final map = original.toMap();
      final restored = MonthlyRate.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.employeeId, original.employeeId);
      expect(restored.dailyRate, original.dailyRate);
      expect(restored.nightBonus, original.nightBonus);
    });

    test('should copy with updated values', () {
      final original = MonthlyRate(
        employeeId: 'employee-1',
        month: '2024-04',
        dailyRate: 300000,
      );

      final copied = original.copyWith(
        dailyRate: 320000,
        nightBonus: 50000,
      );

      expect(copied.dailyRate, 320000);
      expect(copied.nightBonus, 50000);
      expect(copied.month, original.month);
    });

    test('should validate daily rate correctly', () {
      final rate = MonthlyRate(
        employeeId: 'employee-1',
        month: '2024-04',
        dailyRate: 300000,
      );

      // Valid rate
      expect(rate.validateDailyRate(), null);

      // Negative rate
      final negativeRate = rate.copyWith(dailyRate: -100);
      expect(negativeRate.validateDailyRate(), 'Lỗi: Tỷ lệ ngày không được âm');

      // Too high rate
      final highRate = rate.copyWith(dailyRate: 100000001);
      expect(highRate.validateDailyRate(), 'Lỗi: Tỷ lệ ngày không được quá 100,000,000 VND');
    });

    test('should validate night bonus correctly', () {
      final rate = MonthlyRate(
        employeeId: 'employee-1',
        month: '2024-04',
        dailyRate: 300000,
        nightBonus: 50000,
      );

      // Valid bonus
      expect(rate.validateNightBonus(), null);

      // Negative bonus
      final negativeBonus = rate.copyWith(nightBonus: -100);
      expect(negativeBonus.validateNightBonus(), 'Lỗi: Tiền thưởng làm tối không được âm');
    });

    test('should calculate total with night correctly', () {
      final rate = MonthlyRate(
        employeeId: 'employee-1',
        month: '2024-04',
        dailyRate: 300000,
        nightBonus: 100000,
      );

      expect(rate.totalWithNight, 400000);
    });

    test('should format month for display', () {
      final rate = MonthlyRate(
        employeeId: 'employee-1',
        month: '2024-04',
        dailyRate: 300000,
      );

      expect(rate.monthDisplay, '04/2024');
    });
  });
}
