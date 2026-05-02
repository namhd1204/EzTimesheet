import '../models/models.dart';
import '../repositories/repositories.dart';

/// Policy for inheriting salary rates from previous months.
/// Implements the rule: if a month has no rate for an employee,
/// inherit the most recent rate from any previous month.
///
/// This is a public service that can be used by screens directly,
/// and also by other services internally.
class RateInheritancePolicy {
  final MonthlyRateRepository _monthlyRateRepository;

  RateInheritancePolicy(this._monthlyRateRepository);

  /// Ensure or inherit a rate for an employee in a specific month.
  ///
  /// Returns the existing rate for the month, or creates and returns
  /// a new rate inherited from the most recent prior rate.
  ///
  /// Returns null if:
  /// - Rate exists for this month, or
  /// - No prior rate exists and no new rate was created
  ///
  /// Gracefully skips inheritance if no prior rate exists;
  /// does not throw an error.
  Future<MonthlyRate?> ensureOrInherit(
    String employeeId,
    String month,
  ) async {
    // Check if rate already exists for this month
    var rate = await _monthlyRateRepository.getByEmployeeAndMonth(
      employeeId,
      month,
    );

    if (rate != null) {
      // Rate already exists, no need to inherit
      return rate;
    }

    // Rate doesn't exist; try to inherit from prior month
    final latestRate = await _monthlyRateRepository.getLatestRate(employeeId);
    if (latestRate != null) {
      // Create new rate for this month based on latest
      rate = MonthlyRate(
        employeeId: employeeId,
        month: month,
        dailyRate: latestRate.dailyRate,
        nightBonus: latestRate.nightBonus,
      );
      await _monthlyRateRepository.create(rate);
      return rate;
    }

    // No prior rate exists; return null without throwing error
    // Caller (e.g., PayrollService.calculatePayroll) will handle the missing rate
    return null;
  }

  /// Ensure or inherit rates for multiple employees in a month.
  ///
  /// Convenience method for bulk operations.
  /// Returns the set of employee IDs that successfully inherited or already had rates.
  Future<Set<String>> ensureOrInheritForAll(
    List<String> employeeIds,
    String month,
  ) async {
    final successful = <String>{};

    for (final id in employeeIds) {
      final rate = await ensureOrInherit(id, month);
      if (rate != null) {
        successful.add(id);
      }
    }

    return successful;
  }
}
