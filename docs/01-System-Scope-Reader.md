# JoyleeBook Mobile — Phạm vi Hệ thống (System Scope: Actor Reader)

Tài liệu này xác định rõ ràng ranh giới phạm vi nghiệp vụ (System Scope) cho ứng dụng di động **JoyleeBook Mobile**, với đối tượng thụ hưởng và tương tác duy nhất là **Độc giả (Reader)**.

---

## 1. Định vị ứng dụng & Tuyên ngôn Phạm vi (Scope Statement)

**JoyleeBook Mobile** là ứng dụng di động được thiết kế chuyên biệt phục vụ nhu cầu **khám phá, lưu trữ và đọc truyện/sách trực tuyến** trên thiết bị cầm tay.

> [!IMPORTANT]
> **Quy định ranh giới Actor trên Mobile:**
> Ứng dụng di động JoyleeBook **chỉ dành riêng cho Actor Reader (Độc giả)**. 
> Toàn bộ các chức năng sáng tác, quản lý bản thảo, duyệt nội dung và quản trị hệ thống của **Author (Tác giả)** và **Admin (Quản trị viên)** được phân định rõ ràng thuộc phạm vi của **Web Portal (Blazor Web / Admin Dashboard)** và **không triển khai trên Mobile**.

Triết lý này giúp ứng dụng mobile:
- Tinh gọn giao diện, tập trung 100% vào sự tiện dụng và thư thái khi đọc sách.
- Tránh phình to mã nguồn và logic phân quyền phức tạp trên thiết bị di động.
- Đảm bảo trải nghiệm người dùng đạt độ mượt mà, tối ưu hiệu năng và thời lượng pin.

---

## 2. Bảng phân ranh giới Scope (In-Scope vs. Out-of-Scope)

| Nhóm chức năng | Trong phạm vi Mobile (In-Scope — Reader) | Ngoài phạm vi Mobile (Out-of-Scope — Chuyển sang Web) |
| :--- | :--- | :--- |
| **Xác thực & Tài khoản (Auth & Profile)** | - Đăng ký tài khoản độc giả mới (`/sign-up`).<br>- Đăng nhập hệ thống (`/sign-in`).<br>- Đăng xuất tài khoản an toàn (`/sign-out`).<br>- Quản lý phiên bằng `FlutterSecureStorage`.<br>- Xem thông tin cá nhân cơ bản của độc giả. | - Quản lý danh sách người dùng toàn hệ thống (Admin).<br>- Phân quyền, cấm tài khoản, mở khóa người dùng (Admin).<br>- Nâng cấp tài khoản lên Author/Creator. |
| **Khám phá tác phẩm (Series Discovery)** | - Xem danh sách truyện nổi bật, mới cập nhật.<br>- Xem chi tiết tác phẩm: bìa, tên, tác giả, mô tả, trạng thái, danh sách chương.<br>- Tìm kiếm truyện với cơ chế Debounce 400ms.<br>- Lọc truyện theo thể loại, trạng thái. | - Đăng tải tác phẩm mới (`POST /api/series`).<br>- Chỉnh sửa thông tin tác phẩm (`PUT /api/series/{id}`).<br>- Xóa tác phẩm (`DELETE /api/series/{id}`).<br>- Kiểm duyệt, ẩn/hiện tác phẩm trên sàn (Admin). |
| **Đọc truyện (Reading Experience)** | - Đọc nội dung chương truyện với giao diện Warm Editorial.<br>- Chuyển chương kế tiếp / chương trước.<br>- Mục lục chương để nhảy nhanh đến chương mong muốn.<br>- Tự động ghi nhớ vị trí chương đang đọc gần nhất vào Local Storage. | - Soạn thảo văn bản chương truyện (Author Studio).<br>- Đăng tải chương mới, lập lịch đăng chương (Author).<br>- Chỉnh sửa/xóa nội dung chương đã đăng (Author). |
| **Tủ sách cá nhân (Personal Library)** | - Lưu truyện vào tủ sách yêu thích (Bookmark) với cơ chế Optimistic UI (tự rollback nếu lỗi).<br>- Xem danh sách truyện đã lưu trong tủ sách.<br>- Xem lịch sử đọc truyện gần đây (Recent Reads - lưu offline).<br>- Xóa truyện khỏi tủ sách hoặc lịch sử đọc. | - Quản lý doanh thu, thống kê lượt đọc của truyện (Author).<br>- Báo cáo phân tích tương tác độc giả (Author/Admin). |
| **Cài đặt & Trải nghiệm (Reader Settings)** | - Tùy chỉnh chế độ giao diện Sáng / Tối (Light / Dark mode).<br>- Tùy chỉnh cỡ chữ đọc truyện (Font size scaling).<br>- Xóa bộ nhớ đệm (Clear cache).<br>- Xem phiên bản ứng dụng và thông tin giới thiệu. | - Cấu hình hệ thống, thiết lập cổng thanh toán (Admin).<br>- Quản lý cấu hình microservices và Gateway (Admin). |

