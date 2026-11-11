import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/series_repository.dart';
import '../../../data/services/api_exceptions.dart';
import '../../../domain/models/auth_session.dart';
import '../../../domain/models/deposit_order.dart';
import '../../../domain/models/donation.dart';
import '../../../domain/models/user_profile.dart';
import '../../../domain/models/wallet.dart';
import '../../auth/view_models/auth_session_view_model.dart';

/// State quản lý Ví Xu, đơn nạp đang chờ, lịch sử nạp & lịch sử nhận ủng hộ (nếu là Tác giả)
@immutable
class WalletState {
  final Wallet wallet;
  final List<PaymentTransaction> transactions;
  final bool isAuthor;
  final List<AuthorReceivedDonation> receivedDonations;
  final bool isLoadingReceivedDonations;
  final String? receivedDonationsError;
  final DepositOrder? activeDeposit;
  final TransactionStatusResult? completedTransaction;
  final bool isCreatingDeposit;
  final bool isCheckingStatus;
  final bool isCancelling;
  final bool isGatewayUnavailable;
  final String? actionError;

  const WalletState({
    required this.wallet,
    this.transactions = const [],
    this.isAuthor = false,
    this.receivedDonations = const [],
    this.isLoadingReceivedDonations = false,
    this.receivedDonationsError,
    this.activeDeposit,
    this.completedTransaction,
    this.isCreatingDeposit = false,
    this.isCheckingStatus = false,
    this.isCancelling = false,
    this.isGatewayUnavailable = false,
    this.actionError,
  });

  int get totalReceivedCoins =>
      receivedDonations.fold(0, (sum, item) => sum + item.coins);

  WalletState copyWith({
    Wallet? wallet,
    List<PaymentTransaction>? transactions,
    bool? isAuthor,
    List<AuthorReceivedDonation>? receivedDonations,
    bool? isLoadingReceivedDonations,
    String? receivedDonationsError,
    DepositOrder? activeDeposit,
    TransactionStatusResult? completedTransaction,
    bool? isCreatingDeposit,
    bool? isCheckingStatus,
    bool? isCancelling,
    bool? isGatewayUnavailable,
    String? actionError,
    bool clearReceivedDonationsError = false,
    bool clearActiveDeposit = false,
    bool clearCompletedTransaction = false,
    bool clearActionError = false,
  }) {
    return WalletState(
      wallet: wallet ?? this.wallet,
      transactions: transactions ?? this.transactions,
      isAuthor: isAuthor ?? this.isAuthor,
      receivedDonations: receivedDonations ?? this.receivedDonations,
      isLoadingReceivedDonations:
          isLoadingReceivedDonations ?? this.isLoadingReceivedDonations,
      receivedDonationsError: clearReceivedDonationsError
          ? null
          : (receivedDonationsError ?? this.receivedDonationsError),
      activeDeposit: clearActiveDeposit
          ? null
          : (activeDeposit ?? this.activeDeposit),
      completedTransaction: clearCompletedTransaction
          ? null
          : (completedTransaction ?? this.completedTransaction),
      isCreatingDeposit: isCreatingDeposit ?? this.isCreatingDeposit,
      isCheckingStatus: isCheckingStatus ?? this.isCheckingStatus,
      isCancelling: isCancelling ?? this.isCancelling,
      isGatewayUnavailable: isGatewayUnavailable ?? this.isGatewayUnavailable,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }
}

/// RIVERPOD PROVIDER: Quản lý trạng thái Ví Xu của độc giả
final walletViewModelProvider =
    AsyncNotifierProvider<WalletViewModel, WalletState>(
      WalletViewModel.new,
      retry: (retryCount, error) => null,
    );

/// VIEWMODEL - Quản lý Ví, Tạo đơn nạp PayOS, Polling trạng thái & Fallback Web
class WalletViewModel extends AsyncNotifier<WalletState> {
  Timer? _pollingTimer;
  bool _isPollingInFlight = false;

