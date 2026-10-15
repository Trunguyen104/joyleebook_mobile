# JoyleeBook Mobile — Quy tắc lập trình & Tiêu chí kỹ thuật (Code Rules)

Tài liệu này quy định các tiêu chuẩn lập trình dành cho ứng dụng **JoyleeBook Mobile (Flutter)**, được xây dựng bám sát theo khung đánh giá đồ án/môn học PRN232.

---

## Tóm tắt trọng số đánh giá

| Tiêu chí | Trọng số | Trọng tâm đánh giá |
| :--- | :---: | :--- |
| **1. Nội dung chương trình học** | **15%** | Đầy đủ kiến thức cơ bản: Flutter Core, Local Database/Storage, Material Design 3, API Calls (Dio/Gateway), State Management (Riverpod). |
| **2. UI/UX & Thiết kế** | **15%** | Đồng nhất giao diện theo Design System (Warm Editorial), xử lý đủ 4 trạng thái (Loading, Empty, Error, Data), không tràn layout (RenderFlex overflow), phản hồi tương tác mượt mà. |
| **3. Business Logic & Validation Rules** | **50%** | **Kiểm soát tính đúng đắn của dữ liệu & nghiệp vụ**: Validate giá/số âm, độ dài chuỗi, phân quyền Author/Reader, quản lý token/session hết hạn, chống spam click, rollback khi API lỗi. |

---

## 1. Nội dung chương trình học (15%)

Yêu cầu ứng dụng phải thể hiện đầy đủ các thành phần kỹ thuật cốt lõi của lập trình Flutter & Mobile:

### 1.1. Flutter Core & Kiến trúc ứng dụng
- **Phân tách tầng rõ ràng**: Tuân thủ chuẩn Compass App Hybrid Architecture:
  - `data/`: Repositories, Services, DTOs.
  - `domain/`: Business Models (Pure Dart).
  - `ui/`: ViewModels (Riverpod Notifier) và Widgets theo từng feature.
  - `routing/`: Quản lý route tập trung qua `go_router`.
- **Tối ưu Widget**: Sử dụng `const` constructor cho các widget tĩnh để tránh build lại cây giao diện không cần thiết. Tránh lồng ghép widget quá sâu (không vượt quá 5-6 cấp lồng nhau, tách thành các private/reusable widget).
- **Vòng đời & Bất đồng bộ**: Sử dụng đúng `async/await`, giải phóng tài nguyên (controller, timer) trong hàm `dispose()`.

### 1.2. Local Storage & Database
Ứng dụng phải có đủ các cơ chế lưu trữ cục bộ:
- **`flutter_secure_storage`**: Lưu trữ nhạy cảm (JWT `accessToken`). Tuyệt đối không lưu token vào SharedPreferences dưới dạng plain text.
- **`shared_preferences`**: Lưu trữ cài đặt người dùng (User preferences: theme sáng/tối, cỡ chữ đọc truyện, cờ `isFirstLaunch`).
- **`sqflite` (hoặc Local Cache)**: Lưu trữ dữ liệu offline (Lịch sử đọc truyện gần đây, danh sách chương đã tải, hoặc cache tạm danh sách Series khi mất mạng).

### 1.3. Material Design 3
- Sử dụng toàn diện **Material 3** (`useMaterial3: true`).
- Tuân thủ touch target tối thiểu: Các nút bấm, icon bấm được phải đạt diện tích tối thiểu **48x48 dp** để người dùng thao tác dễ dàng trên màn hình cảm ứng.
- Áp dụng các component chuẩn: `Scaffold`, `AppBar`, `NavigationBar` (Bottom Navigation), `Card`, `SnackBar`, `AlertDialog`, `ModalBottomSheet`.

### 1.4. Gọi API & Xử lý mạng (API Calls)
- **Tập trung qua Gateway**: Tất cả request đều đi qua JoyleeBook Gateway dùng chung (`https://api.joyleebook.duckdns.org`, khai báo duy nhất tại `Environment.hostedBaseUrl`). Không bao giờ hard-code IP/port của từng microservice con.
- **HTTP Client chuyên dụng**: Sử dụng `Dio` cấu hình:
  - `connectTimeout`: 10 giây; `receiveTimeout`: 20 giây.
  - `Interceptors`: Tự động đính kèm `Authorization: Bearer <token>` vào header request nếu đã đăng nhập; tự động bắt mã `401` để logout.
