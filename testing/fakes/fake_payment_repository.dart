import 'package:joyleebook_mobile/data/repositories/payment_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/domain/models/deposit_order.dart';
import 'package:joyleebook_mobile/domain/models/donation.dart';
import 'package:joyleebook_mobile/domain/models/wallet.dart';

/// Repository giả lập phục vụ Unit & Widget Test cho Ví Xu & Tặng Xu.
class FakePaymentRepository implements PaymentRepository {
  Wallet wallet;
  final List<PaymentTransaction> transactions;
  final Map<int, DepositOrder> ordersByCode;
  final Map<String, List<StoryDonation>> donationsByStory;

  AppException? walletError;
  AppException? transactionsError;
  AppException? createDepositError;
  AppException? transactionStatusError;
  AppException? cancelDepositError;
  AppException? donateError;
  AppException? storyDonationsError;

  int getWalletCalls = 0;
  int createDepositCalls = 0;
  int cancelDepositCalls = 0;
  int donateCalls = 0;
  int? lastCreatedDepositAmount;
  int? lastCancelledOrderCode;
  String? lastDonatedStoryId;
  int? lastDonatedCoins;
  String? lastDonatedMessage;

  int _nextOrderCode = 20260501;

  FakePaymentRepository({
    Wallet? initialWallet,
    List<PaymentTransaction> initialTransactions = const [],
    List<DepositOrder> initialOrders = const [],
    Map<String, List<StoryDonation>> initialDonationsByStory = const {},
    this.walletError,
    this.transactionsError,
    this.createDepositError,
    this.transactionStatusError,
    this.cancelDepositError,
    this.donateError,
    this.storyDonationsError,
  }) : wallet =
           initialWallet ??
           Wallet(
             userId: 'user-1',
             balance: 5000,
             updatedAt: DateTime(2026, 5, 1, 10, 0),
           ),
       transactions = List<PaymentTransaction>.from(initialTransactions),
       ordersByCode = {
         for (final order in initialOrders) order.orderCode: order,
       },
       donationsByStory = {
         for (final entry in initialDonationsByStory.entries)
           entry.key: List<StoryDonation>.from(entry.value),
       };

  @override
  Future<Wallet> getWallet() async {
    getWalletCalls++;
    if (walletError != null) {
      throw walletError!;
    }
    return wallet;
  }

  @override
  Future<List<PaymentTransaction>> getTransactions() async {
    if (transactionsError != null) {
      throw transactionsError!;
    }
    return List<PaymentTransaction>.unmodifiable(transactions);
  }

  @override
  Future<DepositOrder> createDeposit({required int amountVnd}) async {
    createDepositCalls++;
    lastCreatedDepositAmount = amountVnd;
    if (amountVnd < 10000 || amountVnd > 50000000) {
      throw const AppException(
        message: 'Số tiền nạp tối thiểu 10.000 VNĐ và tối đa 50.000.000 VNĐ.',
        statusCode: 400,
      );
    }
    if (createDepositError != null) {
      throw createDepositError!;
    }

    final orderCode = _nextOrderCode++;
    final coins = (amountVnd * 0.1).round();
    final txId = 'tx-$orderCode';
    final order = DepositOrder(
      transactionId: txId,
      orderCode: orderCode,
      amountVnd: amountVnd,
      coins: coins,
      status: DepositStatus.pending,
      checkoutUrl: 'https://pay.payos.vn/web/$orderCode',
      qrCode: '00020101021238570010A000000727012700069704220113$orderCode',
      accountNumber: '0399887766',
      accountName: 'JOYLEEBOOK PAYMENT',
      bin: '970422',
      description: 'JOYLEE $orderCode',
      expiredAt: DateTime.now().add(const Duration(minutes: 15)),
    );
    ordersByCode[orderCode] = order;
    transactions.insert(
      0,
      PaymentTransaction(
        id: txId,
        orderCode: orderCode,
        amountVnd: amountVnd,
        coins: coins,
        status: DepositStatus.pending,
        paymentUrl: order.checkoutUrl,
        createdAt: DateTime.now(),
      ),
    );
    return order;
  }

  @override
  Future<DepositOrder> getDepositByOrderCode(int orderCode) async {
    final order = ordersByCode[orderCode];
    if (order == null) {
      throw const AppException(
        message: 'Không tìm thấy đơn nạp tiền.',
        statusCode: 404,
      );
    }
    return order;
  }