  @override
  Future<WalletState> build() async {
    ref.onDispose(_stopPolling);

    final session = ref.watch(authSessionProvider).value;
    if (session == null) {
      _stopPolling();
      throw const AppException(
        message: 'Vui lòng đăng nhập để xem ví Xu của bạn.',
        statusCode: 401,
      );
    }

    return _loadInitialState(session);
  }

  Future<WalletState> _loadInitialState(AuthSession session) async {
    final repo = ref.read(paymentRepositoryProvider);
    final isAuthor = session.role == UserRole.author;

    final walletFuture = repo.getWallet();
    final txFuture = repo.getTransactions().then<List<PaymentTransaction>>(
      (value) => value,
      onError: (_) => const <PaymentTransaction>[],
    );
    final receivedFuture = isAuthor
        ? _fetchAuthorReceivedDonations(session.userId)
        : Future.value((
            items: const <AuthorReceivedDonation>[],
            error: null as String?,
          ));

    final wallet = await walletFuture;
    final transactions = await txFuture;
    final receivedResult = await receivedFuture;

    DepositOrder? activeDeposit;
    for (final tx in transactions) {
      if (tx.status == DepositStatus.pending) {
        try {
          activeDeposit = await repo.getDepositByOrderCode(tx.orderCode);
          if (activeDeposit.status == DepositStatus.pending) {
            _startPolling(activeDeposit.orderCode);
          } else {
            activeDeposit = null;
          }
        } catch (_) {}
        break;
      }
    }

    return WalletState(
      wallet: wallet,
      transactions: transactions,
      isAuthor: isAuthor,
      receivedDonations: receivedResult.items,
      receivedDonationsError: receivedResult.error,
      activeDeposit: activeDeposit,
    );
  }

  Future<({List<AuthorReceivedDonation> items, String? error})>
  _fetchAuthorReceivedDonations(String authorId) async {
    try {
      final authorSeries = await ref
          .read(seriesRepositoryProvider)
          .getSeriesByAuthorId(authorId);
      if (authorSeries.isEmpty) {
        return (items: const <AuthorReceivedDonation>[], error: null);
      }

      final paymentRepo = ref.read(paymentRepositoryProvider);
      var successCount = 0;
      String? lastError;

      final perSeriesLists = await Future.wait(
        authorSeries.map((series) async {
          try {
            final donations = await paymentRepo.getStoryDonations(series.id);
            successCount++;
            return donations
                .map(
                  (d) => AuthorReceivedDonation(
                    id: d.id,
                    storyId: series.id,
                    storyTitle: series.title,
                    senderUserId: d.senderUserId,
                    coins: d.coins,
                    message: d.message,
                    createdAt: d.createdAt,
                  ),
                )
                .toList(growable: false);
          } catch (e) {
            lastError = e is AppException
                ? e.message
                : 'Không thể tải lịch sử được ủng hộ.';
            return const <AuthorReceivedDonation>[];
          }
        }),
      );

      if (successCount == 0 && lastError != null) {
        return (items: const <AuthorReceivedDonation>[], error: lastError);
      }

      final combined =
          perSeriesLists.expand((items) => items).toList(growable: false)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return (items: combined, error: null);
    } catch (e) {
      return (
        items: const <AuthorReceivedDonation>[],
        error: e is AppException
            ? e.message
            : 'Không thể tải lịch sử được ủng hộ.',
      );
    }
  }

  Future<void> refresh() async {
    _stopPolling();
    final session = ref.read(authSessionProvider).value;
    if (session == null) {
      state = AsyncError(
        const AppException(
          message: 'Vui lòng đăng nhập để xem ví Xu của bạn.',
          statusCode: 401,
        ),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    final next = await AsyncValue.guard(() => _loadInitialState(session));
    if (ref.mounted) {
      state = next;
    }
  }

  /// Tải lại riêng phần lịch sử được ủng hộ cho tài khoản Tác giả
  Future<void> retryReceivedDonations() async {
    final session = ref.read(authSessionProvider).value;
    final current = state.value;
    if (session == null ||
        current == null ||
        !current.isAuthor ||
        current.isLoadingReceivedDonations) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        isLoadingReceivedDonations: true,
        clearReceivedDonationsError: true,
      ),
    );

    final result = await _fetchAuthorReceivedDonations(session.userId);
    final latest = state.value;
    if (!ref.mounted || latest == null) return;
    state = AsyncData(
      latest.copyWith(
        isLoadingReceivedDonations: false,
        receivedDonations: result.items,
        receivedDonationsError: result.error,
        clearReceivedDonationsError: result.error == null,
      ),
    );
  }

