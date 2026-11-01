/// Kiểm tra dữ liệu form xác thực (khớp với quy tắc của backend).
/// Trả về null nếu hợp lệ, ngược lại trả về câu báo lỗi tiếng Việt.
library;

final _usernamePattern = RegExp(r'^[A-Za-z0-9._-]+$');
final _hasLetter = RegExp(r'[A-Za-z]');
final _hasDigit = RegExp(r'[0-9]');

/// Dùng cho checklist mật khẩu hiển thị trực tiếp trên form đăng ký
bool passwordHasMinLength(String value) => value.length >= 8;
bool passwordHasLetter(String value) => _hasLetter.hasMatch(value);
bool passwordHasDigit(String value) => _hasDigit.hasMatch(value);

/// Tên đăng nhập: 3-64 ký tự, chỉ gồm chữ, số, dấu . _ -
String? validateUsername(String value) {
  final username = value.trim();
  if (username.isEmpty) return 'Vui lòng nhập tên đăng nhập';
  if (username.length < 3 ||
      username.length > 64 ||
      !_usernamePattern.hasMatch(username)) {
    return 'Tên đăng nhập từ 3-64 ký tự và không chứa ký tự đặc biệt';
  }
  return null;
}

/// Mật khẩu: 8-128 ký tự, có ít nhất 1 chữ cái và 1 chữ số
String? validatePassword(String value) {
  if (value.isEmpty) return 'Vui lòng nhập mật khẩu';
  if (!passwordHasMinLength(value) ||
      value.length > 128 ||
      !passwordHasLetter(value) ||
      !passwordHasDigit(value)) {
    return 'Mật khẩu tối thiểu 8 ký tự, bao gồm cả chữ và số';
  }
  return null;
}

String? validateConfirmPassword(String password, String confirmPassword) {
  if (confirmPassword.isEmpty) return 'Vui lòng nhập lại mật khẩu';
  if (confirmPassword != password) return 'Mật khẩu xác nhận không trùng khớp';
  return null;
}

/// Form đăng nhập chỉ cần không bỏ trống
/// (backend cho đăng nhập bằng cả email nên không áp quy tắc tên đăng nhập)
String? validateRequired(String value, String message) =>
    value.trim().isEmpty ? message : null;
