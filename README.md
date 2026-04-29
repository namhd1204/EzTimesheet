# EzTimesheet

Phần mềm quản lý chấm công và tính lương đơn giản, hiệu quả.

## Hướng dẫn chạy trên Web

Để chạy project trên trình duyệt Chrome với profile cá nhân (giữ đăng nhập Google), sử dụng lệnh sau:

```bash
flutter run -d web-server --web-port 8083
```

Sau khi chạy lệnh trên, hãy mở trình duyệt Chrome và truy cập: `http://localhost:8083`

## Tính năng chính

- [x] Quản lý danh sách nhân viên (Thêm/Xóa/Xem chi tiết)
- [x] Chấm công hàng ngày (Cả ngày, Nửa ngày, Làm tối)
- [x] Xem lịch sử chấm công theo tháng
- [x] Tính lương tự động dựa trên mức lương cấu hình
- [x] Sao lưu và khôi phục dữ liệu qua file JSON
- [x] Đồng bộ hóa dữ liệu với Google Drive
