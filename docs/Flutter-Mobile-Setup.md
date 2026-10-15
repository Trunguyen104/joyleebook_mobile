# Thiết lập Flutter Mobile cho JoyleeBook

Tài liệu này hướng dẫn tạo ứng dụng Flutter mobile mới, dùng kiến trúc hiện đại và gọi **qua JoyleeBook Gateway**. Phạm vi API đã có thể tích hợp ngay là Authentication và Series. Chapters, Library, Community, Notification hiện mới có health check; không xây màn hình nghiệp vụ dựa trên các API đó cho đến khi contract được bổ sung.

## 1. Nguyên tắc tích hợp

Luồng bắt buộc là:

```text
Flutter app -> JoyleeBook Gateway (https://api.joyleebook.duckdns.org) -> API service -> SQL Server
```

- Chỉ dùng base URL của Gateway; không gọi trực tiếp microservice, Docker DNS, hay SQL Server.
- Không tự gửi `X-User-Id`, `X-User-Role`, `X-User-Name`. Gateway loại bỏ các header này và chỉ tự forward danh tính sau khi kiểm JWT.
- Lưu access token trong secure storage, gửi bằng `Authorization: Bearer <token>` cho request cần đăng nhập.
- Không đưa `Jwt:Key`, SQL password hoặc nội dung `.env` backend vào Flutter. App mobile chỉ biết base URL công khai.
- Base URL mặc định là Gateway dùng chung `Environment.hostedBaseUrl` trong `lib/config/environment.dart`. Có thể ghi đè bằng `--dart-define=API_BASE_URL=...` khi cần trỏ sang Gateway khác; không hard-code URL ở bất kỳ nơi nào khác.

Dự án **không chạy backend local**. Toàn bộ thành viên dùng chung một Gateway đã deploy qua HTTPS:

| Thông tin | Giá trị |
| --- | --- |
| Gateway base URL | `https://api.joyleebook.duckdns.org` |
| Health check | `https://api.joyleebook.duckdns.org/health/live` |
| Swagger Authentication | `https://api.joyleebook.duckdns.org/docs/authentication/swagger/index.html` |
| Swagger Series | `https://api.joyleebook.duckdns.org/docs/series/swagger/index.html` |

`API_BASE_URL` chỉ là **gốc của Gateway**, không kèm `/api/...`. Các path như `/api/series` nằm trong `lib/config/api_endpoints.dart`. Vì Gateway là HTTPS công khai, cùng một URL chạy được trên Android emulator, iOS Simulator và thiết bị thật mà không cần cùng mạng LAN hay mở firewall.

## 2. Kiểm tra Gateway

Kiểm tra Gateway trước khi chạy Flutter:

```powershell
curl.exe -i https://api.joyleebook.duckdns.org/health/live
curl.exe -i https://api.joyleebook.duckdns.org/api/series
```

Kết quả health phải là `200`. `/api/series` phải đi qua Gateway; lỗi `502` thường nghĩa là Series API phía server chưa chạy/ready — báo người quản lý server thay vì tự chạy backend. Có thể mở cùng URL trên trình duyệt điện thoại để tự kiểm tra, hoặc dùng tab **Kiểm tra Gateway** trong app.

> Lưu ý CORS: mobile native không bị browser CORS, nhưng Flutter Web thì bị. Nếu phát triển Flutter Web, origin Flutter Web phải được thêm vào cấu hình CORS của Gateway đã deploy; không dùng `AllowAnyOrigin`.

## 3. Khởi tạo project và dependencies

Tạo project ở **ngoài** solution .NET (ví dụ thư mục đồng cấp), để mobile có vòng đời và pipeline riêng:

```powershell
flutter create --org com.joyleeBook joylee_book_mobile
cd joylee_book_mobile
```

Dependencies khuyến nghị:

```powershell
flutter pub add flutter_riverpod riverpod_annotation go_router dio flutter_secure_storage json_annotation
flutter pub add --dev build_runner riverpod_generator json_serializable
```

- `flutter_riverpod`: state management, dependency injection và test override rõ ràng.
- `go_router`: routing, redirect theo trạng thái đăng nhập.
- `dio`: HTTP client, timeout và interceptor token/refresh-ready.
- `flutter_secure_storage`: giữ token trong Keychain/EncryptedSharedPreferences.
- `json_serializable`: model typed, không parse JSON rải rác trong UI.

Nếu dùng code generation, chạy sau khi thêm các class `@JsonSerializable()` / `@riverpod`:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

## 4. Cấu trúc thư mục chuẩn (Flutter Compass App Architecture - Hybrid)

