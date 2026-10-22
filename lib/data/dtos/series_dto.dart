import 'package:flutter/foundation.dart';

/// DTO (Data Transfer Object) - Đối tượng truyền dữ liệu
/// Bước 1 trong kiến trúc Compass App:
/// Lớp này ánh xạ CHÍNH XÁC cấu trúc JSON trả về từ JoyleeBook API Gateway (/api/series).
/// Mục đích: Parse dữ liệu thô từ `Map<String, dynamic>` và xử lý an toàn kiểu dữ liệu (null-safety).
@immutable
class SeriesDto {
  // Mã định danh truyện (Backend trả về UUID string, ví dụ: 11111111-1111-...)
  final String id;

  // Tiêu đề truyện
  final String title;

  // Mã tác giả
  final String authorId;

  // Tên tác giả (Backend có thể chưa trả, ta cung cấp giá trị mặc định)
  final String authorName;

  // Tóm tắt nội dung truyện (có thể null nếu tác giả chưa nhập)
  final String? description;

  // Đường link ảnh bìa truyện
  final String? coverImageUrl;

  // Trạng thái: 0 = Hoàn thành (Completed), 1 = Đang tiến hành (Ongoing)
  final int status;

  // Cờ xuất bản công khai
  final bool isPublish;

  // Danh sách tên các thể loại truyện (Hành Động, Phiêu Lưu...)
  final List<String> genreNames;

  // Tổng số chương (nếu API trả về)
  final int totalChapters;

  const SeriesDto({
    required this.id,
    required this.title,
    required this.authorId,
    required this.authorName,
    this.description,
    this.coverImageUrl,
    required this.status,
    this.isPublish = true,
    this.genreNames = const [],
    this.totalChapters = 0,
  });

  /// Hàm khởi tạo từ Map JSON nhận từ API
  /// Xử lý cẩn thận từng trường để tránh lỗi sập app (Crash) do lệch kiểu dữ liệu
  factory SeriesDto.fromJson(Map<String, dynamic> json) {
    // 1. Trích xuất danh sách thể loại từ mảng "genres" (nếu có)
    final rawGenres = json['genres'] as List<dynamic>? ?? [];
    final parsedGenres = rawGenres
        .map((g) => (g is Map<String, dynamic>) ? (g['name'] as String? ?? '') : '')
        .where((name) => name.isNotEmpty)
        .toList();

    return SeriesDto(
      // Lấy id: Chuyển về dạng String để hỗ trợ cả Guid lẫn số nguyên
      id: json['id']?.toString() ?? '',

      // Lấy title: Nếu null hoặc rỗng thì ghi "Chưa có tiêu đề"
      title: json['title'] as String? ?? 'Chưa có tiêu đề',

      // Lấy authorId
      authorId: json['authorId']?.toString() ?? '',

      // Lấy authorName: Nếu backend chưa trả tên thì đặt mặc định
      authorName: json['authorName'] as String? ?? 'Tác giả JoyleeBook',

      // Lấy mô tả
      description: json['description'] as String?,

      // Lấy ảnh bìa: Hỗ trợ cả 2 tên trường coverImageUrl hoặc coverUrl
      coverImageUrl: (json['coverImageUrl'] ?? json['coverUrl']) as String?,

      // Lấy trạng thái truyện (0 hoặc 1, mặc định 1 = Ongoing)
      status: json['status'] as int? ?? 1,

      // Cờ xuất bản
      isPublish: json['isPublish'] as bool? ?? true,

      // Danh sách thể loại
      genreNames: parsedGenres,

      // Tổng số chương
      totalChapters: json['totalChapters'] as int? ?? 0,
    );
  }

  /// Chuyển ngược lại DTO thành Map JSON (nếu cần gửi dữ liệu lên server)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'authorId': authorId,
      'authorName': authorName,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'status': status,
      'isPublish': isPublish,
      'totalChapters': totalChapters,
    };
  }
}
