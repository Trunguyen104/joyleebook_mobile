import 'package:flutter/foundation.dart';

/// Trạng thái giao dịch nạp tiền vào ví
enum DepositStatus {
  pending,
  success,
  cancelled,
  failed;

  static DepositStatus fromString(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'success':
      case 'paid':
        return DepositStatus.success;
      case 'cancelled':
      case 'canceled':
        return DepositStatus.cancelled;
      case 'failed':
        return DepositStatus.failed;
      default:
        return DepositStatus.pending;
    }
  }

  String get label => switch (this) {
    DepositStatus.pending => 'Chờ thanh toán',
    DepositStatus.success => 'Thành công',
    DepositStatus.cancelled => 'Đã hủy',
    DepositStatus.failed => 'Thất bại',
  };

  bool get isFinal => this != DepositStatus.pending;
}

/// PURE DOMAIN MODEL - Đơn nạp xu qua PayOS (VietQR + Checkout URL)
@immutable
class DepositOrder {
  final String transactionId;
  final int orderCode;
  final int amountVnd;
  final int coins;
  final DepositStatus status;
  final String? checkoutUrl;
  final String? qrCode;
  final String? accountNumber;
  final String? accountName;
  final String? bin;
  final String? description;
  final DateTime? expiredAt;

  const DepositOrder({
    required this.transactionId,
    required this.orderCode,
    required this.amountVnd,
    required this.coins,
    required this.status,
    this.checkoutUrl,
    this.qrCode,
    this.accountNumber,
    this.accountName,
    this.bin,
    this.description,
    this.expiredAt,
  });
}

/// PURE DOMAIN MODEL - Một mục lịch sử nạp tiền trong ví
@immutable
class PaymentTransaction {
  final String id;
  final int orderCode;
  final int amountVnd;
  final int coins;
  final DepositStatus status;
  final String? paymentUrl;
  final DateTime createdAt;
  final DateTime? completedAt;

  const PaymentTransaction({
    required this.id,
    required this.orderCode,
    required this.amountVnd,
    required this.coins,
    required this.status,
    this.paymentUrl,
    required this.createdAt,
    this.completedAt,
  });
}

/// PURE DOMAIN MODEL - Kết quả kiểm tra trạng thái đơn nạp
@immutable
class TransactionStatusResult {
  final int orderCode;
  final DepositStatus status;
  final int amountVnd;
  final int coins;
  final DateTime? completedAt;

  const TransactionStatusResult({
    required this.orderCode,
    required this.status,
    required this.amountVnd,
    required this.coins,
    this.completedAt,
  });
}
