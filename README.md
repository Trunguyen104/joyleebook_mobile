# JoyleeBook Mobile (Flutter)

Ứng dụng di động **JoyleeBook Mobile** — Nền tảng đọc sách & truyện trực tuyến tối ưu cho thiết bị cầm tay, được xây dựng bằng **Flutter**, quản lý trạng thái bằng **Riverpod**, tuân thủ kiến trúc **Compass App Hybrid Architecture**, giao diện mang phong cách **Warm Editorial** (Plum & Amber) và kết nối tập trung qua **JoyleeBook API Gateway** (`https://api.joyleebook.duckdns.org`).

> [!IMPORTANT]
> **Phạm vi đối tượng sử dụng (Target Actor):**
> Ứng dụng di động JoyleeBook **chỉ dành riêng cho Actor Reader (Độc giả)**. Các chức năng sáng tác và quản trị của Author và Admin được quy hoạch hoàn toàn trên nền tảng Web Blazor.

---

## 📚 Hệ thống Tài liệu Dự án (Documentation Index)

Bộ tài liệu kỹ thuật được chuẩn hóa và phân chia rõ ràng trong thư mục [`docs/`](./docs/):

| STT | Tài liệu | Nội dung trọng tâm |
| :---: | :--- | :--- |
| **01** | [**Phạm vi Hệ thống cho Reader**](./docs/01-System-Scope-Reader.md) | Phân định In-Scope vs. Out-of-Scope; Chân dung độc giả; Quy tắc nghiệp vụ Read-only, Session lifecycle, Optimistic UI. |
| **02** | [**Kiến trúc Ứng dụng Mobile**](./docs/02-Mobile-Architecture.md) | Sơ đồ hệ thống qua API Gateway; Mô hình 4 tầng Compass App Hybrid (UI, Domain, Data, Routing); UDF Data flow; Phân cấp Local Storage 3 cấp; Exception hierarchy. |
| **03** | [**Luồng Nghiệp vụ & Hợp đồng API**](./docs/03-System-Flows-And-Contracts.md) | Sơ đồ tuần tự Auth, Session 401 Interceptor, Khám phá truyện 4-States, Debounce tìm kiếm 400ms, Đọc offline; Bảng contract endpoints qua Gateway. |
| **04** | [**Hướng dẫn Thiết kế Chức năng Mẫu**](./docs/04-Feature-Implementation-Guide.md) | Template thực chiến từ A-Z với chức năng Series Discovery (DTO ➔ Domain Model ➔ Repository ➔ Riverpod ViewModel ➔ UI 4 States ➔ Unit/Widget Test Fakes). |
| **05** | [**Quy tắc Lập trình & Tiêu chí Kỹ thuật**](./docs/Flutter-Mobile-Code-Rules.md) | Khung đánh giá PRN232 (15% Flutter Core & Storage, 15% UI/UX 4 States & No Overflow, 50% Business Logic, Validation & Optimistic Rollback). |
| **06** | [**Thiết lập Theme & Design System**](./docs/Flutter-Mobile-Design-System.md) | Phong cách Warm Editorial (Plum, Amber, Canvas, Paper & Ink); Bảng ánh xạ token CSS sang Flutter `AppColors`; Quy tắc xây dựng và mã nguồn 5 Shared Widgets thiết yếu. |
| **07** | [**Hướng dẫn Thiết lập & Tích hợp Gateway**](./docs/Flutter-Mobile-Setup.md) | Hướng dẫn kết nối JoyleeBook Gateway, kiểm tra Gateway dùng chung, kết nối HTTPS; Kiểm thử mock repository. |

---

## 🚀 Khởi chạy Nhanh (Quick Start)

### 1. Cài đặt Dependencies
```powershell
flutter pub get
```

### 2. Sinh mã nguồn tự động (nếu có DTO / Riverpod Generator)
```powershell
dart run build_runner build --delete-conflicting-outputs
```

### 3. Chạy Ứng dụng theo Thiết bị

App gọi **Gateway dùng chung đã deploy**: `https://api.joyleebook.duckdns.org` — không cần chạy backend trên máy, cùng một lệnh chạy được trên mọi emulator/thiết bị thật:

```powershell
flutter run -t lib/main_development.dart
```

> `API_BASE_URL` chỉ là **base URL của Gateway** (không kèm `/api/...`). Các path như `/api/series` đã được khai báo trong `lib/config/api_endpoints.dart`.

Dự án không chạy backend local. Chỉ khi cần trỏ sang một Gateway khác mới truyền `--dart-define=API_BASE_URL=https://<gateway-khac>`.

Cũng có thể đổi URL lúc chạy trong tab **Kiểm tra Gateway**.

---

## Đổi mật khẩu

Đăng nhập, mở tab **Cá nhân**, chọn biểu tượng khóa **Đổi mật khẩu** trên thanh tiêu đề. Nhập mật khẩu hiện tại, mật khẩu mới và xác nhận. Mật khẩu mới phải khác mật khẩu hiện tại, dài 8–128 ký tự, có chữ cái và chữ số. Đổi thành công sẽ xóa token trên máy và chuyển về đăng nhập bằng mật khẩu mới; đăng nhập xong trở lại trang Cá nhân.

Ứng dụng gọi `PUT /api/auth/me/password` qua Gateway với body `{ currentPassword, newPassword, confirmNewPassword }`. Backend trả `204` khi thành công và thu hồi phiên hiện tại cùng các refresh token. Mật khẩu hiện tại sai được hiển thị ngay dưới ô nhập; lỗi mạng cho phép thử lại.

## Khôi phục mật khẩu

Từ màn hình **Đăng nhập**, chọn **Quên mật khẩu?**, nhập email và gửi yêu cầu. Sau khi nhận email, chọn **Tôi đã có mã khôi phục**, dán mã hoặc toàn bộ liên kết đặt lại mật khẩu, rồi bấm **Tiếp tục**. Khi mã hợp lệ, nhập mật khẩu mới và xác nhận; sau khi hoàn tất, quay lại đăng nhập. Mật khẩu phải có 8–128 ký tự, bao gồm chữ cái và chữ số.

Luồng sử dụng các hàm đã có trong `AuthRepository`: `POST /api/auth/forgot-password`, `GET /api/auth/validate-reset-token` và `POST /api/auth/reset-password`. Route `/reset-password` nhận tham số `email`, `token` và `from` (tùy chọn); mã trong URL cần được URL-encode. Chưa cấu hình Android App Links/iOS Universal Links; người dùng có thể dán liên kết vào ứng dụng để tiếp tục. Việc gửi email phụ thuộc dịch vụ backend.

Kiểm thử luồng với API giả:

```bash
flutter test test/ui/forgot_password_screen_test.dart test/ui/reset_password_screen_test.dart test/widget_test.dart
```

## 🛠 Bộ Công nghệ & Thư viện Cốt lõi

- **Framework**: Flutter 3.x (Dart 3.x)
- **Kiến trúc**: Compass App Hybrid Architecture (Layer-first cho Data & Domain, Feature-first cho UI)
- **State Management**: `flutter_riverpod` + `riverpod_annotation`
- **Navigation & Routing**: `go_router`
- **Networking**: `dio` (kết nối tập trung qua API Gateway)
- **Secure Storage**: `flutter_secure_storage` (lưu trữ JWT Access Token)
- **Preferences & Caching**: `shared_preferences` / `sqflite`
- **Serialization**: `json_serializable`
