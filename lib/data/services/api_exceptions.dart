import 'package:dio/dio.dart';

/// Lớp ngoại lệ chuẩn của toàn ứng dụng JoyleeBook Mobile
/// Mục đích: Bọc các lỗi kỹ thuật thô thành thông báo tiếng Việt thân thiện,
/// giúp người dùng không nhìn thấy các dòng mã lỗi khó hiểu hay crash app.
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({
    required this.message,
    this.statusCode,
  });

  /// Hàm tiện ích: Chuyển đổi mã lỗi từ thư viện Dio thành AppException tiếng Việt
  factory AppException.fromDio(DioException error) {
    switch (error.type) {
      // 1. Quá hạn kết nối mạng
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppException(
          message: 'Kết nối mạng quá hạn. Vui lòng kiểm tra đường truyền và thử lại.',
        );

      // 2. Không thể kết nối tới máy chủ (chưa bật Gateway hoặc mất mạng)
      case DioExceptionType.connectionError:
        return const AppException(
          message: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng hoặc Gateway.',
        );

      // 3. Máy chủ có phản hồi mã HTTP lỗi (400, 401, 404, 500, 502...)
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        switch (status) {
          case 400:
            return AppException(
              message: 'Dữ liệu gửi lên không hợp lệ.',
              statusCode: status,
            );
          case 401:
            return AppException(
              message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
              statusCode: status,
            );
          case 403:
            return AppException(
              message: 'Bạn không có quyền thực hiện hành động này.',
              statusCode: status,
            );
          case 404:
            return AppException(
              message: 'Không tìm thấy dữ liệu tác phẩm yêu cầu.',
              statusCode: status,
            );
          case 502:
            return AppException(
              message: 'Máy chủ Gateway đang chạy nhưng dịch vụ truyện chưa được bật (HTTP 502).',
              statusCode: status,
            );
          case 500:
          case 503:
            return AppException(
              message: 'Máy chủ đang bận hoặc gặp sự cố nội bộ. Vui lòng thử lại sau.',
              statusCode: status,
            );
          default:
            return AppException(
              message: 'Lỗi máy chủ ($status): ${error.response?.statusMessage ?? "Không rõ"}',
              statusCode: status,
            );
        }

      // 4. Các lỗi khác (hủy request, SSL...)
      default:
        return AppException(
          message: error.message ?? 'Đã xảy ra sự cố kết nối không xác định.',
        );
    }
  }

  @override
  String toString() => message;
}
