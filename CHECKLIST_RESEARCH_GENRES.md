# CHECKLIST KIỂM TRA CODE: FEATURE/RESEARCH-GENRES
### Dự án: JoyleeBook Mobile (Flutter — PRN232)

> **Nhánh kiểm tra:** `feature/research-genres`  
> **Người thực hiện:** Antigravity  
> **Người kiểm tra:** Reviewer / Team Lead  
> **Tài liệu quy chiếu:** `CHECKLIST_CODE_REVIEW.md`, `docs/Flutter-Mobile-Code-Rules.md`, `CLAUDE.md`, `docs/01-System-Scope-Reader.md`, `docs/03-System-Flows-And-Contracts.md`, `docs/Design-System.md`

---

## 📌 TỔNG QUAN KẾT QUẢ QUÉT TỰ ĐỘNG (AUTOMATED GATES)

| Công cụ | Lệnh thực thi | Kết quả | Ghi chú |
| :--- | :--- | :---: | :--- |
| **Đồng bộ thư viện** | `flutter pub get` | 🟢 **PASS** | Dependencies đồng bộ hoàn hảo, không xung đột gói. |
| **Phân tích tĩnh** | `dart analyze lib test` | 🟢 **PASS** | **No issues found!** 0 errors, 0 warnings, 0 info. |
| **Kiểm thử tự động** | `flutter test` | 🟢 **PASS** | **92/92 tests passed (100%)**, bao gồm 17 tests mới cho tính năng Research & Genres. |
| **Số files thay đổi** | `git status` | **10 files** | Thêm mới DTO, Domain Model, Repository, ViewModels, Widgets và Tests. |

---

## 📋 BẢNG CHECKLIST ĐÁNH GIÁ CHI TIẾT THEO BAREM PRN232

### 1. Kiến trúc Tầng & Mô hình Dữ liệu (Compass App Architecture - 15%)

- [x] **1.1. Data Layer — DTO (`lib/data/dtos/genre_dto.dart`)**
  - [x] Ánh xạ chuẩn xác JSON từ JoyleeBook Gateway (`GET /api/genres`).
  - [x] Null safety và Type Casting an toàn tuyệt đối: `json['id']?.toString() ?? ''`, `(json['seriesCount'] ?? json['totalSeries'] as num?)?.toInt() ?? 0`.
  - [x] Đầy đủ hàm `fromJson` và `toJson`.
  - [x] Tuyệt đối không dùng toán tử ép kiểu cưỡng bức `!`.

- [x] **1.2. Domain Layer — Pure Domain Model (`lib/domain/models/genre.dart`)**
  - [x] Pure Dart entity: Tuyệt đối không import `material.dart`, `dio.dart`, hay `riverpod`. Chỉ import `foundation.dart` cho `@immutable`.
  - [x] Bất biến (Immutability): Toàn bộ thuộc tính là `final`.
  - [x] Tự động chuẩn hóa chuỗi và trim khoảng trắng thừa: `dto.name.trim()`.
  - [x] Có hàm `copyWith()`, override `operator ==` và `hashCode`.

- [x] **1.3. Data Layer — Repository (`lib/data/repositories/genre_repository.dart` & `series_repository.dart`)**
  - [x] Đăng ký Riverpod Provider: `final genreRepositoryProvider = Provider<GenreRepository>(...)`.
  - [x] Bọc toàn bộ lệnh gọi Dio trong khối `try/catch`, bắt `DioException` và rethrow thành `AppException.fromDio(e)`.
  - [x] Mở rộng `SeriesRepository.getSeriesList` hỗ trợ đa tham số lọc: `{String? searchQuery, String? genre, SeriesStatus? status}` với cơ chế lọc dự phòng client-side.
  - [x] Cung cấp đầy đủ `FakeGenreRepository` và nâng cấp `FakeSeriesRepository` trong thư mục `testing/fakes/`.

- [x] **1.4. UI Layer — State Management (Riverpod ViewModels)**
  - [x] Tạo `GenreListViewModel` kế thừa `AsyncNotifier<List<Genre>>`, có hàm `refresh()` bọc trong `AsyncValue.guard`.
  - [x] Nâng cấp `SeriesListViewModel` quản lý toàn diện trạng thái tra cứu: `currentQuery`, `selectedGenre`, `selectedStatus`, `isFiltered`.
  - [x] Tích hợp cơ chế **Debounce 400ms** khi gõ bàn phím tìm kiếm (`Timer`).
  - [x] Cung cấp các phương thức nghiệp vụ: `filterByGenre()`, `filterByStatus()`, `clearFilters()`, `refresh()`.

---

### 2. Tiêu chuẩn Giao diện & Design System (UI/UX & Warm Editorial - 15%)

