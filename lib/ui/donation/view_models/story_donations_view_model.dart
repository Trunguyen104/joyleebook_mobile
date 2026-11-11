import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/payment_repository.dart';
import '../../../data/services/api_exceptions.dart';
import '../../../domain/models/donation.dart';
import '../../wallet/view_models/wallet_view_model.dart';

/// RIVERPOD PROVIDER: Danh sách độc giả ủng hộ xu của một bộ truyện theo [storyId]
final storyDonationsViewModelProvider = AsyncNotifierProvider.autoDispose
    .family<StoryDonationsViewModel, List<StoryDonation>, String>(
      StoryDonationsViewModel.new,
      retry: (retryCount, error) => null,
    );

/// VIEWMODEL - Nạp và làm mới danh sách ủng hộ của một bộ truyện
class StoryDonationsViewModel extends AsyncNotifier<List<StoryDonation>> {
  final String storyId;

  StoryDonationsViewModel(this.storyId);

  @override
  Future<List<StoryDonation>> build() {
    return ref.watch(paymentRepositoryProvider).getStoryDonations(storyId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final next = await AsyncValue.guard(
      () => ref.read(paymentRepositoryProvider).getStoryDonations(storyId),
    );
    if (ref.mounted) {
      state = next;
    }
  }
}

/// Trạng thái gửi yêu cầu tặng xu
@immutable
class DonateState {
  final bool isSubmitting;
  final String? errorMessage;

  const DonateState({this.isSubmitting = false, this.errorMessage});

  DonateState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DonateState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// RIVERPOD PROVIDER: Quản lý thao tác gửi tặng xu tác giả
final donateViewModelProvider =
    NotifierProvider.autoDispose<DonateViewModel, DonateState>(
      DonateViewModel.new,
    );

/// VIEWMODEL - Kiểm tra hợp lệ, chống double-submit và đồng bộ ví sau khi tặng xu
class DonateViewModel extends Notifier<DonateState> {
  @override
  DonateState build() => const DonateState();

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<DonateResult?> submitDonate({
    required String storyId,
    required int coins,
    String? message,
  }) async {
    if (state.isSubmitting) return null;

    if (coins < 10 || coins > 10000000) {
      state = state.copyWith(
        errorMessage:
            'Số xu ủng hộ tối thiểu là 10 Xu và tối đa 10.000.000 Xu.',
      );
      return null;
    }
    final trimmedMsg = message?.trim();
    if (trimmedMsg != null && trimmedMsg.length > 500) {
      state = state.copyWith(
        errorMessage: 'Lời nhắn không được vượt quá 500 ký tự.',
      );
      return null;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final result = await ref
          .read(paymentRepositoryProvider)
          .donateToStory(storyId: storyId, coins: coins, message: trimmedMsg);

      // Cập nhật số dư ví và làm mới bảng ủng hộ của bộ truyện
      ref
          .read(walletViewModelProvider.notifier)
          .updateBalanceLocally(result.senderBalanceRemaining);
      ref.invalidate(storyDonationsViewModelProvider(storyId));

      if (ref.mounted) {
        state = const DonateState(isSubmitting: false);
      }
      return result;
    } catch (e) {
      if (ref.mounted) {
        state = DonateState(
          isSubmitting: false,
          errorMessage: e is AppException
              ? e.message
              : 'Không thể tặng xu. Vui lòng thử lại sau.',
        );
      }
      return null;
    }
  }
}
