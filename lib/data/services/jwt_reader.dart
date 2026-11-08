import 'dart:convert';

/// Đọc phần payload (claims) của JWT. Không kiểm tra chữ ký —
/// việc đó là của Gateway; app chỉ cần biết id, tên và vai trò.
/// Token hỏng thì trả về Map rỗng thay vì ném lỗi.
Map<String, dynamic> readJwtClaims(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return const {};
  try {
    // base64url có thể thiếu dấu "=" ở cuối, normalize() tự bù lại
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final claims = jsonDecode(payload);
    return claims is Map<String, dynamic> ? claims : const {};
  } on FormatException {
    return const {};
  }
}
