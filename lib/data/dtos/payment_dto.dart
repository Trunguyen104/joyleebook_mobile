import '../../domain/models/deposit_order.dart';
import '../../domain/models/donation.dart';
import '../../domain/models/wallet.dart';

/// DTO: Ví Xu của người dùng
class WalletResponseDto {
  final String userId;
  final int balance;
  final DateTime? updatedAtUtc;

  const WalletResponseDto({
    required this.userId,
    required this.balance,
    this.updatedAtUtc,
  });

  factory WalletResponseDto.fromJson(Map<String, dynamic> json) {
    return WalletResponseDto(
      userId: (json['userId'] ?? '').toString(),
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      updatedAtUtc: DateTime.tryParse((json['updatedAtUtc'] ?? '').toString()),
    );
  }

  Wallet toDomain() =>
      Wallet(userId: userId, balance: balance, updatedAt: updatedAtUtc);
}

/// DTO: Request tạo đơn nạp tiền PayOS
class CreateDepositRequestDto {
  final int amountVnd;
  final String gateway;

  const CreateDepositRequestDto({
    required this.amountVnd,
    this.gateway = 'PayOS',
  });

  Map<String, dynamic> toJson() => {'amountVnd': amountVnd, 'gateway': gateway};
}

/// DTO: Response đơn nạp tiền PayOS
class DepositResponseDto {
  final String transactionId;
  final int orderCode;
  final int amountVnd;
  final int coins;
  final String status;
  final String? checkoutUrl;
  final String? qrCode;
  final String? accountNumber;
  final String? accountName;
  final String? bin;
  final String? description;
  final DateTime? expiredAtUtc;

  const DepositResponseDto({
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
    this.expiredAtUtc,
  });

  factory DepositResponseDto.fromJson(Map<String, dynamic> json) {
    return DepositResponseDto(
      transactionId: (json['transactionId'] ?? '').toString(),
      orderCode: (json['orderCode'] as num?)?.toInt() ?? 0,
      amountVnd: (json['amountVnd'] as num?)?.toInt() ?? 0,
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'Pending').toString(),
      checkoutUrl: json['checkoutUrl'] as String?,
      qrCode: json['qrCode'] as String?,
      accountNumber: json['accountNumber'] as String?,
      accountName: json['accountName'] as String?,
      bin: json['bin'] as String?,
      description: json['description'] as String?,
      expiredAtUtc: DateTime.tryParse((json['expiredAtUtc'] ?? '').toString()),
    );
  }

  DepositOrder toDomain() => DepositOrder(
    transactionId: transactionId,
    orderCode: orderCode,
    amountVnd: amountVnd,
    coins: coins,
    status: DepositStatus.fromString(status),
    checkoutUrl: checkoutUrl,
    qrCode: qrCode,
    accountNumber: accountNumber,
    accountName: accountName,
    bin: bin,
    description: description,
    expiredAt: expiredAtUtc,
  );
}

/// DTO: Một dòng lịch sử giao dịch nạp tiền
class PaymentTransactionResponseDto {
  final String id;
  final int orderCode;
  final int amountVnd;
  final int coins;
  final String status;
  final String? paymentUrl;
  final DateTime createdAtUtc;
  final DateTime? completedAtUtc;

  const PaymentTransactionResponseDto({
    required this.id,
    required this.orderCode,
    required this.amountVnd,
    required this.coins,
    required this.status,
    this.paymentUrl,
    required this.createdAtUtc,
    this.completedAtUtc,
  });

  factory PaymentTransactionResponseDto.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionResponseDto(
      id: (json['id'] ?? '').toString(),
      orderCode: (json['orderCode'] as num?)?.toInt() ?? 0,
      amountVnd: (json['amountVnd'] as num?)?.toInt() ?? 0,
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'Pending').toString(),
      paymentUrl: json['paymentUrl'] as String?,
      createdAtUtc:
          DateTime.tryParse((json['createdAtUtc'] ?? '').toString()) ??
          DateTime.now(),
      completedAtUtc: DateTime.tryParse(
        (json['completedAtUtc'] ?? '').toString(),
      ),
    );
  }

  PaymentTransaction toDomain() => PaymentTransaction(
    id: id,
    orderCode: orderCode,
    amountVnd: amountVnd,
    coins: coins,
    status: DepositStatus.fromString(status),
    paymentUrl: paymentUrl,
    createdAt: createdAtUtc,
    completedAt: completedAtUtc,
  );
}