  @override
  Future<TransactionStatusResult> getTransactionStatus(int orderCode) async {
    if (transactionStatusError != null) {
      throw transactionStatusError!;
    }
    final order = ordersByCode[orderCode];
    if (order == null) {
      throw const AppException(
        message: 'Không tìm thấy giao dịch.',
        statusCode: 404,
      );
    }
    return TransactionStatusResult(
      orderCode: order.orderCode,
      status: order.status,
      amountVnd: order.amountVnd,
      coins: order.coins,
      completedAt: order.status == DepositStatus.success
          ? DateTime.now()
          : null,
    );
  }

  @override
  Future<void> cancelDeposit(int orderCode) async {
    cancelDepositCalls++;
    lastCancelledOrderCode = orderCode;
    if (cancelDepositError != null) {
      throw cancelDepositError!;
    }
    final existing = ordersByCode[orderCode];
    if (existing != null) {
      ordersByCode[orderCode] = DepositOrder(
        transactionId: existing.transactionId,
        orderCode: existing.orderCode,
        amountVnd: existing.amountVnd,
        coins: existing.coins,
        status: DepositStatus.cancelled,
        checkoutUrl: existing.checkoutUrl,
        qrCode: existing.qrCode,
        accountNumber: existing.accountNumber,
        accountName: existing.accountName,
        bin: existing.bin,
        description: existing.description,
        expiredAt: existing.expiredAt,
      );
    }
    for (var i = 0; i < transactions.length; i++) {
      final tx = transactions[i];
      if (tx.orderCode == orderCode) {
        transactions[i] = PaymentTransaction(
          id: tx.id,
          orderCode: tx.orderCode,
          amountVnd: tx.amountVnd,
          coins: tx.coins,
          status: DepositStatus.cancelled,
          paymentUrl: tx.paymentUrl,
          createdAt: tx.createdAt,
          completedAt: DateTime.now(),
        );
      }
    }
  }

  @override
  Future<DonateResult> donateToStory({
    required String storyId,
    required int coins,
    String? message,
  }) async {
    donateCalls++;
    lastDonatedStoryId = storyId;
    lastDonatedCoins = coins;
    lastDonatedMessage = message;

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
    if (donateError != null) {
      throw donateError!;
    }
    if (coins > wallet.balance) {
      throw const AppException(message: 'Số dư Xu không đủ.', statusCode: 400);
    }

    final trimmedMsg = message?.trim();
    final effectiveMsg = (trimmedMsg == null || trimmedMsg.isEmpty)
        ? null
        : trimmedMsg;
    final now = DateTime.now();
    final remaining = wallet.balance - coins;
    wallet = wallet.copyWith(balance: remaining, updatedAt: now);

    final donationId = 'don-${now.microsecondsSinceEpoch}';
    donationsByStory.putIfAbsent(storyId, () => []);
    donationsByStory[storyId]!.insert(
      0,
      StoryDonation(
        id: donationId,
        senderUserId: wallet.userId,
        coins: coins,
        message: effectiveMsg,
        createdAt: now,
      ),
    );

    return DonateResult(
      donationId: donationId,
      storyId: storyId,
      coins: coins,
      message: effectiveMsg,
      senderBalanceRemaining: remaining,
      createdAt: now,
    );
  }

  @override
  Future<List<StoryDonation>> getStoryDonations(String storyId) async {
    if (storyDonationsError != null) {
      throw storyDonationsError!;
    }
    return List<StoryDonation>.unmodifiable(
      donationsByStory[storyId] ?? const [],
    );
  }

  /// Helper cho test mô phỏng PayOS webhook đã thanh toán thành công đơn [orderCode].
  void completeDepositOrder(int orderCode) {
    final existing = ordersByCode[orderCode];
    if (existing == null) return;
    ordersByCode[orderCode] = DepositOrder(
      transactionId: existing.transactionId,
      orderCode: existing.orderCode,
      amountVnd: existing.amountVnd,
      coins: existing.coins,
      status: DepositStatus.success,
      checkoutUrl: existing.checkoutUrl,
      qrCode: existing.qrCode,
      accountNumber: existing.accountNumber,
      accountName: existing.accountName,
      bin: existing.bin,
      description: existing.description,
      expiredAt: existing.expiredAt,
    );
    wallet = wallet.copyWith(
      balance: wallet.balance + existing.coins,
      updatedAt: DateTime.now(),
    );
    for (var i = 0; i < transactions.length; i++) {
      final tx = transactions[i];
      if (tx.orderCode == orderCode) {
        transactions[i] = PaymentTransaction(
          id: tx.id,
          orderCode: tx.orderCode,
          amountVnd: tx.amountVnd,
          coins: tx.coins,
          status: DepositStatus.success,
          paymentUrl: tx.paymentUrl,
          createdAt: tx.createdAt,
          completedAt: DateTime.now(),
        );
      }
    }
  }
}