- **DTO & Serialization**: Mọi dữ liệu JSON nhận từ API phải parse thông qua DTO bằng `@JsonSerializable()`. Tuyệt đối không truy cập trực tiếp `response.data['someKey']` trong các lớp UI.

### 1.5. Quản lý trạng thái (State Management)
- Sử dụng **`flutter_riverpod`** làm giải pháp state management chuẩn:
  - Dùng `Notifier` / `AsyncNotifier` cho state có logic nghiệp vụ.
  - Tận dụng `AsyncValue` (`AsyncData`, `AsyncLoading`, `AsyncError`) để quản lý các trạng thái bất đồng bộ từ API.
  - Phân tách rõ ràng: Widget chỉ `ref.watch()` để đọc state và gọi hàm ViewModel qua `ref.read()`. Không viết logic gọi API hay xử lý tính toán trong hàm `build()` của Widget.

---

## 2. Tiêu chuẩn UI/UX (15%)

Giao diện người dùng phải đồng nhất, tinh tế và không có lỗi hiển thị:

### 2.1. Bộ 4 trạng thái bắt buộc (4 States Pattern)
Mọi màn hình có dữ liệu từ mạng hoặc database đều **bắt buộc** phải xử lý trọn vẹn 4 trạng thái:
1. **Loading State**: Hiển thị Shimmer / Skeleton (ưu tiên) hoặc `CircularProgressIndicator` ở vị trí trung tâm, giữ nguyên layout để tránh giật lag khi tải xong.
2. **Empty State**: Khi danh sách rỗng (ví dụ: Chưa có truyện nào, tìm kiếm không thấy kết quả), phải hiển thị hình minh họa/icon nhẹ nhàng, câu thông báo rõ ràng và **1 nút hành động gợi ý** (ví dụ: "Khám phá ngay", "Thử từ khóa khác").
3. **Error State**: Khi mất mạng hoặc API lỗi, phải hiển thị thông báo lỗi thân thiện kèm nút **"Thử lại" (Retry button)** để người dùng tải lại trang mà không cần khởi động lại app.
4. **Data State**: Dữ liệu hiển thị gọn gàng, hỗ trợ thao tác kéo để làm mới (`RefreshIndicator`).

### 2.2. Quy tắc chống lỗi hiển thị (No Overflow)
- Tuyệt đối không để xảy ra lỗi dải sọc vàng đen `A RenderFlex overflowed by ... pixels`.
- Mọi form nhập liệu phải được bọc trong `SingleChildScrollView` kết hợp `SafeArea` để không bị bàn phím ảo che khuất các ô nhập liệu hoặc nút bấm.
- Các danh sách dữ liệu động phải sử dụng `ListView.builder` hoặc `CustomScrollView` (Slivers) để tái sử dụng bộ nhớ (lazy loading), không dùng `Column` lặp qua mảng lớn.

### 2.3. Phản hồi hành động (Feedback & Notifications)
- **Hành động tức thời (Thành công/Thông báo nhẹ)**: Dùng `ScaffoldMessenger.of(context).showSnackBar()` có thời gian hiển thị 3–4 giây, nền màu nhẹ đồng bộ hệ thống, không làm gián đoạn luồng làm việc.
- **Hành động nguy hiểm (Xóa, Đăng xuất)**: Bắt buộc mở `AlertDialog` xác nhận: tiêu đề rõ ràng, giải thích hệ quả (ví dụ: *"Bạn có chắc chắn muốn xóa truyện này? Hành động này không thể hoàn tác."*), nút Hủy và nút Xác nhận (màu Đỏ cảnh báo).
- **Hành động nâng cao / Bộ lọc**: Mở `showModalBottomSheet` có bo góc trên (`radiusLg`), có thanh vuốt (drag handle).

---

## 3. Business Logic & Validation Rules (50% - Trọng tâm)

Đây là phần chiếm tỷ trọng điểm số cao nhất. Hệ thống phải đảm bảo tính toàn vẹn dữ liệu, kiểm tra mọi trường hợp biên (boundary cases) và phân quyền chặt chẽ:

