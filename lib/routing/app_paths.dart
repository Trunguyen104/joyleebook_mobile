/// ĐƯỜNG DẪN CÁC TRANG TRONG APP
/// Màn hình dùng các hằng/hàm ở đây thay vì tự gõ chuỗi URL,
/// nên khi đổi đường dẫn chỉ cần sửa 1 chỗ.
abstract final class AppPaths {
  // Các tab chính trên NavigationBar
  static const series = '/series';
  static const search = '/search';
  static const bookmarks = '/bookmarks';
  static const profile = '/profile';
  static const gateway = '/gateway';

  // Xác thực (mở toàn màn hình, không có thanh tab)
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';

  /// Chi tiết một bộ truyện: /series/:seriesId
  static String seriesDetail(String seriesId) => '$series/$seriesId';

  /// Danh sách chương của bộ truyện: /series/:seriesId/chapters
  static String chapterList(String seriesId) =>
      '${seriesDetail(seriesId)}/chapters';

  /// Trang đọc một chương: /series/:seriesId/chapters/:chapterId
  static String chapterReader(String seriesId, String chapterId) =>
      '${chapterList(seriesId)}/$chapterId';
}
