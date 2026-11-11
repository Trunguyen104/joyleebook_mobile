import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/api_exceptions.dart';
import '../../../domain/models/donation.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../view_models/story_donations_view_model.dart';

/// MỤC BẢNG VÀNG ỦNG HỘ TÁC GIẢ (StoryDonationsSection)
/// Hiển thị ở cuối Tab Tóm tắt trên SeriesDetailScreen.
class StoryDonationsSection extends ConsumerWidget {
  const StoryDonationsSection({
    super.key,
    required this.seriesId,
    required this.onDonateTap,
  });

  final String seriesId;
  final VoidCallback onDonateTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final donationsAsync = ref.watch(storyDonationsViewModelProvider(seriesId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.volunteer_activism_rounded,
              size: 20,
              color: colors.primaryBrand,
            ),
            const SizedBox(width: AppDimensions.space2),
            Expanded(
              child: Text(
                'Độc giả ủng hộ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onDonateTap,
              icon: const Icon(Icons.volunteer_activism_outlined, size: 16),
              label: const Text('Tặng xu'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primaryBrand,
                side: BorderSide(color: colors.primaryBrand),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: const Size(0, 36),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space3),

        donationsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppDimensions.space4),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (error, _) => Container(
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
                    error is AppException
                        ? error.message
                        : 'Không thể tải danh sách ủng hộ.',
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(storyDonationsViewModelProvider(seriesId).notifier)
                      .refresh(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
          data: (donations) {
            if (donations.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.space4),
                decoration: BoxDecoration(
                  color: colors.bgSurfaceSubtle,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  border: Border.all(color: colors.borderDefault),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.volunteer_activism_outlined,
                      size: 32,
                      color: colors.textDisabled,
                    ),
                    const SizedBox(height: AppDimensions.space2),
                    Text(
                      'Chưa có độc giả nào ủng hộ tác phẩm này.\nHãy là người đầu tiên gửi tặng Xu cho tác giả!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: donations
                  .take(10)
                  .map(
                    (donation) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AppDimensions.space2,
                      ),
                      child: _DonationTile(donation: donation),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _DonationTile extends StatelessWidget {
  const _DonationTile({required this.donation});

  final StoryDonation donation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space3),
      decoration: BoxDecoration(
        color: colors.bgSurfaceSubtle,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: colors.borderDefault.withValues(alpha: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colors.primaryBrand.withValues(alpha: 0.15),
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
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Độc giả',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryBrand.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+${_formatNumber(donation.coins)} Xu',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colors.primaryBrand,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(donation.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (donation.message != null &&
                    donation.message!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '"${donation.message!.trim()}"',
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
        ],
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

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
