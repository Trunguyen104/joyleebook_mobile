import 'package:dio/dio.dart';

import '../../config/api_endpoints.dart';
import '../dtos/auth_dto.dart';
import 'token_storage.dart';

/// Interceptor xác thực của Dio:
/// 1. Gắn `Authorization: Bearer <accessToken>` vào mọi request.
/// 2. Gặp 401 -> dùng refreshToken xin cặp token mới rồi gửi lại request.
/// 3. Refresh bị từ chối -> xóa token và báo "phiên hết hạn" qua [onSessionExpired].
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this._dio,
    required this._tokenStorage,
    required this._onSessionExpired,
  });

  /// Đặt vào `Options(extra: {AuthInterceptor.skipAuthRefresh: true})` cho các
  /// request mà 401 mang nghĩa khác "hết phiên" (sai mật khẩu, đăng xuất...).
  static const skipAuthRefresh = 'skipAuthRefresh';
  static const _retried = 'retried';

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final void Function() _onSessionExpired;

  /// Lần refresh đang chạy. Nhiều request cùng bị 401 sẽ chờ chung Future này,
  /// nên backend chỉ nhận đúng 1 lần gọi /refresh (dùng lại refreshToken cũ
  /// sẽ khiến backend thu hồi cả phiên).
  Future<bool>? _refreshing;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final sentHeader = options.headers['Authorization'];
    final canRefresh =
        err.response?.statusCode == 401 &&
        sentHeader != null &&
        options.extra[skipAuthRefresh] != true &&
        options.extra[_retried] != true;
    if (!canRefresh) return handler.next(err);

    // Request này gửi bằng token cũ nhưng một request khác đã refresh xong
    // -> không cần refresh nữa, gửi lại luôn với token mới.
    final currentToken = await _tokenStorage.readAccessToken();
    final alreadyRefreshed =
        currentToken != null && sentHeader != 'Bearer $currentToken';
    if (!alreadyRefreshed && !await _refreshOnce()) return handler.next(err);

    try {
      final newToken = await _tokenStorage.readAccessToken();
      options.headers['Authorization'] = 'Bearer $newToken';
      options.extra[_retried] = true; // chỉ gửi lại 1 lần, tránh vòng lặp
      handler.resolve(await _dio.fetch(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<bool> _refreshOnce() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<bool> _refresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _expireSession();
      return false;
    }

    // Dio "trần" (không interceptor) để lời gọi refresh không tự kích hoạt lại chính nó
    final refreshClient = Dio(_dio.options.copyWith())
      ..httpClientAdapter = _dio.httpClientAdapter;
    try {
      final response = await refreshClient.post<Map<String, dynamic>>(
        ApiEndpoints.authRefresh,
        data: {'refreshToken': refreshToken},
      );
      final dto = TokenResponseDto.fromJson(response.data ?? const {});
      if (!dto.isValid) {
        await _expireSession();
        return false;
      }
      await _tokenStorage.saveTokens(
        accessToken: dto.accessToken,
        refreshToken: dto.refreshToken,
      );
      return true;
    } on DioException catch (e) {
      // 400/401: refreshToken hết hạn hoặc đã bị thu hồi -> phiên kết thúc.
      // Lỗi mạng/timeout: giữ token, lần sau thử lại.
      final status = e.response?.statusCode;
      if (status == 400 || status == 401) await _expireSession();
      return false;
    }
  }

  Future<void> _expireSession() async {
    await _tokenStorage.clear();
    _onSessionExpired();
  }
}