/// DTO: Trạng thái đơn nạp khi polling
class TransactionStatusResponseDto {
  final int orderCode;
  final String status;
  final int amountVnd;
  final int coins;
  final DateTime? completedAtUtc;

  const TransactionStatusResponseDto({
    required this.orderCode,
    required this.status,
    required this.amountVnd,
    required this.coins,
    this.completedAtUtc,
  });

  factory TransactionStatusResponseDto.fromJson(Map<String, dynamic> json) {
    return TransactionStatusResponseDto(
      orderCode: (json['orderCode'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? 'Pending').toString(),
      amountVnd: (json['amountVnd'] as num?)?.toInt() ?? 0,
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      completedAtUtc: DateTime.tryParse(
        (json['completedAtUtc'] ?? '').toString(),
      ),
    );
  }

  TransactionStatusResult toDomain() => TransactionStatusResult(
    orderCode: orderCode,
    status: DepositStatus.fromString(status),
    amountVnd: amountVnd,
    coins: coins,
    completedAt: completedAtUtc,
  );
}

/// DTO: Request tặng xu cho tác giả
class DonateRequestDto {
  final String storyId;
  final int coins;
  final String? message;

  const DonateRequestDto({
    required this.storyId,
    required this.coins,
    this.message,
  });

  Map<String, dynamic> toJson() {
    final trimmed = message?.trim();
    return {
      'storyId': storyId,
      'coins': coins,
      if (trimmed != null && trimmed.isNotEmpty) 'message': trimmed,
    };
  }
}

/// DTO: Response tặng xu thành công
class DonateResponseDto {
  final String donationId;
  final String storyId;
  final int coins;
  final String? message;
  final int senderBalanceRemaining;
  final DateTime createdAtUtc;

  const DonateResponseDto({
    required this.donationId,
    required this.storyId,
    required this.coins,
    this.message,
    required this.senderBalanceRemaining,
    required this.createdAtUtc,
  });

  factory DonateResponseDto.fromJson(Map<String, dynamic> json) {
    return DonateResponseDto(
      donationId: (json['donationId'] ?? '').toString(),
      storyId: (json['storyId'] ?? '').toString(),
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      message: json['message'] as String?,
      senderBalanceRemaining:
          (json['senderBalanceRemaining'] as num?)?.toInt() ?? 0,
      createdAtUtc:
          DateTime.tryParse((json['createdAtUtc'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  DonateResult toDomain() => DonateResult(
    donationId: donationId,
    storyId: storyId,
    coins: coins,
    message: message,
    senderBalanceRemaining: senderBalanceRemaining,
    createdAt: createdAtUtc,
  );
}

/// DTO: Một lượt ủng hộ hiển thị trong Bảng vàng truyện
class StoryDonationItemResponseDto {
  final String id;
  final String senderUserId;
  final int coins;
  final String? message;
  final DateTime createdAtUtc;

  const StoryDonationItemResponseDto({
    required this.id,
    required this.senderUserId,
    required this.coins,
    this.message,
    required this.createdAtUtc,
  });

  factory StoryDonationItemResponseDto.fromJson(Map<String, dynamic> json) {
    return StoryDonationItemResponseDto(
      id: (json['id'] ?? '').toString(),
      senderUserId: (json['senderUserId'] ?? '').toString(),
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      message: json['message'] as String?,
      createdAtUtc:
          DateTime.tryParse((json['createdAtUtc'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  StoryDonation toDomain() => StoryDonation(
    id: id,
    senderUserId: senderUserId,
    coins: coins,
    message: message,
    createdAt: createdAtUtc,
  );
}
