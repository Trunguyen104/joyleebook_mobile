/// Tiện ích chuẩn hóa và so khớp tìm kiếm tiếng Việt (SearchUtils)
/// Hỗ trợ tìm kiếm thông minh:
/// 1. Bỏ dấu tiếng Việt (Accent-insensitive): "hoi uc" -> "Hồi Ức Người Lữ Khách"
/// 2. Hỗ trợ cả 2 bảng mã Unicode: Dựng sẵn (NFC) & Tổ hợp (NFD - gõ từ bàn phím iOS/macOS/UniKey)
/// 3. Bỏ qua dấu ba chấm, dấu chấm cuối từ (...), khoảng trắng thừa
/// 4. So khớp đa từ (Multi-word): Tìm theo từng cụm từ không phân biệt thứ tự
class SearchUtils {
  SearchUtils._();

  /// Chuẩn hóa chuỗi tiếng Việt thành chữ thường không dấu
  static String removeDiacritics(String str) {
    var result = str.toLowerCase();

    // 1. Loại bỏ các ký tự dấu tổ hợp Unicode NFD (combining diacritical marks)
    result = result.replaceAll(
      RegExp(r'[\u0300\u0301\u0303\u0309\u0323\u0302\u0306\u031B]'),
      '',
    );

    // 2. Chuyển đổi các ký tự có dấu dựng sẵn (NFC) thành ký tự không dấu
    const vietnameseMap = {
      'a': 'á|à|ả|ã|ạ|ă|ắ|ằ|ẳ|ẵ|ặ|â|ấ|ầ|ẩ|ẫ|ậ',
      'd': 'đ',
      'e': 'é|è|ẻ|ẽ|ẹ|ê|ế|ề|ể|ễ|ệ',
      'i': 'í|ì|ỉ|ĩ|ị',
      'o': 'ó|ò|ỏ|õ|ọ|ô|ố|ồ|ổ|ỗ|ộ|ơ|ớ|ờ|ở|ỡ|ợ',
      'u': 'ú|ù|ủ|ũ|ụ|ư|ứ|ừ|ử|ữ|ự',
      'y': 'ý|ỳ|ỷ|ỹ|ỵ',
    };

    for (final entry in vietnameseMap.entries) {
      result = result.replaceAll(RegExp(entry.value), entry.key);
    }

    return result;
  }

  /// Làm sạch từ khóa tìm kiếm: loại bỏ khoảng trắng thừa, dấu ba chấm, dấu câu
  static String cleanQuery(String query) {
    return query
        .replaceAll(RegExp(r'[.\s]+$'), '')
        .replaceAll(RegExp(r'^[.\s]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Kiểm tra xem [target] có khớp với từ khóa [query] hay không
  static bool matches(String? target, String? query) {
    if (query == null) return true;
    final cleaned = cleanQuery(query);
    if (cleaned.isEmpty) return true;
    if (target == null || target.trim().isEmpty) return false;

    final targetLower = target.toLowerCase();
    final queryLower = cleaned.toLowerCase();

    // A. So khớp chuỗi con trực tiếp (NFC với NFC)
    if (targetLower.contains(queryLower)) return true;

    // B. So khớp không dấu (NFD, không dấu, telex)
    final normalizedTarget = removeDiacritics(targetLower);
    final normalizedQuery = removeDiacritics(queryLower);

    if (normalizedTarget.contains(normalizedQuery)) return true;

    // C. So khớp theo từng từ đơn (Multi-word: người dùng gõ đảo từ hoặc nhiều từ khóa)
    final words = normalizedQuery
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList(growable: false);

    if (words.isNotEmpty &&
        words.every((word) => normalizedTarget.contains(word))) {
      return true;
    }

    return false;
  }
}
