# Hướng dẫn Tích hợp Google Drive API vào EzTimesheet

Dưới đây là các bước chi tiết để cấu hình **Google Cloud Console**, giúp ứng dụng EzTimesheet có thể sao lưu dữ liệu lên Google Drive.

## Bước 1: Tạo Dự án trên Google Cloud Console

1. Truy cập [Google Cloud Console](https://console.cloud.google.com/).
2. Đăng nhập bằng tài khoản Google.
3. Nhấp vào **Select a project** -> **New Project**.
4. Đặt tên dự án (ví dụ: `EzTimesheet`) và nhấn **Create**.

## Bước 2: Bật Google Drive API

1. Tại thanh tìm kiếm trên cùng, nhập "Google Drive API".
2. Chọn **Google Drive API** từ danh sách kết quả.
3. Nhấn nút **Enable**.

## Bước 3: Cấu hình OAuth Consent Screen

Trước khi tạo Client ID, bạn cần cấu hình màn hình xin quyền (Consent Screen).

1. Vào menu bên trái: **APIs & Services** -> **OAuth consent screen**.
2. Chọn **User Type**:
   - Chọn **External** (nếu muốn bất kỳ ai cũng dùng được).
   - Nhấn **Create**.
3. Điền thông tin cơ bản:
   - **App name**: EzTimesheet
   - **User support email**: Email của bạn.
   - **Developer contact information**: Email của bạn.
4. Nhấn **Save and Continue** cho đến hết.
5. (Quan trọng) Trong phần **Test users**, hãy thêm email của bạn để có thể đăng nhập khi ứng dụng còn ở trạng thái "Testing".

## Bước 4: Tạo OAuth 2.0 Client IDs

Bạn cần tạo các Client ID riêng biệt cho từng nền tảng.

### 1. Cho Web (Để sửa lỗi crash trên trình duyệt)
1. Vào **APIs & Services** -> **Credentials**.
2. Nhấn **Create Credentials** -> **OAuth client ID**.
3. Chọn **Application type**: `Web application`.
4. **Authorized JavaScript origins**:
   - Thêm `http://localhost:8081` (hoặc port bạn đang chạy debug).
5. Nhấn **Create**.
6. **Lưu lại Client ID** này.

### 2. Cho Android
1. Làm tương tự nhưng chọn **Application type**: `Android`.
2. Nhập **Package name**: `com.namhd.eztimesheet` (kiểm tra trong `android/app/build.gradle`).
3. Nhập **SHA-1 certificate fingerprint**:
   - Chạy lệnh này trong terminal để lấy: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android` (trên Windows thay `~` bằng đường dẫn thư mục user).

## Bước 5: Cấu hình trong Mã nguồn Flutter

### Cấu hình cho Web
Mở tệp `web/index.html` và thêm thẻ `<meta>` vào trong thẻ `<head>`:

```html
<head>
  ...
  <meta name="google-signin-client_id" content="YOUR_CLIENT_ID_FOR_WEB.apps.googleusercontent.com">
</head>
```

### Cấu hình cho Android
Plugin `google_sign_in` thường tự động nhận diện nếu bạn đã tải tệp `google-services.json` (từ Firebase) hoặc cấu hình đúng Client ID trong Google Cloud.

> [!TIP]
> Nếu bạn chỉ phát triển local trên Web, hãy đảm bảo Client ID trong `web/index.html` khớp với ID bạn vừa tạo trên Console.

## Bước 6: Kiểm tra tính năng
1. Chạy lại ứng dụng: `flutter run -d chrome --web-port 8081`.
2. Vào phần **Cài đặt** -> **Đồng bộ Google Drive**.
3. Hệ thống sẽ hiển thị cửa sổ đăng nhập Google để xin quyền truy cập thư mục `appDataFolder` trên Drive.
