/// Vietnamese error messages for the application
class ErrorMessages {
  // Employee errors
  static const String employeeNameRequired = 'Lỗi: Vui lòng nhập tên nhân viên';
  static const String employeeNameTooShort = 'Lỗi: Tên nhân viên phải có ít nhất 2 ký tự';
  static const String employeeNameTooLong = 'Lỗi: Tên nhân viên không được quá 50 ký tự';
  static const String employeePhoneInvalid = 'Lỗi: Số điện thoại không hợp lệ (phải bắt đầu bằng 0 và có 10-11 số)';
  static const String employeeDuplicate = 'Lỗi: Nhân viên với tên và số điện thoại này đã tồn tại';
  static const String employeeNotFound = 'Lỗi: Không tìm thấy nhân viên';
  static const String employeeTooMany = 'Cảnh báo: Quá nhiều nhân viên có thể làm chậm ứng dụng';
  static const String employeePhotoFailed = 'Cảnh báo: Không thể lưu ảnh';

  // Attendance errors
  static const String attendanceFutureDate = 'Lỗi: Không thể ghi nhận chấm công cho ngày tương lai';
  static const String attendanceDuplicate = 'Lỗi: Đã có bản ghi chấm công cho nhân viên này vào ngày này';
  static const String attendanceNotFound = 'Lỗi: Không tìm thấy bản ghi chấm công';
  static const String attendanceEmployeeNotFound = 'Lỗi: Không tìm thấy nhân viên';
  static const String attendanceRateNotConfigured = 'Lỗi: Chưa cấu hình tỷ lệ cho nhân viên này';
  static const String attendanceUndoFailed = 'Lỗi: Không có bản ghi chấm công để hoàn tác';

  // Payroll errors
  static const String payrollRateNotConfigured = 'Lỗi: Chưa cấu hình tỷ lệ cho nhân viên này trong tháng này';
  static const String payrollCalculationFailed = 'Lỗi: Không thể tính lương';
  static const String payrollOverflow = 'Lỗi: Tổng lương vượt quá giới hạn tính toán';

  // Data errors
  static const String dataExportFailed = 'Lỗi: Không thể xuất dữ liệu. Vui lòng thử lại.';
  static const String dataImportFailed = 'Lỗi: Không thể nhập dữ liệu. Vui lòng thử lại.';
  static const String dataInvalidFormat = 'Lỗi: Dữ liệu không hợp lệ';
  static const String dataMalformed = 'Lỗi: Dữ liệu bị hỏng';
  static const String dataImportConflict = 'Lỗi: Xung đột dữ liệu khi nhập';
  static const String dataStorageFull = 'Lỗi: Không thể lưu dữ liệu. Bộ nhớ đầy.';
  static const String dataBatteryLow = 'Cảnh báo: Pin yếu (<20%). Nên sạc pin trước khi xuất/nhập dữ liệu.';

  // General errors
  static const String generalError = 'Lỗi: Đã xảy ra lỗi. Vui lòng thử lại.';
  static const String networkError = 'Lỗi: Không thể kết nối mạng.';
  static const String permissionDenied = 'Lỗi: Không có quyền truy cập.';
  static const String operationCancelled = 'Đã hủy thao tác.';
  static const String operationSuccess = 'Thao tác thành công.';
}
