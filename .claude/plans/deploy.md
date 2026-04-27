### Bước 1: Chuẩn bị thông tin ứng dụng (Quan trọng)

Trước khi tạo file, bạn cần đảm bảo ứng dụng hiển thị đúng tên và biểu tượng để người dùng dễ nhận biết.

1.  **Đổi tên ứng dụng (Tiếng Việt):**
    - Mở file: `android/app/src/main/AndroidManifest.xml`.
    - Tìm dòng `android:label="tên_dự_án"`.
    - Sửa thành: `android:label="Chấm Công"`.
2.  **Cấu hình Icon (Biểu tượng):**
    - Sử dụng package `flutter_launcher_icons`.
    - Chuẩn bị 1 file ảnh vuông (1024x1024px) đặt tên là `icon_app.png` trong thư mục `assets/images/`.
    - Chạy lệnh cấu hình để icon tự động cập nhật vào hệ thống Android.

---

### Bước 2: Tạo KeyStore (Ký tên ứng dụng)

Để Android cho phép cài đặt và chạy ổn định, ứng dụng cần một "chữ ký số".

1.  Mở terminal (ô nhập lệnh) tại thư mục dự án.
2.  Nhập lệnh sau (Thay `mat-khau-cua-ban` bằng mật khẩu dễ nhớ của bạn):

    ```bash
    keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
    ```

    _(Lưu ý: Sau khi chạy, file `upload-keystore.jks` sẽ được tạo ra ở thư mục người dùng. Hãy copy nó vào thư mục `android/app/` trong dự án của bạn)._

3.  **Cấu hình kết nối key:**
    - Mở file `android/key.properties` (nếu chưa có thì tạo mới) và dán nội dung này vào:
      ```properties
      storePassword=mat-khau-cua-ban
      keyPassword=mat-khau-cua-ban
      keyAlias=upload
      storeFile=upload-keystore.jks
      ```
    - Mở file `android/app/build.gradle` và tìm phần `buildTypes`, cấu hình để nó sử dụng key này (đây là bước kỹ thuật để Flutter tự động ký tên khi build).

---

### Bước 3: Lệnh tạo file APK

Bạn nên tạo file APK theo kiểu **"Split" (Chia nhỏ)**. Điều này đặc biệt quan trọng vì người dùng trên 40 tuổi thường dùng nhiều dòng điện thoại khác nhau (máy cũ, máy mới).

Mở terminal và gõ:

```bash
flutter build apk --split-per-abi --release
```

**Tại sao lại dùng lệnh này?**

- Lệnh này sẽ tạo ra các file APK riêng biệt tối ưu cho từng loại chip điện thoại.
- File tạo ra sẽ nhẹ hơn (thường giảm 30-50% dung lượng), giúp người dùng tải qua Zalo nhanh hơn và máy chạy mượt hơn.

---

### Bước 4: Lấy file và gửi cho người dùng

Sau khi lệnh chạy xong, bạn truy cập vào đường dẫn sau trong thư mục dự án:
`build/app/outputs/flutter-apk/`

Bạn sẽ thấy các file:

1.  `app-armeabi-v7a-release.apk`: Dành cho các máy Android đời cũ (Rất phổ biến).
2.  `app-arm64-v8a-release.apk`: Dành cho các máy Android đời mới, tốc độ cao.
3.  `app-x86_64-release.apk`: Dành cho trình giả lập.

**Lời khuyên:** Bạn nên gửi file **`app-armeabi-v7a-release.apk`** hoặc **`app-arm64-v8a-release.apk`** cho người dùng. Nếu không chắc chắn máy họ là loại nào, bạn có thể build lệnh `flutter build apk --release` (không có split) để ra 1 file duy nhất nặng hơn nhưng máy nào cũng dùng được.

---

### Bước 5: Lưu ý hỗ trợ người dùng cài đặt

Vì tệp APK này không tải từ Google Play, khi người dùng mở file trên điện thoại, họ sẽ gặp cảnh báo bảo mật. Bạn nên chuẩn bị sẵn một tin nhắn hướng dẫn ngắn:

> **Hướng dẫn cài đặt ứng dụng Chấm Công:**
>
> 1. Anh/Chị bấm vào file để tải về.
> 2. Nếu máy báo "Bị chặn bởi Play Protect" hoặc "Nguồn không xác định", hãy bấm vào **Cài đặt** (Settings).
> 3. Chọn **Cho phép cài đặt từ nguồn này** (Allow from this source).
> 4. Bấm **Quay lại** và chọn **Cài đặt** là xong ạ.

### Mẹo nhỏ cho ứng dụng của bạn:

Vì đối tượng là người ít dùng công nghệ, khi build APK xong, hãy kiểm tra thử dung lượng. Nếu file **dưới 15MB**, tỷ lệ người dùng cài đặt thành công sẽ cao hơn rất nhiều so với các file nặng 40-50MB. Flutter mặc định làm rất tốt việc này nên bạn hoàn toàn có thể yên tâm.
