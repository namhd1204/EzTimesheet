## 1. Phân tích chức năng hệ thống

### Quản lý nhân viên & Cấu hình lương

- **Hồ sơ nhân viên:** Tối giản chỉ gồm Tên, SĐT và Ảnh (chụp trực tiếp từ camera sẽ nhanh hơn chọn từ thư viện).
- **Cấu hình lương linh hoạt:** Việc cho phép thay đổi giá tiền công theo từng tháng là rất hợp lý, vì đặc thù lao động phổ thông thường thay đổi lương theo mùa vụ hoặc biến động thị trường.

### Cơ chế chấm công (Core Feature)

- Sử dụng cơ chế **"Một chạm"** hoặc **"Chọn nhanh"**. Thay vì bắt người dùng nhập số, hãy cho họ chọn các nút có sẵn: `Cả ngày`, `Nửa ngày`, `Có làm tối`.

### Lưu trữ và Đồng bộ

- **Lưu cục bộ (Offline-first):** Giúp ứng dụng chạy mượt mà ngay cả khi không có mạng.
- **Google Drive Backup:** Đây là giải pháp an toàn nhất cho người không rành công nghệ. Tuy nhiên, việc đăng nhập Google nên là tùy chọn (Optional) ngay từ đầu để họ có thể trải nghiệm app trước khi quyết định kết nối tài khoản.

---

## 2. Đề xuất thay đổi để phù hợp với người trên 40 tuổi

Để ứng dụng thực sự "dễ dùng", tôi đề xuất một số điều chỉnh sau:

### Giao diện "Cỡ đại" (UI/UX)

- **Cỡ chữ & Nút bấm:** Sử dụng font chữ lớn, độ tương phản cao. Các nút bấm phải to, rõ ràng, hạn chế tối đa việc dùng các biểu tượng trừu tượng mà không có chữ đi kèm.
- **Giao diện lịch:** Thay vì danh sách dài, hãy dùng **Giao diện Lịch (Calendar View)**. Người dùng bấm vào một ngày trên lịch, hiện lên bảng chọn: "Hôm nay [Tên nhân viên] làm thế nào?".

### Cải tiến chức năng chấm công

- **Chấm công hàng loạt:** Nếu một nhóm nhân viên cùng làm giống nhau, nên có chức năng "Chọn tất cả" rồi bấm "Cả ngày" để tiết kiệm thời gian.
- **Trạng thái trực quan:**
  - Màu xanh: Cả ngày.
  - Màu vàng: Nửa ngày.
  - Biểu tượng trăng khuyết: Có làm tối.
  - _Người dùng chỉ cần nhìn vào lịch là biết tình hình cả tháng mà không cần đọc chữ, làm nửa ngày thì không không thể làm cả ngày và ngược lại, nhưng vẫn có thể làm tối_

### Quản lý lương thông minh

- **Chốt lương tháng:** Nên có nút "Khóa dữ liệu tháng". Sau khi đã tính lương và trả tiền, người dùng bấm khóa để tránh việc lỡ tay chạm vào làm thay đổi số liệu cũ.

### Tự động hóa Backup

- **Lịch Backup**: **"2 giờ sáng hàng ngày"** khi có mạng.
- Thêm tính năng **"Phục hồi dữ liệu"** nổi bật ngay trang đầu nếu ứng dụng phát hiện dữ liệu trống (khi mới chuyển máy). Người dùng sau khi đăng nhập tài khoản google ở máy mới thì sẽ hiện nút **"Phục hồi dữ liệu"** lên để user có thể phục hồi dữ liệu.

---

## 3. Mô hình luồng dữ liệu (Gợi ý kỹ thuật)

Vì bạn muốn lưu dữ liệu theo máy nhưng có đồng bộ Google Drive, cấu trúc nên như sau:

1.  **Local Database (SQLite/Room):** Lưu trữ mọi thao tác tức thời.
2.  **JSON Export:** Khi đến lịch backup, chuyển toàn bộ Database thành 1 file JSON/Zip.
3.  **Google Drive API:** Đẩy file này lên một thư mục ẩn trên Drive của người dùng (App Data Folder).

---

## 4. Gợi ý quy trình sử dụng (User Flow) tối giản

1.  **Bước 1:** Mở app -> Thêm nhân viên (Chụp ảnh, nhập tên).
2.  **Bước 2:** Vào màn hình Lịch -> Chọn ngày -> Chọn Nhân viên -> Chọn "Cả ngày/Nửa ngày".
3.  **Bước 3:** Cuối tháng vào mục "Báo cáo" -> Nhập giá tiền công tháng này -> Xem tổng tiền
