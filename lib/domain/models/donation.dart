import 'package:flutter/foundation.dart';

/// PURE DOMAIN MODEL - Một lượt ủng hộ xu của độc giả cho bộ truyện
@immutable
class StoryDonation {
  final String id;
  final String senderUserId;
  final int coins;
  final String? message;
  final DateTime createdAt;

  const StoryDonation({
    required this.id,
    required this.senderUserId,
    required this.coins,
    this.message,
    required this.createdAt,
  });
}

/// PURE DOMAIN MODEL - Kết quả sau khi tặng xu thành công
@immutable
class DonateResult {
  final String donationId;
  final String storyId;
  final int coins;
  final String? message;
  final int senderBalanceRemaining;
  final DateTime createdAt;

  const DonateResult({
    required this.donationId,
    required this.storyId,
    required this.coins,
    this.message,
    required this.senderBalanceRemaining,
    required this.createdAt,
  });
}

/// PURE DOMAIN MODEL - Lượt nhận ủng hộ Xu của tác giả theo từng tác phẩm
@immutable
class AuthorReceivedDonation {
  final String id;
  final String storyId;
  final String storyTitle;
  final String senderUserId;
  final int coins;
  final String? message;
  final DateTime createdAt;

  const AuthorReceivedDonation({
    required this.id,
    required this.storyId,
    required this.storyTitle,
    required this.senderUserId,
    required this.coins,
    this.message,
    required this.createdAt,
  });
}
