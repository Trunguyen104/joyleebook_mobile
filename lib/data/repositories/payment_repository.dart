import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_endpoints.dart';
import '../../domain/models/deposit_order.dart';
import '../../domain/models/donation.dart';
import '../../domain/models/wallet.dart';
import '../dtos/payment_dto.dart';
import '../services/api_client.dart';
import '../services/api_exceptions.dart';

/// RIVERPOD PROVIDER: Cung cấp PaymentRepository cho các ViewModel
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return PaymentRepository(dio);
});

/// REPOSITORY - Giao tiếp với JoyleeBook PaymentService qua Gateway
class PaymentRepository {
  final Dio _dio;

  PaymentRepository(this._dio);

  /// 1. Lấy thông tin ví Xu hiện tại của người dùng (tự khởi tạo nếu chưa có)
  Future<Wallet> getWallet() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.paymentsWallet,
      );
      final data = response.data;
      if (data == null) {
        throw const AppException(message: 'Không nhận được dữ liệu ví.');
      }
      return WalletResponseDto.fromJson(data).toDomain();
    } on DioException catch (e) {
      throw _toPaymentException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể tải thông tin ví: $e');
    }
  }

  /// 2. Lấy lịch sử 50 giao dịch nạp tiền gần nhất
  Future<List<PaymentTransaction>> getTransactions() async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.paymentsTransactions,
      );
      final rawList = response.data ?? const [];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map(
            (json) => PaymentTransactionResponseDto.fromJson(json).toDomain(),
          )
          .toList(growable: false);
    } on DioException catch (e) {
      throw _toPaymentException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể tải lịch sử giao dịch: $e');
    }
  }

  /// 3. Tạo đơn nạp tiền PayOS
  Future<DepositOrder> createDeposit({required int amountVnd}) async {
    if (amountVnd < 10000 || amountVnd > 50000000) {
      throw const AppException(
        message: 'Số tiền nạp tối thiểu 10.000 VNĐ và tối đa 50.000.000 VNĐ.',
        statusCode: 400,
      );
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.paymentsDeposits,
        data: CreateDepositRequestDto(amountVnd: amountVnd).toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const AppException(message: 'Không nhận được thông tin đơn nạp.');
      }
      return DepositResponseDto.fromJson(data).toDomain();
    } on DioException catch (e) {
      throw _toPaymentException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể tạo đơn nạp xu: $e');
    }
  }

  /// 4. Lấy chi tiết đơn nạp đang chờ thanh toán theo [orderCode]
  Future<DepositOrder> getDepositByOrderCode(int orderCode) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.paymentsDepositDetail(orderCode),
      );
      final data = response.data;
      if (data == null) {
        throw const AppException(message: 'Không tìm thấy đơn nạp tiền.');
      }
      return DepositResponseDto.fromJson(data).toDomain();
    } on DioException catch (e) {
      throw _toPaymentException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể tải chi tiết đơn nạp: $e');
    }
  }

  /// 5. Kiểm tra trạng thái thanh toán theo [orderCode]
  Future<TransactionStatusResult> getTransactionStatus(int orderCode) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.paymentsTransactionStatus(orderCode),
      );
      final data = response.data;
      if (data == null) {
        throw const AppException(
          message: 'Không tìm thấy trạng thái giao dịch.',
        );
      }
      return TransactionStatusResponseDto.fromJson(data).toDomain();
    } on DioException catch (e) {
      throw _toPaymentException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể kiểm tra trạng thái đơn nạp: $e');
    }
  }

  /// 6. Hủy đơn nạp đang ở trạng thái Pending
  Future<void> cancelDeposit(int orderCode) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.paymentsDepositCancel(orderCode),
      );
    } on DioException catch (e) {
      throw _toPaymentException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể hủy đơn nạp tiền: $e');
    }
  }

  /// 7. Tặng xu cho tác giả của bộ truyện [storyId]
  Future<DonateResult> donateToStory({
    required String storyId,
    required int coins,
    String? message,
  }) async {
    if (coins < 10 || coins > 10000000) {
      throw const AppException(
        message: 'Số xu ủng hộ tối thiểu là 10 Xu và tối đa 10.000.000 Xu.',
        statusCode: 400,
      );
    }
    if (message != null && message.trim().length > 500) {
      throw const AppException(
        message: 'Lời nhắn không được vượt quá 500 ký tự.',
        statusCode: 400,
      );
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.paymentsDonate,
        data: DonateRequestDto(
          storyId: storyId,
          coins: coins,
          message: message,
        ).toJson(),
      );
      final data = response.data;
      if (data == null) {
        throw const AppException(message: 'Không nhận được phản hồi ủng hộ.');
      }
      return DonateResponseDto.fromJson(data).toDomain();
    } on DioException catch (e) {
      throw _toPaymentException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể thực hiện tặng xu: $e');
    }
  }

  /// 8. Lấy danh sách lượt ủng hộ công khai của một bộ truyện
  Future<List<StoryDonation>> getStoryDonations(String storyId) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        ApiEndpoints.paymentsStoryDonations(storyId),
      );
      final rawList = response.data ?? const [];
      return rawList
          .whereType<Map<String, dynamic>>()
          .map((json) => StoryDonationItemResponseDto.fromJson(json).toDomain())
          .toList(growable: false);
    } on DioException catch (e) {
      throw _toPaymentException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException(message: 'Không thể tải danh sách ủng hộ: $e');
    }
  }

  AppException _toPaymentException(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return AppException(message: detail.trim(), statusCode: status);
      }

      final errors = data['errors'];
      if (errors is Map) {
        for (final entry in errors.values) {
          if (entry is List && entry.isNotEmpty) {
            final msg = entry.first?.toString();
            if (msg != null && msg.trim().isNotEmpty) {
              return AppException(message: msg.trim(), statusCode: status);
            }
          }
        }
      }
    }

    return AppException.fromDio(e);
  }
}
