abstract final class Environment {
  /// Base URL được truyền qua `--dart-define=API_BASE_URL` lúc build (tùy chọn)
  static const String definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Gateway dùng chung đã deploy (HTTPS) — dự án không chạy backend local
  static const String hostedBaseUrl = 'https://api.joyleebook.duckdns.org';

  /// URL mặc định: ưu tiên `--dart-define`, nếu không có thì dùng Gateway đã deploy
  static String get defaultBaseUrl =>
      definedBaseUrl.isNotEmpty ? definedBaseUrl : hostedBaseUrl;

  static Uri parseUri(String url) {
    var cleaned = url.trim();
    // Bỏ dấu "/" cuối để không bị "//" khi ghép với ApiEndpoints
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    // Gateway chỉ phục vụ HTTPS nên mặc định thêm https:// khi thiếu scheme
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'https://$cleaned';
    }
    return Uri.parse(cleaned);
  }
}