Cấu trúc mã nguồn áp dụng theo **hướng dẫn kiến trúc chính thức của Flutter (Compass App)** kết hợp thư viện `flutter_riverpod`. Mô hình này phối hợp điểm mạnh của cả hai phương pháp:
- **Tầng Data & Domain (Layer-First / By-Type)**: Repositories, Services, DTOs và Models được dùng chung cho toàn bộ ứng dụng (ví dụ: `Series` và `Auth` được gọi từ nhiều màn hình khác nhau như Home, Library, Reading, Profile). Gom nhóm theo loại giúp tránh việc các tính năng phụ thuộc chéo vào mã nguồn nội bộ của nhau.
- **Tầng UI (Feature-First)**: Mỗi màn hình/tính năng có thư mục riêng chứa `view_models/` (quản lý state/logic màn hình qua Riverpod) và `widgets/` (màn hình và component con). `ui/core/` chứa theme và widget dùng chung.
- **Entry points đa môi trường**: Phân tách file chạy cho Development, Staging và Production.
- **Tách biệt kiểm thử**: Thư mục `test/` chứa unit/widget test; thư mục `testing/` chứa mocks, fake data dùng chung.

```text
joylee_book_mobile/
├── lib/
│   ├── main.dart                      # Entry point Production
│   ├── main_development.dart          # Entry point Development (gọi Gateway dùng chung)
│   ├── main_staging.dart              # Entry point Staging
│   ├── app.dart                       # Root MaterialApp widget & global theme config
│   │
│   ├── config/                        # Cấu hình app, constants, environment
│   │   ├── environment.dart           # Gateway mặc định + ghi đè bằng --dart-define (API_BASE_URL)
│   │   └── api_endpoints.dart         # Hằng số URL: /api/auth, /api/series...
│   │
│   ├── routing/                       # Điều hướng GoRouter
│   │   ├── app_router.dart            # Cấu hình routes & auth redirects
│   │   └── routes.dart                # Tên / path enum của các màn hình
│   │
│   ├── domain/                        # Pure domain entities (Business models)
│   │   └── models/
│   │       ├── auth_session.dart
│   │       ├── series.dart
│   │       └── user_profile.dart
│   │
│   ├── data/                          # Data layer (Gom theo loại - by type)
│   │   ├── services/                  # Network & local storage thấp tầng
│   │   │   ├── api_client.dart        # Dio instance & Interceptors (Bearer token)
│   │   │   ├── token_storage.dart     # FlutterSecureStorage wrapper
│   │   │   └── api_exceptions.dart    # Mapping lỗi HTTP/Gateway thành lỗi app
│   │   ├── repositories/              # Repositories trung gian cấp dữ liệu cho UI
│   │   │   ├── auth_repository.dart
│   │   │   └── series_repository.dart
│   │   └── dtos/                      # Request / Response JSON serialization
│   │       ├── sign_in_request.dart
│   │       └── sign_in_response.dart
│   │
│   ├── ui/                            # UI Layer (Gom theo tính năng - by feature)
│   │   ├── core/                      # Reusable UI & Styling cho toàn ứng dụng
│   │   │   ├── themes/                # AppTheme, Colors, Typography (đồng bộ Web)
│   │   │   └── widgets/               # Nút bấm, loading, dialogs dùng chung
│   │   ├── auth/                      # Tính năng Auth
│   │   │   ├── view_models/           # Riverpod Notifier quản lý state form & session
│   │   │   │   └── sign_in_view_model.dart
│   │   │   └── widgets/               # Màn hình & giao diện
│   │   │       ├── sign_in_screen.dart
│   │   │       └── sign_up_screen.dart
│   │   ├── series/                    # Tính năng Series
│   │   │   ├── view_models/
│   │   │   │   ├── series_list_view_model.dart
│   │   │   │   └── series_detail_view_model.dart
│   │   │   └── widgets/
│   │   │       ├── series_list_screen.dart
│   │   │       ├── series_detail_screen.dart
│   │   │       └── series_card.dart
│   │   ├── library/                   # Tủ sách cá nhân (mở rộng sau)
│   │   └── reading/                   # Trình đọc chapter (mở rộng sau)
│   │
│   └── utils/                         # Helper functions, formatters (date, string)
│
├── test/                              # Unit test & Widget test theo tầng
│   ├── data/                          # Test repository, api client
│   ├── domain/                        # Test logic domain models
│   └── ui/                            # Test view models và widget screens
│
└── testing/                           # Fakes & Mocks dùng chung
    ├── fakes/                         # FakeAuthRepository, FakeTokenStorage
    └── fixtures/                      # Mock JSON response mẫu
```

Quy tắc phụ thuộc dữ liệu: `UI (Widgets) -> ViewModels (Riverpod) -> Repositories -> Data Services (Dio/Storage) -> Gateway`. Widgets không bao giờ gọi trực tiếp `Dio`; Repositories là nơi duy nhất chuyển đổi DTO sang Domain Models cho ViewModels tiêu thụ.

