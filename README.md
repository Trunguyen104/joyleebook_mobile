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

## 🛠 Bộ Công nghệ & Thư viện Cốt lõi

- **Framework**: Flutter 3.x (Dart 3.x)
- **Kiến trúc**: Compass App Hybrid Architecture (Layer-first cho Data & Domain, Feature-first cho UI)
- **State Management**: `flutter_riverpod` + `riverpod_annotation`
- **Navigation & Routing**: `go_router`
- **Networking**: `dio` (kết nối tập trung qua API Gateway)
- **Secure Storage**: `flutter_secure_storage` (lưu trữ JWT Access Token)
- **Preferences & Caching**: `shared_preferences` / `sqflite`
- **Serialization**: `json_serializable`
