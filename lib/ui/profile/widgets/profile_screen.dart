import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/domain/models/user_profile.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_colors.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_dimensions.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_empty_state.dart';
import 'package:joyleebook_mobile/ui/core/widgets/joylee_error_view.dart';
import 'package:joyleebook_mobile/ui/profile/view_models/profile_view_model.dart';
import 'package:joyleebook_mobile/ui/profile/widgets/profile_header.dart';
import 'package:joyleebook_mobile/ui/profile/widgets/reading_stat_tile.dart';

/// Màn hình Hồ sơ cá nhân — đủ 4 trạng thái
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch: state đổi thì màn hình tự vẽ lại
    final state = ref.watch(profileViewModelProvider);
    // read: chỉ lấy notifier để gọi hàm, không theo dõi thay đổi
    final viewModel = ref.read(profileViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ của tôi')),
      body: SafeArea(
        child: state.when(
          // 1. Đang tải
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) {
            // 2. "Trống": chưa đăng nhập / hết phiên -> gợi ý Đăng nhập
            if (error is AppException && error.statusCode == 401) {
              return JoyleeEmptyState(
                iconData: Icons.person_outline,
                title: 'Bạn chưa đăng nhập',
                message: 'Đăng nhập để xem hồ sơ và thống kê đọc của bạn.',
                actionLabel: 'Đăng nhập',
                onAction: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng đăng nhập từ thanh điều hướng.'),
                    ),
                  );
                },
              );
            }
            // 3. Lỗi khác (mất mạng, 502...) -> Thử lại
            return JoyleeErrorView(
              message: error is AppException
                  ? error.message
                  : 'Đã có lỗi xảy ra.',
              onRetry: viewModel.refresh,
            );
          },
          // 4. Có dữ liệu
          data: (profile) => RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: ListView(
              // Nội dung ngắn hơn màn hình vẫn kéo xuống để làm mới được
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.space4,
                AppDimensions.space6,
                AppDimensions.space4,
                AppDimensions.space8,
              ),
              children: [
                ProfileHeader(profile: profile),
                const SizedBox(height: AppDimensions.space8), // section gap
                _SectionTitle(
                  title: 'Thống kê đọc',
                  subtitle: profile.stats.lastReadAt == null
                      ? 'Bạn chưa đọc chương nào'
                      : 'Đọc gần nhất: ${_formatDate(profile.stats.lastReadAt!)}',
                ),
                const SizedBox(height: AppDimensions.space3),
                _StatsGrid(stats: profile.stats),
                if (profile.stats.periodDays > 0) ...[
                  const SizedBox(height: AppDimensions.space3),
                  _PeriodSummaryCard(stats: profile.stats),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Định dạng ngày kiểu Việt Nam: 18/10/2026
String _formatDate(DateTime date) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  return '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year}';
}

/// Tiêu đề mục + dòng chú thích màu text/muted
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.space1),
        Text(
          subtitle,
          style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
        ),
      ],
    );
  }
}

/// Lưới thống kê: 2 cột trên điện thoại, 4 cột từ 600px (tablet).
/// Các ô cùng hàng cao bằng nhau nhờ IntrinsicHeight + stretch.
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final ReadingStats stats;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      ReadingStatTile(
        icon: Icons.auto_stories_outlined,
        value: '${stats.seriesStarted}',
        label: 'Truyện đã đọc',
      ),
      ReadingStatTile(
        icon: Icons.check_circle_outline,
        value: '${stats.chaptersCompleted}',
        label: 'Chương đã xong',
      ),
      ReadingStatTile(
        icon: Icons.local_fire_department_outlined,
        value: '${stats.currentStreakDays}',
        unit: 'ngày',
        label: 'Chuỗi hiện tại',
      ),
      ReadingStatTile(
        icon: Icons.emoji_events_outlined,
        value: '${stats.longestStreakDays}',
        unit: 'ngày',
        label: 'Chuỗi dài nhất',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 4 : 2;
        return Column(
          spacing: AppDimensions.space3,
          children: [
            for (var i = 0; i < tiles.length; i += columns)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppDimensions.space3,
                  children: [
                    for (final tile in tiles.skip(i).take(columns))
                      Expanded(child: tile),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Tóm tắt kỳ gần đây (mặc định 30 ngày): số ngày có đọc + thanh tiến độ 4px
class _PeriodSummaryCard extends StatelessWidget {
  const _PeriodSummaryCard({required this.stats});

  final ReadingStats stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space5), // card padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Eyebrow: 12px, đậm 600, giãn chữ 0.15em, viết hoa, màu text/brand
            Text(
              '${stats.periodDays} NGÀY QUA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.8,
                color: colors.textBrand,
              ),
            ),
            const SizedBox(height: AppDimensions.space2),
            Text.rich(
              TextSpan(
                text: '${stats.activeDaysInPeriod}',
                children: [
                  TextSpan(
                    text: ' / ${stats.periodDays} ngày có đọc',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.space3),
            // Thanh tiến độ 4px (giống progress đọc trên Story Card)
            ExcludeSemantics(
              child: Container(
                height: 4,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  // Rãnh dùng borderDefault để vẫn thấy rõ trên nền thẻ trắng
                  color: colors.borderDefault,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: FractionallySizedBox(
                  widthFactor: stats.activeRatio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.primaryBrand,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusFull,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space3),
            Text(
              'Đọc xong ${stats.chaptersCompletedInPeriod} chương trong kỳ',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