  /// Tạo đơn nạp tiền PayOS mới
  Future<bool> createDeposit(int amountVnd) async {
    final current = state.value;
    if (current == null || current.isCreatingDeposit) return false;

    if (amountVnd < 10000 || amountVnd > 50000000) {
      state = AsyncData(
        current.copyWith(
          actionError: 'Số tiền nạp phải từ 10.000 VNĐ đến 50.000.000 VNĐ.',
          isGatewayUnavailable: false,
        ),
      );
      return false;
    }

    _stopPolling();
    state = AsyncData(
      current.copyWith(
        isCreatingDeposit: true,
        isGatewayUnavailable: false,
        clearActionError: true,
      ),
    );

    try {
      final repo = ref.read(paymentRepositoryProvider);
      final deposit = await repo.createDeposit(amountVnd: amountVnd);

      List<PaymentTransaction> txs = current.transactions;
      try {
        txs = await repo.getTransactions();
      } catch (_) {}

      if (!ref.mounted) return false;

      state = AsyncData(
        current.copyWith(
          transactions: txs,
          activeDeposit: deposit,
          clearCompletedTransaction: true,
          isCreatingDeposit: false,
          isGatewayUnavailable: false,
          clearActionError: true,
        ),
      );
      _startPolling(deposit.orderCode);
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      final isUnavailable =
          e is AppException &&
          (e.statusCode == 503 || e.statusCode == 502 || e.statusCode == 404);
      final message = e is AppException
          ? e.message
          : 'Không thể tạo đơn nạp xu. Vui lòng thử lại.';
      state = AsyncData(
        current.copyWith(
          isCreatingDeposit: false,
          isGatewayUnavailable: isUnavailable,
          actionError: message,
        ),
      );
      return false;
    }
  }

  /// Mở lại một đơn đang Pending từ danh sách lịch sử
  Future<void> viewPendingDeposit(int orderCode) async {
    final current = state.value;
    if (current == null) return;

    _stopPolling();
    state = AsyncData(
      current.copyWith(isCreatingDeposit: true, clearActionError: true),
    );

    try {
      final deposit = await ref
          .read(paymentRepositoryProvider)
          .getDepositByOrderCode(orderCode);
      if (!ref.mounted) return;

      state = AsyncData(
        current.copyWith(
          activeDeposit: deposit,
          clearCompletedTransaction: true,
          isCreatingDeposit: false,
        ),
      );
      if (deposit.status == DepositStatus.pending) {
        _startPolling(deposit.orderCode);
      }
    } catch (e) {
      if (!ref.mounted) return;
      state = AsyncData(
        current.copyWith(
          isCreatingDeposit: false,
          actionError: e is AppException ? e.message : 'Không thể tải đơn nạp.',
        ),
      );
    }
  }