- [x] **2.1. Đầy đủ bộ 4 trạng thái bắt buộc (4 States Pattern)**
  - [x] **Loading State**: Hiển thị vòng xoay `CircularProgressIndicator` màu Plum chính giữa màn hình kèm nhãn tiếng Việt dịu mắt; các chip thể loại có skeleton placeholder `...`.
  - [x] **Empty State**: Khi bộ lọc hoặc từ khóa không khớp tác phẩm nào, hiển thị `JoyleeEmptyState` kèm câu thông báo lịch sự tiếng Việt và nút bấm hành động **"Xóa bộ lọc"**.
  - [x] **Error State**: Khi mất kết nối hoặc API Gateway lỗi, hiển thị `JoyleeErrorView` kèm thông điệp tiếng Việt thân thiện và nút **"Thử lại"**.
  - [x] **Data State**: Hiển thị danh sách thẻ truyện với banner thông báo kết quả lọc (`_buildActiveFiltersBanner`), bọc trong `RefreshIndicator` hỗ trợ kéo để làm mới.

- [x] **2.2. Modal Bottom Sheet "Tất cả Thể loại & Bộ lọc" (`GenreBottomSheet`)**
  - [x] Thiết kế theo chuẩn Design System: Bo góc trên `radiusLg`, có thanh gạt `drag handle` ở trên cùng.
  - [x] Hỗ trợ lọc trạng thái phát hành: "Tất cả trạng thái", "Đang tiến hành", "Hoàn thành".
  - [x] Danh mục thể loại đầy đủ 4 trạng thái (Loading, Data, Empty, Error).
  - [x] Touch target đạt chuẩn tối thiểu **48x48 dp** cho tất cả các nút bấm và chip lựa chọn.

- [x] **2.3. Chống tràn layout (No RenderFlex Overflow)**
  - [x] Toàn bộ form và thanh cuộn bọc trong `SingleChildScrollView` / `ListView.builder`.
  - [x] Văn bản dài có giới hạn `maxLines` và `overflow: TextOverflow.ellipsis`.

---

### 3. Logic Nghiệp vụ & Ràng buộc Dự án (Business Logic & Validation - 50% Trọng tâm)

- [x] **3.1. Phân quyền Reader (Role Authorization)**
  - [x] Chỉ cho phép người dùng xem (`GET /api/genres`, `GET /api/series`) và lọc tác phẩm.
  - [x] Tuyệt đối không xuất hiện các nút thêm, sửa, xóa thể loại hoặc tác phẩm trên giao diện di động.

- [x] **3.2. Debounce Tìm kiếm 400ms**
  - [x] Khi người dùng gõ từng ký tự liên tục trong ô tìm kiếm, timer cũ được reset. Sau khi ngừng gõ đủ 400ms mới kích hoạt tìm kiếm, ngăn chặn spam request lên Gateway.

- [x] **3.3. Cơ chế Cập nhật Lạc quan (Optimistic UI with Rollback)**
  - [x] Độc giả có thể lưu hoặc bỏ lưu truyện vào Tủ sách (Bookmark) ngay trên màn hình tra cứu.
  - [x] Đổi màu icon lập tức; nếu request API thất bại thì hoàn tác (rollback) trạng thái và thông báo nhẹ qua SnackBar.

- [x] **3.4. Liên kết Liền mạch từ Trang Chi tiết (`SeriesDetailScreen`)**
  - [x] Khi người dùng nhấn vào một Tag thể loại trên trang chi tiết tác phẩm, hệ thống kích hoạt `filterByGenre(genre)` và điều hướng người dùng quay lại trang Kho truyện với bộ lọc thể loại đã được chọn sẵn.

---

## 🧪 4. DANH SÁCH BỘ TEST ĐÃ KIỂM ĐỊNH (TEST RUN SUMMARY)

1. `test/data/genre_dto_and_model_test.dart` (6 tests):
   - Trích xuất JSON null-safety, type casting.
   - Map sang Pure Domain Model, copyWith, equality.
2. `test/data/series_filter_repository_test.dart` (5 tests):
   - Lọc theo từ khóa, thể loại, trạng thái phát hành.
   - Kết hợp đa tiêu chí (keyword + genre + status).
3. `test/ui/research_genres_screen_test.dart` (6 widget tests):
   - Render đầy đủ ô search, thanh genre chips, nút bộ lọc.
   - Nhấn chọn thể loại -> lọc đúng truyện.
   - Nhập từ khóa với Debounce 400ms.
   - Bộ lọc rỗng -> Empty state + nút Xóa bộ lọc khôi phục danh sách.
   - Mở Bottom Sheet xem toàn bộ thể loại và bộ lọc trạng thái.
   - Xử lý lỗi tải thể loại trong Bottom Sheet với nút Thử lại.
4. **Hệ thống toàn dự án:** **92/92 tests PASS (100%)**.
