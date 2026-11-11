import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/app_paths.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_button.dart';
import '../../wallet/view_models/wallet_view_model.dart';
import '../view_models/story_donations_view_model.dart';

/// MODAL BOTTOM SHEET - Tặng Xu ủng hộ tác giả
class DonateBottomSheet extends ConsumerStatefulWidget {
  const DonateBottomSheet({
    super.key,
    required this.storyId,
    required this.storyTitle,
  });

  final String storyId;
  final String storyTitle;

  static Future<bool?> show(
    BuildContext context, {
    required String storyId,
    required String storyTitle,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      builder: (_) =>
          DonateBottomSheet(storyId: storyId, storyTitle: storyTitle),
    );
  }

  @override
  ConsumerState<DonateBottomSheet> createState() => _DonateBottomSheetState();
}

class _DonateBottomSheetState extends ConsumerState<DonateBottomSheet> {
  static const List<int> _presetCoins = [20, 50, 100, 200, 500, 1000];

  final _coinsController = TextEditingController(text: '50');
  final _messageController = TextEditingController();
  int _selectedCoins = 50;
  String? _coinsError;

  @override
  void dispose() {
    _coinsController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _selectPreset(int coins) {
    setState(() {
      _selectedCoins = coins;
      _coinsController.text = coins.toString();
      _coinsError = null;
    });
    ref.read(donateViewModelProvider.notifier).clearError();
  }

  void _onCoinsChanged(String value) {
    final parsed = int.tryParse(value.trim());
    setState(() {
      _selectedCoins = parsed ?? 0;
      _coinsError = _validateCoins(parsed);
    });
    ref.read(donateViewModelProvider.notifier).clearError();
  }

  String? _validateCoins(int? coins) {
    if (coins == null || coins < 10) {
      return 'Số xu ủng hộ tối thiểu là 10 Xu.';
    }
    if (coins > 10000000) {
      return 'Số xu ủng hộ tối đa là 10.000.000 Xu.';
    }
    return null;
  }

  Future<void> _openWallet() async {
    await context.push(AppPaths.wallet);
    if (mounted) {
      ref.invalidate(walletViewModelProvider);
    }
  }

  Future<void> _submit() async {
    final parsed = int.tryParse(_coinsController.text.trim());
    final err = _validateCoins(parsed);
    if (err != null) {
      setState(() => _coinsError = err);
      return;
    }

    FocusScope.of(context).unfocus();
    final result = await ref
        .read(donateViewModelProvider.notifier)
        .submitDonate(
          storyId: widget.storyId,
          coins: parsed!,
          message: _messageController.text,
        );

    if (result != null && mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã tặng ${_formatNumber(result.coins)} Xu ủng hộ tác phẩm "${widget.storyTitle}"!',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final walletAsync = ref.watch(walletViewModelProvider);
    final donateState = ref.watch(donateViewModelProvider);

    final walletBalance = walletAsync.value?.wallet.balance;
    final isInsufficientBalance =
        walletBalance != null &&
        _selectedCoins >= 10 &&
        walletBalance < _selectedCoins;
    final isCoinsValid = _validateCoins(_selectedCoins) == null;

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppDimensions.space4,
          0,
          AppDimensions.space4,
          AppDimensions.space4 + bottomInset,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề sheet
              Text(
                'Tặng Xu ủng hộ tác giả',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.storyTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.primaryBrand,
                ),
              ),
              const SizedBox(height: AppDimensions.space4),

              // Hộp hiển thị số dư hiện tại + Nạp thêm
              Container(
                padding: const EdgeInsets.all(AppDimensions.space3),
                decoration: BoxDecoration(
                  color: colors.bgSurfaceSubtle,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: colors.borderDefault),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      color: colors.primaryBrand,
                      size: 22,
                    ),
                    const SizedBox(width: AppDimensions.space2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Số dư ví hiện tại',
                            style: TextStyle(
                              fontSize: 11,
                              color: colors.textSecondary,
                            ),
                          ),
                          Text(
                            walletAsync.isLoading
                                ? 'Đang kiểm tra...'
                                : walletBalance != null
                                ? '${_formatNumber(walletBalance)} Xu'
                                : 'Không xác định',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _openWallet,
                      icon: const Icon(Icons.add_card_rounded, size: 16),
                      label: const Text('Nạp thêm xu'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.space3),

              if (isInsufficientBalance) ...[
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space3),
                  decoration: BoxDecoration(
                    color: colors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(
                      color: colors.warning.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: colors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Số dư ví (${_formatNumber(walletBalance)} Xu) không đủ để tặng ${_formatNumber(_selectedCoins)} Xu.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space3),
              ],

              if (donateState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space3),
                  decoration: BoxDecoration(
                    color: colors.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(
                      color: colors.danger.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: colors.danger,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          donateState.errorMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space3),
              ],

              // Chip chọn nhanh số Xu
              Text(
                'Chọn nhanh số Xu',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              const SizedBox(height: AppDimensions.space2),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _presetCoins.map((amount) {
                  return ChoiceChip(
                    label: Text('${_formatNumber(amount)} Xu'),
                    selected: _selectedCoins == amount,
                    onSelected: (_) => _selectPreset(amount),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimensions.space3),

              // Ô nhập số xu tùy chỉnh
              TextField(
                controller: _coinsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: _onCoinsChanged,
                decoration: InputDecoration(
                  labelText: 'Số Xu muốn tặng',
                  helperText: 'Tối thiểu 10 Xu',
                  errorText: _coinsError,
                  suffixText: 'Xu',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppDimensions.space3),

              // Lời nhắn gửi tác giả
              TextField(
                controller: _messageController,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Lời nhắn gửi tác giả (không bắt buộc)',
                  hintText: 'Viết vài lời động viên tác giả nhé...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppDimensions.space4),

              // Hàng nút bấm
              Row(
                children: [
                  Expanded(
                    child: JoyleeButton(
                      label: 'Hủy',
                      variant: JoyleeButtonVariant.ghost,
                      onPressed: donateState.isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space3),
                  Expanded(
                    flex: 2,
                    child: JoyleeButton(
                      label: isCoinsValid
                          ? 'Tặng ${_formatNumber(_selectedCoins)} Xu'
                          : 'Tặng Xu',
                      icon: const Icon(
                        Icons.volunteer_activism_rounded,
                        size: 18,
                      ),
                      isLoading: donateState.isSubmitting,
                      onPressed:
                          donateState.isSubmitting ||
                              walletAsync.isLoading ||
                              !isCoinsValid ||
                              isInsufficientBalance
                          ? null
                          : _submit,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
}
