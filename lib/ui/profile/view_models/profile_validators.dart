/// Kiểm tra dữ liệu form chỉnh sửa hồ sơ.
/// Trả về null nếu hợp lệ, ngược lại trả về câu báo lỗi tiếng Việt.
library;

/// Tên hiển thị: được để trống (dùng username), tối đa 64 ký tự.
String? validateDisplayName(String value) {
  if (value.trim().length > 64) {
    return 'Tên hiển thị tối đa 64 ký tự';
  }
  return null;
}

/// Giới thiệu: được để trống, tối đa 500 ký tự.
String? validateBio(String value) {
  if (value.trim().length > 500) {
    return 'Giới thiệu tối đa 500 ký tự';
  }
  return null;
}

/// Ảnh đại diện: tối đa 2MB, đúng định dạng đã được ImagePickerService chuẩn hóa.
const int maxAvatarSizeBytes = 2 * 1024 * 1024;

String? validateAvatarSize(int byteLength) {
  if (byteLength <= 0) {
    return 'Ảnh đã chọn không hợp lệ.';
  }
  if (byteLength > maxAvatarSizeBytes) {
    return 'Ảnh đại diện tối đa 2MB. Vui lòng chọn ảnh nhỏ hơn.';
  }
  return null;
}
