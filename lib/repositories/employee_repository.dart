import '../models/models.dart';

/// Repository interface for Employee data access
abstract class EmployeeRepository {
  /// Get all active employees
  Future<List<Employee>> getAllActive();

  /// Get all employees (including inactive)
  Future<List<Employee>> getAll();

  /// Get employee by ID
  Future<Employee?> getById(String id);

  /// Get employee by name and phone (for duplicate checking)
  Future<Employee?> getByNameAndPhone(String name, String phone);

  /// Create new employee
  Future<Employee> create(Employee employee);

  /// Update existing employee
  Future<Employee> update(Employee employee);

  /// Delete employee (soft delete - set isActive to false)
  Future<void> delete(String id);

  /// Permanently delete employee
  Future<void> permanentDelete(String id);

  /// Count active employees
  Future<int> countActive();
}
