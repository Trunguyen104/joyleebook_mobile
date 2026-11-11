import 'package:flutter/foundation.dart';

/// PURE DOMAIN MODEL - Thông tin ví Xu của độc giả
@immutable
class Wallet {
  final String userId;
  final int balance;
  final DateTime? updatedAt;

  const Wallet({required this.userId, required this.balance, this.updatedAt});

  Wallet copyWith({int? balance, DateTime? updatedAt}) {
    return Wallet(
      userId: userId,
      balance: balance ?? this.balance,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
