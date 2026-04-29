import 'package:flutter_test/flutter_test.dart';
import 'package:eztimesheet/models/models.dart';
import 'package:eztimesheet/utils/error_messages.dart';

void main() {
  group('Employee Model', () {
    test('should create employee with default values', () {
      final employee = Employee(
        name: 'John Doe',
        phone: '0123456789',
      );

      expect(employee.name, 'John Doe');
      expect(employee.phone, '0123456789');
      expect(employee.isActive, true);
      expect(employee.photoPath, null);
      expect(employee.id, isNotEmpty);
      expect(employee.createdAt, isNotNull);
    });

    test('should create employee with custom values', () {
      final now = DateTime.now();
      final employee = Employee(
        id: 'test-id',
        name: 'Jane Smith',
        phone: '0987654321',
        photoPath: '/path/to/photo.jpg',
        createdAt: now,
        isActive: false,
      );

      expect(employee.id, 'test-id');
      expect(employee.name, 'Jane Smith');
      expect(employee.phone, '0987654321');
      expect(employee.photoPath, '/path/to/photo.jpg');
      expect(employee.createdAt, now);
      expect(employee.isActive, false);
    });

    test('should convert to map and back', () {
      final original = Employee(
        name: 'Test User',
        phone: '0123456789',
      );

      final map = original.toMap();
      final restored = Employee.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.phone, original.phone);
      expect(restored.photoPath, original.photoPath);
      expect(restored.isActive, original.isActive);
    });

    test('should copy with updated values', () {
      final original = Employee(
        name: 'Original Name',
        phone: '0123456789',
      );

      final copied = original.copyWith(
        name: 'Updated Name',
        phone: '0987654321',
      );

      expect(copied.name, 'Updated Name');
      expect(copied.phone, '0987654321');
      expect(copied.id, original.id);
    });

    test('should validate name correctly', () {
      final employee = Employee(name: 'Test', phone: '0123456789');

      // Valid name
      expect(employee.validateName(), null);

      // Empty name
      final emptyName = employee.copyWith(name: '');
      expect(emptyName.validateName(), ErrorMessages.employeeNameRequired);

      // Too short name
      final shortName = employee.copyWith(name: 'A');
      expect(shortName.validateName(), ErrorMessages.employeeNameTooShort);

      // Too long name
      final longName = employee.copyWith(name: 'A' * 51);
      expect(longName.validateName(), ErrorMessages.employeeNameTooLong);
    });

    test('should validate phone correctly', () {
      final employee = Employee(name: 'Test', phone: '');

      // Empty phone (optional)
      expect(employee.validatePhone(), null);

      // Valid phone
      final validPhone = employee.copyWith(phone: '0123456789');
      expect(validPhone.validatePhone(), null);

      // Invalid phone (wrong format)
      final invalidPhone = employee.copyWith(phone: '123456789');
      expect(invalidPhone.validatePhone(), ErrorMessages.employeePhoneInvalid);

      // Invalid phone (too short)
      final shortPhone = employee.copyWith(phone: '0123');
      expect(shortPhone.validatePhone(), ErrorMessages.employeePhoneInvalid);
    });

    test('should validate all fields', () {
      final employee = Employee(name: 'Test', phone: '0123456789');
      final validation = employee.validate();

      expect(validation['name'], null);
      expect(validation['phone'], null);
    });
  });
}