### 3.1. Quy tắc Validation Form & Ranh giới dữ liệu (Boundary Checks)

#### A. Form Xác thực (Authentication)
| Trường dữ liệu | Quy tắc kiểm tra (Validation Rules) | Thông báo lỗi hiển thị |
| :--- | :--- | :--- |
| **Username** | - Không được để trống / chỉ có khoảng trắng.<br>- Độ dài từ 3 đến 64 ký tự.<br>- Chỉ chấp nhận chữ cái, số, dấu chấm `.`, gạch dưới `_`, gạch ngang `-`. | *"Tên đăng nhập từ 3-64 ký tự và không chứa ký tự đặc biệt"* |
| **Password** | - Không được để trống.<br>- Độ dài từ 8 đến 128 ký tự.<br>- Bắt buộc có **ít nhất 1 chữ cái** và **ít nhất 1 chữ số**. | *"Mật khẩu tối thiểu 8 ký tự, bao gồm cả chữ và số"* |
| **Confirm Password** | - Giá trị nhập phải trùng khớp 100% với trường Password. | *"Mật khẩu xác nhận không trùng khớp"* |

#### B. Thao tác Quản lý Truyện & Chương (Series & Chapters)
| Trường dữ liệu | Quy tắc kiểm tra (Validation Rules) | Ngăn chặn lỗi nghiệp vụ |
| :--- | :--- | :--- |
| **Tên truyện (Title)** | - Không được để trống hoặc toàn dấu cách.<br>- Độ dài từ 3 đến 200 ký tự. | Chống tạo truyện rỗng, tiêu đề quá ngắn hoặc spam tiêu đề dài vô tận. |
| **Mô tả (Description)** | - Tối đa 2000 ký tự (nếu có nhập). | Tránh tràn bộ nhớ UI và database. |
| **Số thứ tự chương (Chapter Number)** | - Bắt buộc là số nguyên dương (`> 0`).<br>- **Tuyệt đối không chấp nhận số âm (`< 0`) hoặc số 0**. | Không được phép tồn tại chương có số thứ tự âm hoặc số thập phân. |
| **Giá tiền / Coins (nếu có)** | - Phải là số dương hoặc bằng 0 (`price >= 0`).<br>- **Tuyệt đối chặn giá trị âm**. | Chống lỗi nghiệp vụ: thêm sản phẩm/chương có giá âm làm sai lệch số dư. |
| **Nội dung chương (Content)** | - Không được để trống.<br>- Độ dài tối thiểu 50 ký tự/từ. | Ngăn chặn tác giả đăng tải chương rỗng. |

### 3.2. Quy tắc phân quyền & Kiểm soát quyền truy cập (Authorization)
- **Role Reader (Độc giả thông thường)**:
  - Chỉ xem danh sách truyện public (`GET /api/series`), xem chi tiết truyện, đọc chương public, quản lý tủ sách cá nhân.
  - **Ẩn hoàn toàn** các nút "Tạo truyện mới", "Chỉnh sửa", "Xóa truyện", "Thêm chương" trên giao diện.
- **Role Author (Tác giả)**:
  - Chỉ được quyền sửa/xóa các truyện do chính mình sáng tác (`authorId == currentUserId`).
  - Khi người dùng cố tình can thiệp gọi API sửa truyện của người khác, Gateway/Backend trả về `403 Forbidden` -> Mobile phải bắt được và hiển thị thông báo: *"Bạn không có quyền chỉnh sửa tác phẩm này"*.
- **Role Admin**:
  - Có toàn quyền quản lý, khóa/mở truyện, quản lý tài khoản.

### 3.3. Xử lý phiên làm việc & Token hết hạn (Session Lifecycle)
- **Khi nhận HTTP 401 (Unauthorized)**:
  1. Ngay lập tức gọi hàm xóa token trong `FlutterSecureStorage`.
  2. Đưa state phiên làm việc về trạng thái `Unauthenticated`.
  3. `GoRouter` tự động kích hoạt redirect đẩy người dùng về màn hình `/sign-in`.
  4. Hiển thị thông báo: *"Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."*
  5. Đảm bảo dùng cơ chế cờ/lock trong interceptor để nếu có 5 request chạy ngầm cùng bị 401 thì **chỉ hiển thị 1 thông báo duy nhất**, không mở nhiều màn hình đăng nhập đè lên nhau.

