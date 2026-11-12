/// Gateway phải là địa chỉ HTTPS gốc, không chứa thông tin đăng nhập.
String? validateGatewayUrl(String value) {
  final url = value.trim();
  if (url.isEmpty) return 'Vui lòng nhập địa chỉ Gateway';
  final uri = Uri.tryParse(url);
  if (RegExp(r'\s').hasMatch(url) ||
      uri == null ||
      uri.scheme != 'https' ||
      !uri.hasAuthority ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      (uri.path.isNotEmpty && uri.path != '/')) {
    return 'Nhập URL gốc HTTPS hợp lệ, không kèm đường dẫn, tham số hoặc tài khoản';
  }
  try {
    if (uri.port < 1 || uri.port > 65535) {
      return 'Cổng Gateway phải từ 1 đến 65535';
    }
  } on FormatException {
    return 'Cổng Gateway không hợp lệ';
  }
  return null;
}