  /// Kiểm tra trạng thái đơn đang chờ (bấm thủ công hoặc khi quay lại từ trình duyệt)
  Future<bool> checkCurrentStatus() async {
    final current = state.value;
    final deposit = current?.activeDeposit;
    if (current == null || deposit == null || current.isCheckingStatus) {
      return false;
    }

    state = AsyncData(
      current.copyWith(isCheckingStatus: true, clearActionError: true),
    );

    try {
      final repo = ref.read(paymentRepositoryProvider);
      final statusRes = await repo.getTransactionStatus(deposit.orderCode);
      if (!ref.mounted) return false;

      if (statusRes.status == DepositStatus.success) {
        _stopPolling();
        await _handlePaymentSuccess(statusRes);
        return true;
      }

      if (statusRes.status.isFinal) {
        _stopPolling();
        final txs = await repo.getTransactions();
        if (!ref.mounted) return false;
        state = AsyncData(
          current.copyWith(
            transactions: txs,
            clearActiveDeposit: true,
            isCheckingStatus: false,
            actionError:
                'Đơn nạp đã chuyển sang trạng thái ${statusRes.status.label}.',
          ),
        );
        return false;
      }

      state = AsyncData(current.copyWith(isCheckingStatus: false));
      return false;
    } catch (e) {
      if (!ref.mounted) return false;
      state = AsyncData(
        current.copyWith(
          isCheckingStatus: false,
          actionError: e is AppException
              ? e.message
              : 'Không thể kiểm tra trạng thái đơn nạp.',
        ),
      );
      return false;
    }
  }

  /// Hủy đơn nạp đang Pending
  Future<bool> cancelActiveDeposit(int orderCode) async {
    final current = state.value;
    if (current == null || current.isCancelling) return false;

    state = AsyncData(
      current.copyWith(isCancelling: true, clearActionError: true),
    );

    try {
      final repo = ref.read(paymentRepositoryProvider);
      await repo.cancelDeposit(orderCode);
      _stopPolling();

      List<PaymentTransaction> txs = current.transactions;
      try {
        txs = await repo.getTransactions();
      } catch (_) {}

      if (!ref.mounted) return false;

      state = AsyncData(
        current.copyWith(
          transactions: txs,
          clearActiveDeposit: current.activeDeposit?.orderCode == orderCode,
          isCancelling: false,
          clearActionError: true,
        ),
      );
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = AsyncData(
        current.copyWith(
          isCancelling: false,
          actionError: e is AppException ? e.message : 'Không thể hủy đơn nạp.',
        ),
      );
      return false;
    }
  }

  void resetAfterSuccess() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        clearCompletedTransaction: true,
        clearActiveDeposit: true,
        clearActionError: true,
      ),
    );
  }

  void clearActionError() {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(clearActionError: true));
  }

  /// Cập nhật ngay số dư sau khi độc giả tặng xu thành công
  void updateBalanceLocally(int newBalance) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        wallet: current.wallet.copyWith(
          balance: newBalance,
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  void _startPolling(int orderCode) {
    _stopPolling();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      unawaited(_pollOrderStatus(orderCode));
    });
  }

  Future<void> _pollOrderStatus(int orderCode) async {
    if (_isPollingInFlight || !ref.mounted) return;
    _isPollingInFlight = true;
    try {
      final statusRes = await ref
          .read(paymentRepositoryProvider)
          .getTransactionStatus(orderCode);
      if (!ref.mounted) return;
      if (statusRes.status == DepositStatus.success) {
        _stopPolling();
        await _handlePaymentSuccess(statusRes);
      } else if (statusRes.status.isFinal) {
        _stopPolling();
        final txs = await ref.read(paymentRepositoryProvider).getTransactions();
        final current = state.value;
        if (ref.mounted && current != null) {
          state = AsyncData(
            current.copyWith(transactions: txs, clearActiveDeposit: true),
          );
        }
      }
    } catch (_) {
      // Bỏ qua lỗi mạng tạm thời khi polling ngầm
    } finally {
      _isPollingInFlight = false;
    }
  }

  Future<void> _handlePaymentSuccess(TransactionStatusResult statusRes) async {
    final current = state.value;
    if (current == null) return;

    final repo = ref.read(paymentRepositoryProvider);
    final wallet = await repo.getWallet();
    List<PaymentTransaction> txs = current.transactions;
    try {
      txs = await repo.getTransactions();
    } catch (_) {}

    if (!ref.mounted) return;
    state = AsyncData(
      current.copyWith(
        wallet: wallet,
        transactions: txs,
        clearActiveDeposit: true,
        completedTransaction: statusRes,
        isCheckingStatus: false,
        clearActionError: true,
      ),
    );
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }
}
