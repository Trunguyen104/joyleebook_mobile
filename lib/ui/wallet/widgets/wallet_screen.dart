import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/environment.dart';
import '../../../data/services/api_exceptions.dart';
import '../../../domain/models/deposit_order.dart';
import '../../../routing/app_paths.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_button.dart';
import '../../core/widgets/joylee_empty_state.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../view_models/wallet_view_model.dart';

/// MÀN HÌNH VÍ XU & NẠP XU (WalletScreen)
/// Hỗ trợ nạp tiền qua PayOS API (VietQR + Checkout URL) và tự động fallback
/// chuyển hướng sang trang Ví trên Web Portal (https://joyleebook.duckdns.org/wallet).
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key, this.onLaunchUrl});

  /// Cho phép truyền custom launcher khi chạy test
  final Future<bool> Function(Uri uri)? onLaunchUrl;

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  static const List<int> _presetAmounts = [
    10000,
    20000,
    50000,
    100000,
    200000,
    500000,
  ];

  late final TabController _tabController;
  final _amountController = TextEditingController(text: '20000');
  int _selectedAmount = 20000;
  String? _inputError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final walletState = ref.read(walletViewModelProvider).value;
      if (walletState?.activeDeposit != null) {
        unawaited(
          ref.read(walletViewModelProvider.notifier).checkCurrentStatus(),
        );
      }
    }
  }

  void _selectPreset(int amount) {
    setState(() {
      _selectedAmount = amount;
      _amountController.text = amount.toString();
      _inputError = null;
    });
  }

  void _onAmountChanged(String value) {
    final parsed = int.tryParse(value.trim());
    setState(() {
      _selectedAmount = parsed ?? 0;
      _inputError = _validateAmount(parsed);
    });
  }

  String? _validateAmount(int? amount) {
    if (amount == null || amount <= 0) {
      return 'Vui lòng nhập số tiền hợp lệ.';
    }
    if (amount < 10000) {
      return 'Số tiền nạp tối thiểu là 10.000 VNĐ.';
    }
    if (amount > 50000000) {
      return 'Số tiền nạp tối đa là 50.000.000 VNĐ.';
    }
    return null;
  }

  Future<void> _submitCreateDeposit() async {
    final parsed = int.tryParse(_amountController.text.trim());
    final err = _validateAmount(parsed);
    if (err != null) {
      setState(() => _inputError = err);
      return;
    }

    FocusScope.of(context).unfocus();
    final success = await ref
        .read(walletViewModelProvider.notifier)
        .createDeposit(parsed!);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo mã thanh toán nạp xu.')),
      );
    }
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final launched = widget.onLaunchUrl != null
        ? await widget.onLaunchUrl!(uri)
        : await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở trình duyệt. Vui lòng thử lại sau.'),
        ),
      );
    }
  }

  Future<void> _confirmCancelDeposit(DepositOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hủy đơn nạp tiền?'),
        content: Text(
          'Bạn có chắc chắn muốn hủy đơn nạp #${order.orderCode} (${_formatNumber(order.amountVnd)} VNĐ)?',
        ),
        actions: [
          JoyleeButton(
            label: 'Đóng',
            variant: JoyleeButtonVariant.ghost,
            isFullWidth: false,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          JoyleeButton(
            label: 'Hủy đơn',
            variant: JoyleeButtonVariant.danger,
            isFullWidth: false,
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await ref
          .read(walletViewModelProvider.notifier)
          .cancelActiveDeposit(order.orderCode);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy đơn nạp tiền thành công.')),
        );
      }
    }
  }

  Future<void> _copyText(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Đã sao chép $label')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final walletAsync = ref.watch(walletViewModelProvider);
    final showAuthorTabs = walletAsync.value?.isAuthor ?? false;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        title: const Text('Ví Xu & Nạp Xu'),
        bottom: showAuthorTabs
            ? TabBar(
                controller: _tabController,
                indicatorColor: colors.primaryBrand,
                labelColor: colors.primaryBrand,
                unselectedLabelColor: colors.textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'Nạp Xu'),
                  Tab(text: 'Được ủng hộ'),
                ],
              )
            : null,
      ),
      body: SafeArea(
        child: walletAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) {
            if (error is AppException && error.statusCode == 401) {
              return JoyleeEmptyState(
                iconData: Icons.account_balance_wallet_outlined,
                title: 'Bạn chưa đăng nhập',
                message: 'Đăng nhập để xem số dư Xu và lịch sử nạp tiền.',
                actionLabel: 'Đăng nhập',
                onAction: () =>
                    context.go('${AppPaths.signIn}?from=${AppPaths.wallet}'),
              );
            }
            return JoyleeErrorView(
              message: error is AppException
                  ? error.message
                  : 'Không thể tải thông tin ví.',
              onRetry: () =>
                  ref.read(walletViewModelProvider.notifier).refresh(),
            );
          },
          data: (walletState) {
            if (!walletState.isAuthor) {
              return _buildTopUpTab(colors, walletState);
            }
            return TabBarView(
              controller: _tabController,
              children: [
                _buildTopUpTab(colors, walletState),
                _buildReceivedDonationsTab(colors, walletState),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopUpTab(AppColors colors, WalletState walletState) {
    return RefreshIndicator(
      onRefresh: () => ref.read(walletViewModelProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.space4),
        children: [
          _buildBalanceCard(colors, walletState),
          const SizedBox(height: AppDimensions.space4),
          if (walletState.completedTransaction != null)
            _buildSuccessCard(colors, walletState.completedTransaction!)
          else if (walletState.activeDeposit != null)
            _buildActiveDepositCard(
              colors,
              walletState.activeDeposit!,
              walletState,
            )
          else
            _buildDepositForm(colors, walletState),
          const SizedBox(height: AppDimensions.space6),
          _buildHistorySection(colors, walletState),
        ],
      ),
    );
  }

  Widget _buildReceivedDonationsTab(AppColors colors, WalletState walletState) {
    return RefreshIndicator(
      onRefresh: () => ref.read(walletViewModelProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimensions.space4),
        children: [
          _buildReceivedCoinsCard(colors, walletState),
          const SizedBox(height: AppDimensions.space4),
          _buildReceivedDonationsSection(colors, walletState),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(AppColors colors, WalletState walletState) {
    return _buildSummaryCard(
      gradientColors: [
        colors.primaryBrand,
        colors.primaryBrand.withValues(alpha: 0.85),
      ],
      textOnCard: colors.textOnBrand,
      title: 'Số dư hiện tại',
      amountText: '${_formatNumber(walletState.wallet.balance)} Xu',
      subtitle: 'Quy đổi: 10.000 VNĐ = 1.000 Xu',
      icon: Icons.monetization_on_rounded,
    );
  }

  Widget _buildReceivedCoinsCard(AppColors colors, WalletState walletState) {
    return _buildSummaryCard(
      gradientColors: [colors.primaryBrandDark, colors.primaryBrand],
      textOnCard: colors.textOnBrand,
      title: 'Tổng Xu đã nhận được',
      amountText: '+${_formatNumber(walletState.totalReceivedCoins)} Xu',
      subtitle:
          'Từ ${walletState.receivedDonations.length} lượt ủng hộ của độc giả',
      icon: Icons.volunteer_activism_rounded,
    );
  }

  Widget _buildSummaryCard({
    required List<Color> gradientColors,
    required Color textOnCard,
    required String title,
    required String amountText,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: textOnCard.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amountText,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textOnCard,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: textOnCard.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, size: 48, color: textOnCard.withValues(alpha: 0.9)),
        ],
      ),
    );
  }

  Widget _buildDepositForm(AppColors colors, WalletState walletState) {
    final estimatedCoins = _selectedAmount >= 10000 ? _selectedAmount ~/ 10 : 0;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space4),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nạp Xu vào ví',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.space3),

          if (walletState.actionError != null) ...[
            _buildErrorOrFallbackBanner(colors, walletState),
            const SizedBox(height: AppDimensions.space3),
          ],

          Text(
            'Chọn nhanh mệnh giá',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.space2),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetAmounts.map((amount) {
              final isSelected = _selectedAmount == amount;
              return ChoiceChip(
                label: Text('${_formatNumber(amount)} đ'),
                selected: isSelected,
                onSelected: (_) => _selectPreset(amount),
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.space4),

          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: _onAmountChanged,
            decoration: InputDecoration(
              labelText: 'Số tiền muốn nạp (VNĐ)',
              helperText: 'Tối thiểu 10.000 VNĐ • Tối đa 50.000.000 VNĐ',
              errorText: _inputError,
              suffixText: 'VNĐ',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppDimensions.space3),

          Container(
            padding: const EdgeInsets.all(AppDimensions.space3),
            decoration: BoxDecoration(
              color: colors.bgSurfaceSubtle,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Số Xu dự kiến nhận:',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '+${_formatNumber(estimatedCoins)} Xu',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.success,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space4),

          JoyleeButton(
            label: 'Tạo mã QR thanh toán',
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
            isLoading: walletState.isCreatingDeposit,
            onPressed: walletState.isCreatingDeposit
                ? null
                : _submitCreateDeposit,
          ),
          const SizedBox(height: AppDimensions.space2),
          Center(
            child: TextButton.icon(
              onPressed: () => _openExternalUrl(Environment.walletWebUrl),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Hoặc nạp xu trên trang Web Portal'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorOrFallbackBanner(
    AppColors colors,
    WalletState walletState,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space3),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: colors.danger.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline_rounded, size: 18, color: colors.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  walletState.actionError!,
                  style: TextStyle(fontSize: 13, color: colors.textPrimary),
                ),
              ),
            ],
          ),
          if (walletState.isGatewayUnavailable) ...[
            const SizedBox(height: AppDimensions.space2),
            JoyleeButton(
              label: 'Nạp xu qua Web Portal',
              variant: JoyleeButtonVariant.secondary,
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              onPressed: () => _openExternalUrl(Environment.walletWebUrl),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveDepositCard(
    AppColors colors,
    DepositOrder order,
    WalletState walletState,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space4),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: colors.primaryBrand, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Đang chờ thanh toán #${order.orderCode}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.primaryBrand,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space3),

          if (walletState.actionError != null) ...[
            _buildErrorOrFallbackBanner(colors, walletState),
            const SizedBox(height: AppDimensions.space3),
          ],

          if (order.qrCode != null && order.qrCode!.trim().isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: colors.borderDefault),
              ),
              child: QrImageView(
                data: order.qrCode!,
                version: QrVersions.auto,
                size: 190,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: AppDimensions.space2),
            Text(
              'Quét mã VietQR bằng ứng dụng ngân hàng của bạn',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: AppDimensions.space3),
          ],

          Container(
            padding: const EdgeInsets.all(AppDimensions.space3),
            decoration: BoxDecoration(
              color: colors.bgSurfaceSubtle,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  colors,
                  'Số tiền',
                  '${_formatNumber(order.amountVnd)} VNĐ (+${_formatNumber(order.coins)} Xu)',
                ),
                if (order.accountName != null)
                  _buildInfoRow(colors, 'Chủ TK', order.accountName!),
                if (order.accountNumber != null)
                  _buildInfoRow(
                    colors,
                    'Số TK',
                    order.accountNumber!,
                    onCopy: () =>
                        _copyText('số tài khoản', order.accountNumber!),
                  ),
                _buildInfoRow(
                  colors,
                  'Nội dung',
                  order.description ?? order.orderCode.toString(),
                  onCopy: () => _copyText(
                    'nội dung chuyển khoản',
                    order.description ?? order.orderCode.toString(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space4),

          if (order.checkoutUrl != null && order.checkoutUrl!.isNotEmpty) ...[
            JoyleeButton(
              label: 'Mở trang thanh toán PayOS',
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              onPressed: () => _openExternalUrl(order.checkoutUrl!),
            ),
            const SizedBox(height: AppDimensions.space2),
          ],

          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              JoyleeButton(
                label: 'Kiểm tra thanh toán',
                variant: JoyleeButtonVariant.secondary,
                isFullWidth: false,
                isLoading: walletState.isCheckingStatus,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                onPressed: walletState.isCheckingStatus
                    ? null
                    : () async {
                        final paid = await ref
                            .read(walletViewModelProvider.notifier)
                            .checkCurrentStatus();
                        if (!paid && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Hệ thống đang chờ thanh toán hoàn tất.',
                              ),
                            ),
                          );
                        }
                      },
              ),
              JoyleeButton(
                label: 'Hủy đơn',
                variant: JoyleeButtonVariant.ghost,
                isFullWidth: false,
                isLoading: walletState.isCancelling,
                onPressed: walletState.isCancelling
                    ? null
                    : () => _confirmCancelDeposit(order),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    AppColors colors,
    String label,
    String value, {
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          if (onCopy != null)
            IconButton(
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: const EdgeInsets.only(left: 4),
              icon: Icon(
                Icons.copy_rounded,
                size: 16,
                color: colors.primaryBrand,
              ),
              tooltip: 'Sao chép',
              onPressed: onCopy,
            ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(AppColors colors, TransactionStatusResult result) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space4),
      decoration: BoxDecoration(
        color: colors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: colors.success, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_rounded, size: 52, color: colors.success),
          const SizedBox(height: AppDimensions.space2),
          Text(
            'Nạp Xu thành công!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.success,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+${_formatNumber(result.coins)} Xu đã được cộng vào ví (#${result.orderCode}).',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colors.textPrimary),
          ),
          const SizedBox(height: AppDimensions.space4),
          JoyleeButton(
            label: 'Nạp thêm Xu',
            onPressed: () =>
                ref.read(walletViewModelProvider.notifier).resetAfterSuccess(),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedDonationsSection(
    AppColors colors,
    WalletState walletState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch sử được ủng hộ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.space3),
        if (walletState.isLoadingReceivedDonations)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.space4),
            decoration: BoxDecoration(
              color: colors.bgSurfaceSubtle,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (walletState.receivedDonationsError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.space3),
            decoration: BoxDecoration(
              color: colors.bgSurfaceSubtle,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(color: colors.borderDefault),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    walletState.receivedDonationsError!,
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(walletViewModelProvider.notifier)
                      .retryReceivedDonations(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          )
        else if (walletState.receivedDonations.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.space4),
            decoration: BoxDecoration(
              color: colors.bgSurfaceSubtle,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Text(
              'Bạn chưa nhận được lượt ủng hộ Xu nào từ độc giả.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          )
        else
          ...walletState.receivedDonations.map((donation) {
            final msg = donation.message?.trim();
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.space2),
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.space3),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: colors.borderDefault),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: colors.primaryBrand.withValues(
                        alpha: 0.14,
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 16,
                        color: colors.primaryBrand,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            donation.storyTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Độc giả ủng hộ • ${_formatDate(donation.createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                          if (msg != null && msg.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '"$msg"',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space2),
                    Text(
                      '+${_formatNumber(donation.coins)} Xu',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.success,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildHistorySection(AppColors colors, WalletState walletState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch sử nạp Xu gần đây',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.space3),
        if (walletState.transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.space4),
            decoration: BoxDecoration(
              color: colors.bgSurfaceSubtle,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Text(
              'Bạn chưa có giao dịch nạp xu nào.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
          )
        else
          ...walletState.transactions.map((tx) {
            final statusColor = switch (tx.status) {
              DepositStatus.success => colors.success,
              DepositStatus.pending => colors.warning,
              DepositStatus.cancelled => colors.textSecondary,
              DepositStatus.failed => colors.danger,
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.space2),
              child: InkWell(
                onTap: tx.status == DepositStatus.pending
                    ? () => ref
                          .read(walletViewModelProvider.notifier)
                          .viewPendingDeposit(tx.orderCode)
                    : null,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.space3),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: colors.borderDefault),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đơn #${tx.orderCode}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_formatNumber(tx.amountVnd)} VNĐ • ${_formatDate(tx.createdAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '+${_formatNumber(tx.coins)} Xu',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colors.primaryBrand,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tx.status.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  String _formatNumber(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final reverseIndex = s.length - i;
      buffer.write(s[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
