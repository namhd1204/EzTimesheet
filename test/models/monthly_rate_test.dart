import 'package:flutter_test/flutter_test.dart';
import 'package:eztimesheet/models/models.dart';

void main() {
  group('MonthlyRate Model', () {
    test('should create monthly rate with default values', () {
      final now = DateTime.now();
      final rate = MonthlyRate(
        employeeId: 'employee-1',
        month: '2024-04',
        dailyRate: 500000,
      );

      expect(rate.employeeId, 'employee-1');
      expect(rate.month, '2024-04');
      expect(rate.dailyRate, 500000);
      expect(rate.nightRateMultiplier, 1.5);
      expect(rate.id, isNotEmpty);
      expect(rate.createdAt, isNotNull);
      expect(rate.updatedAt, isNotNull);
    });

    test('should create monthly rate with custom values', () {
      final now = DateTime.now();
      final createdAt = now.subtract(const Duration(days: 1));
      final updatedAt = now;

      final rate = MonthlyRate(
        id: 'test-id',
        employeeId: 'employee-2',
        month: '2024-05',
        dailyRate: 600000,
        nightRateMultiplier: 2.0,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(rate.id, 'test-id');
      expect(rate.employeeId, 'employee-2');
      expect(rate.month, '2024-05');
      expect(rate.dailyRate, 600000);
      expect(rate.nightRateMultiplier, 2.0);
      expect(rate.createdAt, createdAt);
      expect(rate.updatedAt, updatedAt);
    });

    test('should convert to map and back', () {
      final original = MonthlyRate(
        employeeId: 'employee-1',
        month: '2024-04',
        dailyRate: 500000,
        nightRateMultiplier: 1.5,
      );

      final map = original.toMap();
      final restored = MonthlyRate.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.employeeId, original.employeeId);
      expect(restored.month, original.month);
      expect(restored.dailyRate, original.dailyRate);
      expect(restored.nightRateMultiplier, original.nightRateMultiplier);
    });

    test('should copy with updated values', () {
      final original = MonthlyRate(
        employeeId: 'employee-1',
        month: '2024-04',
        dailyRate: 500000,
      );

      final copied = original.copyWith(
        dailyRate: 600000,
        nightRateMultiplier: 2.0,
        updatedAt: DateTime.now(),
      );

      expect(copied.dailyRate, 600000);
      expect(copied.nightRateMultiplier, 2.0);
      expect(copied.employeeId, original.employeeId);
      expect(copied.month, original.month);
    });

    test('should validate daily rate correctly', () {
      final rate = MonthlyRate(
        employeeId: 'employee-1',
        month: '2024-04',
        dailyRate: 500000,
      );

      // Valid rate
      expect(rate.validateDailyRate(), null);

      // Zero rate
      final zeroRate = rate.copyWith(dailyRate: 0);
      expect(zeroRate.validateDailyRate(), ErrorMessages.rateZero);

      // Negative rate
      final negativeRate = rate.copyWith(dailyRate: -100);
      expect(negativeRate.validateDailyRate(), ErrorMessages.rateNegative);

      // Too high rate
      final highRate = rate.copyWith(dailyRate: 100000001);
      expect(highRate.validateDailyRate(), ErrorMessages.rateTooHigh);
    });

    test('should validate night rate multiplier correctly', () {
      final rate = MonthlyRate(
        employeeId: 'employee-1',
        month: '2024-04',
        dailyRate: 500000,
        nightRateMultiplier: 1.5,
      );

      // Valid multiplier
      expect(rate.validateNightRateMultiplier(), null);

      // Too low multiplier
      final lowMultiplier = rate.copyWith(nightRateMultiplier: 0.9);
      expect(lowMultiplier.validateNightRateMultiplier(), ErrorMessages.nightRateMultiplierTooLow);

      // Too high multiplier
      final highMultiplier = rate.copyWith(nightRateMultiplier: 3.1);
      expect(highMultiplier.validateNightRateMultiplier(), ErrorMessages.nightRateMultiplierTooHigh);
    });

    test('should validate month format correctly', () {
      final rate = MonthlyRate(
        employeeId: 'employee-1',
        month: '2024-04',
        dailyRate: 500000,
      );

      // Valid month format
      expect(rate.validateMonth(), null);

      // Invalid format - missing year
      final invalidFormat1 = rate.copyWith(month: '04');
      expect(invalidFormat1.validateMonth(), ErrorMessages.monthInvalidFormat);

      // Invalid format - missing month
      final invalidFormat2 = rate.copyWith(month: '2024');
      expect(invalidFormat2.validateMonth(), ErrorMessages.monthInvalidFormat);

      // Invalid format - wrong separator
      final invalidFormat3 = rate.copyWith(month: '2024/04');
      expect(invalidFormat3.validateMonth(), ErrorMessages.monthInvalidFormat);

      // Invalid month number
      final invalidMonth = rate.copyWith(month: '2024-13');
      expect(invalidMonth.validateMonth(), ErrorMessages.monthInvalidRange);
    });

    test('should validate all fields', () {
      final rate = MonthlyRate(
        employeeId: 'employee-1',
        month: '2024-04',
        dailyRate: 500000,
        nightRateMultiplier: 1.5,
      );
      final validation = rate.validate();

      expect(validation['dailyRate'], null);
      expect(validation['nightRateMultiplier'], null);
      expect(validation['month'], null);
    });

    test('should handle edge cases for daily rate', () {
      final rate = MonthlyRate(
        employeeId: 'employee-1',
        month: '2024-04',
        dailyRate: 500000,
      );

      // Minimum valid rate
      final minRate = rate.copyWith(dailyRate: 1);
      expect(minRate.validateDailyRate(), null);

      // Maximum valid rate
      final maxRate = rate.copyWith(dailyRate: 100000000);
      expect(maxRate.validateDailyRate(), null);
    });

    test('should handle edge cases for night rate multiplier', () {
      final rate = MonthlyRate(
        employeeId: 'employee-1',
        month: '2024-04',
        dailyRate: 500000,
        nightRateMultiplier: 1.5,
      );

      // Minimum valid multiplier
      final minMultiplier = rate.copyWith(nightRateMultiplier: 1.0);
      expect(minMultiplier.validateNightRateMultiplier(), null);

      // Maximum valid multiplier
      final maxMultiplier = rate.copyWith(nightRateMultiplier: 3.0);
      expect(maxMultiplier.validateNightRateMultiplier(), null);
    });
  });
}