---

## 3. Chân dung người dùng mục tiêu (User Persona: Reader)

- **Mục đích chính**: Giải trí, tìm đọc những bộ truyện yêu thích bất cứ lúc nào, mọi nơi chỉ với một chiếc điện thoại thông minh.
- **Thói quen sử dụng**:
  - Thao tác bằng một tay khi đang di chuyển hoặc nằm thư giãn.
  - Thường đọc trong thời gian dài (30 phút đến vài tiếng), đòi hỏi màn hình màu sắc ấm áp, dịu mắt (phong cách Warm Editorial), chữ rõ nét, không gây mỏi mắt.
  - Kỳ vọng tốc độ mở app và chuyển chương nhanh, không bị giật lag hay văng app (crash).
  - Có thể mất mạng đột ngột (đi tàu xe, thang máy), kỳ vọng ứng dụng thông báo thân thiện và cho phép đọc tiếp nội dung đã cache cục bộ.

---

## 4. Các quy tắc nghiệp vụ cốt lõi dành riêng cho Reader (Business Rules)

### 4.1. Quy tắc hiển thị Read-Only đối với nội dung tác phẩm
- Trên toàn bộ giao diện mobile, **tuyệt đối không hiển thị** các nút thao tác quản trị như: *"Tạo truyện mới"*, *"Sửa truyện"*, *"Xóa truyện"*, *"Thêm chương"*, *"Duyệt bài"*.
- Mọi API gọi từ app mobile liên quan đến Series đều chỉ sử dụng các phương thức xem (`GET /api/series`, `GET /api/series/{id}`). Nếu có bất kỳ hành vi bất thường nào cố tình gọi endpoint thay đổi dữ liệu tác phẩm, Gateway trả về `403 Forbidden` và app sẽ thông báo thân thiện: *"Bạn không có quyền thực hiện thao tác này"*.

### 4.2. Quy tắc quản lý phiên làm việc & Xác thực (Session & Auth)
- Độc giả có thể duyệt xem danh sách truyện công khai mà chưa cần đăng nhập.
- Khi người dùng muốn thực hiện hành động cá nhân hóa (Thêm truyện vào tủ sách cá nhân, Đồng bộ lịch sử đọc lên server):
  - Nếu chưa đăng nhập: Ứng dụng hiển thị thông báo nhẹ hoặc chuyển hướng đến màn hình `/sign-in`.
  - Sau khi đăng nhập thành công: `accessToken` được lưu an toàn vào `FlutterSecureStorage` và tự động đính kèm vào header `Authorization: Bearer <token>` cho mọi request sau đó.
- Khi phiên đăng nhập hết hạn (Backend/Gateway trả về `HTTP 401`):
  - Tự động xóa token đã lưu.
  - Chuyển hướng người dùng về màn hình `/sign-in`.
  - Hiển thị duy nhất **1 thông báo**: *"Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."* (ngăn chặn tình trạng nhiều request cùng bị 401 gây chồng chéo thông báo).

### 4.3. Quy tắc Trải nghiệm Tủ sách (Optimistic UI & Rollback)
- Khi độc giả bấm nút **Bookmark (Thêm vào tủ sách)** hoặc **Thích truyện**:
  1. Giao diện lập tức đổi màu/trạng thái icon đã lưu (tạo phản hồi tức thì, không bắt người dùng chờ mạng).
  2. Bắn request ngầm lên Gateway.
  3. Nếu gặp sự cố mạng hoặc API lỗi: Hoàn tác (rollback) trạng thái icon về như cũ và hiển thị thông báo SnackBar: *"Không thể lưu vào tủ sách. Vui lòng thử lại sau."*

### 4.4. Quy tắc Chống Spam tương tác & Debounce tìm kiếm
- Nút gửi form (Đăng nhập, Đăng ký): Tự động khóa bấm (`onPressed: null`) và hiện spinner xoay tròn khi đang xử lý, ngăn chặn việc bấm liên tiếp nhiều lần gây duplicate request.
- Ô tìm kiếm truyện: Áp dụng cơ chế **Debounce 400ms**. Chỉ khi người dùng ngừng gõ phím sau 400ms mới kích hoạt tìm kiếm, tránh gửi request dồn dập lên Gateway.

### 4.5. Quy tắc Đọc Offline & Lưu trữ cục bộ (Offline-First for Reading)
- Mỗi khi độc giả mở đọc một chương, thông tin chương và vị trí đọc dở dang được lưu tự động vào `SharedPreferences` hoặc SQLite cục bộ.
- Khi mất kết nối mạng, độc giả vẫn có thể mở lại mục **"Lịch sử đọc gần đây"** để xem lại danh sách truyện đã đọc và nội dung chương đã được lưu trong bộ nhớ đệm.