## 5. Environment và HTTP client

Tạo `lib/config/environment.dart`:

```dart
abstract final class Environment {
  static const String definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Gateway dùng chung đã deploy (HTTPS)
  static const String hostedBaseUrl = 'https://api.joyleebook.duckdns.org';

  static String get defaultBaseUrl =>
      definedBaseUrl.isNotEmpty ? definedBaseUrl : hostedBaseUrl;
}
```

Tạo `lib/data/services/token_storage.dart` và `lib/data/services/api_client.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _key = 'access_token';
  final FlutterSecureStorage _storage;
  const TokenStorage(this._storage);

  Future<String?> read() => _storage.read(key: _key);
  Future<void> save(String value) => _storage.write(key: _key, value: value);
  Future<void> clear() => _storage.delete(key: _key);
}

Dio createApiClient(TokenStorage tokenStorage, Uri baseUri) {
  final dio = Dio(BaseOptions(
    baseUrl: baseUri.toString(),
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    headers: const {'Accept': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await tokenStorage.read();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
  ));
  return dio;
}
```

Tạo entry point môi trường dev `lib/main_development.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: JoyleeBookApp(),
    ),
  );
}
```

Chạy ứng dụng (mọi emulator/simulator/thiết bị thật đều dùng cùng lệnh):

```powershell
flutter run -t lib/main_development.dart
```

Chỉ khi cần trỏ sang một Gateway khác (ví dụ môi trường staging), truyền `--dart-define`:

```powershell
flutter run -t lib/main_development.dart --dart-define=API_BASE_URL=https://<gateway-khac>
```

## 6. Kết nối HTTPS

Gateway chỉ phục vụ HTTPS (request `http://` được chuyển hướng `308` sang `https://`), nên app **không** cần bật clear-text HTTP:

- Android: không đặt `android:usesCleartextTraffic="true"` trong bất kỳ `AndroidManifest.xml` nào. `src/main/AndroidManifest.xml` chỉ cần quyền `INTERNET`.
- iOS: không thêm ATS exception hay `NSAllowsArbitraryLoads`.
- Không bypass TLS (ví dụ `badCertificateCallback` trả về `true`) để "chữa cháy" lỗi chứng chỉ.

## 7. Contract API hiện tại

Các property JSON từ ASP.NET Core dùng camelCase. Các route dưới đây đều đi qua Gateway.

| Mục đích | Method + path | Auth |
| --- | --- | --- |
| Đăng ký | `POST /api/auth/sign-up` | Public |
| Đăng nhập | `POST /api/auth/sign-in` | Public |
| Đăng xuất token hiện tại | `POST /api/auth/sign-out` | Bearer token |
| Danh sách Series | `GET /api/series` | Public (Admin có thể thấy thêm dữ liệu) |
| Chi tiết Series | `GET /api/series/{id}` | Public nếu nội dung visible |
| Series của author | `GET /api/series/author/{authorId}` | Author/Admin, token |
| Tạo Series | `POST /api/series` | Author/Admin, token |
| Cập nhật/xóa Series | `PUT` / `DELETE /api/series/{id}` | Author sở hữu hoặc Admin |

Ví dụ đăng nhập:

```http
POST /api/auth/sign-in
Content-Type: application/json

{"username":"demo.reader","password":"<mật-khẩu-demo>"}
```

Response thành công có dạng:

```json
{
  "accessToken": "eyJ...",
  "tokenType": "Bearer",
  "expiresAtUtc": "2026-10-01T...Z"
}
```

Lưu `accessToken`; không cần tự tạo `X-User-*`. Khi nhận `401`, xóa token và đưa người dùng về Sign in. Khi nhận `403`, giữ session nhưng hiển thị lỗi không có quyền. `429` có thể xuất hiện ở sign-up (Gateway giới hạn 30 request/phút); hãy hiển thị thông báo thử lại, không retry tự động dồn dập.

`POST /api/series` nhận `authorId` theo DTO hiện tại, nhưng controller ghi đè giá trị này bằng user ID rút từ token. Mobile nên gửi `authorId` là ID của session nếu đã decode/biết được, nhưng **không** coi đó là cơ chế phân quyền. Enum `status` hiện được ASP.NET Core serialize/deserialize dạng số: `0` = `Completed`, `1` = `Ongoing`.

## 8. Repositories và ViewModels mẫu

Theo kiến trúc Compass App, các Repositories nằm trong `lib/data/repositories/` và được expose qua Riverpod Provider. Repositories đảm nhiệm việc gọi HTTP qua `Dio`, xử lý DTO và trả về Domain Model an toàn:

