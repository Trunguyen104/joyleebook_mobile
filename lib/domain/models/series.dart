import 'package:flutter/foundation.dart';
import '../../data/dtos/series_dto.dart';

/// Enum đại diện cho trạng thái của bộ truyện
/// Giúp code dễ đọc hơn thay vì dùng số 0 hoặc 1
enum SeriesStatus {
  completed, // Đã hoàn thành (tương ứng với số 0 trên backend)
  ongoing;   // Đang tiến hành (tương ứng với số 1 trên backend)

  /// Hàm tiện ích chuyển đổi từ số nguyên sang Enum
  static SeriesStatus fromInt(int value) =>
      value == 0 ? SeriesStatus.completed : SeriesStatus.ongoing;

  /// Nhãn hiển thị tiếng Việt trên giao diện
  String get label => switch (this) {
        SeriesStatus.completed => 'Hoàn thành',
        SeriesStatus.ongoing => 'Đang tiến hành',
      };
}

/// PURE DOMAIN MODEL - Thực thể nghiệp vụ thuần túy
/// Bước 2 trong kiến trúc Compass App:
/// Lớp này là đối tượng "sạch" mà giao diện và logic của app sẽ dùng trực tiếp.
/// 
/// NGUYÊN TẮC VÀNG CHO NGƯỜI MỚI HỌC:
/// 1. Tuyệt đối không import thư viện 'flutter/material.dart' hay 'dio' vào đây.
/// 2. Thuộc tính phải là final và bất biến (@immutable) để dữ liệu không bị sửa lung tung.
/// 3. Không để lộ các chi tiết vụn vặt của DTO lên UI.
@immutable
class Series {
  final String id;              // Mã truyện
  final String title;           // Tên truyện
  final String authorName;      // Tên tác giả
  final String description;     // Tóm tắt nội dung
  final String coverImageUrl;   // Đường dẫn ảnh bìa
  final SeriesStatus status;    // Trạng thái (Hoàn thành / Đang ra)
  final List<String> genres;    // Danh sách thể loại
  final bool isBookmarked;      // Đã thêm vào tủ sách hay chưa (thuộc tính của app mobile)
  final int totalChapters;      // Tổng số chương của bộ truyện

  const Series({
    required this.id,
    required this.title,
    required this.authorName,
    required this.description,
    required this.coverImageUrl,
    required this.status,
    this.genres = const [],
    this.isBookmarked = false,
    this.totalChapters = 0,
  });

  /// Hàm chuyển đổi từ DTO (Data Layer) sang Domain Model (Domain Layer)
  /// Giúp chuẩn hóa các trường null thành chuỗi hiển thị mặc định đẹp mắt
  factory Series.fromDto(SeriesDto dto, {bool isBookmarked = false}) {
    return Series(
      id: dto.id,
      title: dto.title,
      authorName: dto.authorName,
      description: (dto.description != null && dto.description!.trim().isNotEmpty)
          ? dto.description!
          : 'Chưa có tóm tắt cho tác phẩm này.',
      coverImageUrl: dto.coverImageUrl ?? '',
      status: SeriesStatus.fromInt(dto.status),
      genres: dto.genreNames,
      isBookmarked: isBookmarked,
      totalChapters: dto.totalChapters,
    );
  }

  /// Hàm copyWith: Tạo bản sao mới với một vài thuộc tính thay đổi
  /// Rất hữu ích khi muốn đổi trạng thái isBookmarked (Optimistic UI) mà không làm thay đổi các trường khác
  Series copyWith({
    bool? isBookmarked,
    int? totalChapters,
  }) {
    return Series(
      id: id,
      title: title,
      authorName: authorName,
      description: description,
      coverImageUrl: coverImageUrl,
      status: status,
      genres: genres,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      totalChapters: totalChapters ?? this.totalChapters,
    );
  }

  /// So sánh hai đối tượng Series theo ID (dùng cho việc tìm kiếm hoặc kiểm thử)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Series && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