### 3.4. Phòng chống Race Condition & Spam Click (Double-Click Prevention)
- Khi người dùng bấm nút gửi form (Đăng nhập, Tạo truyện, Lưu chương):
  - **Tự động chuyển nút sang trạng thái `isLoading = true`** và vô hiệu hóa tương tác (`onPressed: null`).
  - Chỉ kích hoạt lại nút sau khi request hoàn tất (thành công hoặc thất bại).
  - Với ô tìm kiếm (Search Bar): Sử dụng cơ chế **Debounce** (trì hoãn 400–500ms sau khi người dùng dừng gõ phím mới bắn request API), tránh gọi API liên tục theo từng ký tự.

### 3.5. Cập nhật lạc quan có hoàn tác (Optimistic UI with Rollback)
- Áp dụng cho các tính năng: **Thêm vào tủ sách (Bookmark)**, **Thích (Like)**:
  1. Khi người dùng bấm icon Bookmark: Cập nhật ngay trạng thái icon trên UI thành đã lưu (tạo cảm giác phản hồi tức thì cho người dùng).
  2. Bắn request ngầm lên API.
  3. **Nếu API thất bại**: Lập tức hoàn tác (rollback) trạng thái icon về ban đầu và hiển thị thông báo lỗi: *"Không thể lưu vào tủ sách. Vui lòng thử lại sau."*

### 3.6. Chuẩn hóa thông báo lỗi (Error Mapping)
Tuyệt đối không hiển thị mã lỗi thô hoặc exception kỹ thuật lên giao diện người dùng. Áp dụng bảng ánh xạ sau:

| Mã lỗi HTTP / Sự cố mạng | Thông điệp thân thiện với người dùng |
| :--- | :--- |
| `DioExceptionType.connectionTimeout` / `receiveTimeout` | *"Kết nối mạng quá hạn. Vui lòng kiểm tra đường truyền và thử lại."* |
| `DioExceptionType.connectionError` / Không có mạng | *"Không thể kết nối đến máy chủ. Vui lòng kiểm tra Wi-Fi/4G."* |
| `400 Bad Request` | Lấy danh sách thông báo validation từ backend để hiển thị cụ thể dưới từng ô nhập liệu. |
| `403 Forbidden` | *"Bạn không có quyền thực hiện hành động này."* |
| `404 Not Found` | *"Dữ liệu không tồn tại hoặc đã bị xóa."* |
| `409 Conflict` | *"Tên đăng nhập hoặc dữ liệu này đã tồn tại trên hệ thống."* |
| `429 Too Many Requests` | *"Bạn đang gửi yêu cầu quá nhanh. Vui lòng thử lại sau giây lát."* |
| `500` / `502` / `503` | *"Hệ thống máy chủ đang bận. Vui lòng thử lại sau."* |

---

## 4. Checklist đánh giá trước khi nộp bài

- [ ] **15% Nội dung**: App chạy mượt trên Emulator và thiết bị thật; có đủ Storage (token + prefs), Material 3, Riverpod và Dio.
- [ ] **15% UI/UX**: Màu sắc chuẩn JoyleeBook (Plum & Amber); có đủ màn hình Loading/Empty/Error/Success; không bị lỗi dải sọc vàng đen khi mở bàn phím.
- [ ] **50% Logic**: Đã thử nghiệm các trường hợp biên:
  - [ ] Nhập số âm vào trường số -> Bị chặn và báo lỗi rõ ràng.
  - [ ] Nhập chuỗi rỗng / khoảng trắng -> Bị chặn.
  - [ ] Bấm nút liên tục 5 lần -> Chỉ bắn 1 request API duy nhất.
  - [ ] Ngắt Wi-Fi rồi thao tác -> Có thông báo mất mạng thân thiện kèm nút "Thử lại".
  - [ ] Đăng nhập tài khoản Reader rồi tìm cách sửa truyện -> Bị chặn phân quyền.
  - [ ] Token hết hạn -> Bị đưa về màn Sign-in, không bị crash app.