### Repository (`lib/data/repositories/auth_repository.dart` & `series_repository.dart`)

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/series.dart';
import '../dtos/sign_in_request.dart';
import '../dtos/sign_in_response.dart';
import '../services/api_client.dart';
import '../services/token_storage.dart';

class AuthRepository {
  AuthRepository(this._dio, this._tokenStorage);
  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<SignInResponse> signIn(String username, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/sign-in',
      data: SignInRequest(username: username, password: password).toJson(),
    );
    final result = SignInResponse.fromJson(response.data!);
    await _tokenStorage.save(result.accessToken);
    return result;
  }

  Future<void> signOut() async {
    try {
      await _dio.post<void>('/api/auth/sign-out');
    } catch (_) {
      // Best-effort: kể cả mất mạng vẫn xóa token cục bộ
    } finally {
      await _tokenStorage.clear();
    }
  }
}

class SeriesRepository {
  SeriesRepository(this._dio);
  final Dio _dio;

  Future<List<Series>> getAllSeries() async {
    final response = await _dio.get<List<dynamic>>('/api/series');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(Series.fromJson)
        .toList(growable: false);
  }

  Future<Series> getSeriesById(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/api/series/$id');
    return Series.fromJson(response.data!);
  }
}

// Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthRepository(dio, tokenStorage);
});

final seriesRepositoryProvider = Provider<SeriesRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return SeriesRepository(dio);
});
```

### ViewModel (`lib/ui/series/view_models/series_list_view_model.dart`)

ViewModel ở tầng UI chỉ lắng nghe Repository và quản lý state cho màn hình:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/series_repository.dart';
import '../../../domain/models/series.dart';

final seriesListViewModelProvider =
    AsyncNotifierProvider<SeriesListViewModel, List<Series>>(
  SeriesListViewModel.new,
);

class SeriesListViewModel extends AsyncNotifier<List<Series>> {
  @override
  Future<List<Series>> build() {
    return ref.watch(seriesRepositoryProvider).getAllSeries();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(seriesRepositoryProvider).getAllSeries(),
    );
  }
}
```

## 9. Routing, UX và kiểm thử

- **Routing (`lib/routing/app_router.dart`)**: Dùng `GoRouter` redirect theo trạng thái session token: chưa có token buộc về `/sign-in`; đã có token không cho vào lại màn auth.
- **Async UI**: Sử dụng `AsyncValue.when(data: ..., loading: ..., error: ...)` trong widgets để giao diện luôn có đủ trạng thái loading, lỗi và dữ liệu rỗng.
- **Form validation**: Username 3–64 ký tự; password 8–128; kiểm tra client-side để phản hồi nhanh, backend Gateway/API luôn giữ quyền quyết định cuối cùng.
- **Tổ chức kiểm thử (`test/` và `testing/`)**:
  - `testing/fakes/fake_series_repository.dart`: Tạo class giả lập `implements SeriesRepository` trả về dữ liệu mẫu trong RAM.
  - Trong Widget Test hoặc Unit Test, chỉ cần ghi đè provider:
    ```dart
    final container = ProviderContainer(
      overrides: [
        seriesRepositoryProvider.overrideWithValue(FakeSeriesRepository()),
      ],
    );
    ```
    Cách này giúp test UI chạy nhanh, độc lập hoàn toàn với backend server và không phụ thuộc kết nối mạng.
  - Integration test luồng end-to-end `sign-in -> GET /api/series -> sign-out` trực tiếp qua Gateway dùng chung trước khi đóng gói release.

Checklist trước khi merge mobile:

1. App gọi duy nhất `API_BASE_URL` Gateway.
2. Không có secret/token/password trong source, log, snapshot hoặc analytics.
3. Không bật clear-text HTTP hay bypass TLS; mọi request đi qua HTTPS.
4. `401`, `403`, `429`, timeout, `502`, `503` đều có trạng thái UI dễ hiểu.
5. Test trên Android emulator và ít nhất một thiết bị thật (4G/Wi-Fi bất kỳ).
6. Đối chiếu Swagger tại `https://api.joyleebook.duckdns.org/docs/authentication/swagger/index.html` và `https://api.joyleebook.duckdns.org/docs/series/swagger/index.html` trước khi mở rộng contract.

## 10. Các việc nên thống nhất trước production

- Quy định versioning API và error envelope thống nhất trước khi nhiều feature mobile cùng phát triển.
- Cân nhắc refresh token/rotation, device session và cơ chế revoke phù hợp UX mobile nếu cần session dài.
- Hoàn thiện ranh giới trusted Gateway-to-service của Series trước khi coi xác thực end-to-end là hoàn chỉnh. Đây là vấn đề backend đã được ghi nhận, không được giải quyết bằng cách mobile gửi thêm header.
