import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/domain/models/user_profile.dart';
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
                  // TODO: điều hướng tới /sign-in khi có màn Đăng nhập
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
              padding: const EdgeInsets.all(AppDimensions.space4),
              children: [
                ProfileHeader(profile: profile),
                const SizedBox(height: AppDimensions.space6),
                Text(
                  'Thống kê đọc',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppDimensions.space2),
                _StatsGrid(stats: profile.stats),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lưới 2 cột, tự xuống hàng nên không tràn layout trên màn nhỏ
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
        label: 'Chuỗi ngày hiện tại',
      ),
      ReadingStatTile(
        icon: Icons.emoji_events_outlined,
        value: '${stats.longestStreakDays}',
        label: 'Chuỗi dài nhất',
      ),
      ReadingStatTile(
        icon: Icons.local_fire_department_outlined,
        value: '${stats.currentStreakDays}',
        label: 'Chuỗi ngày hiện tại',
      ),
      ReadingStatTile(
        icon: Icons.emoji_events_outlined,
        value: '${stats.longestStreakDays}',
        label: 'Chuỗi dài nhất',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Bề rộng mỗi ô = (bề rộng khả dụng - khe giữa) / 2
        final tileWidth = (constraints.maxWidth - AppDimensions.space2) / 2;
        return Wrap(
          spacing: AppDimensions.space2, // khe ngang
          runSpacing: AppDimensions.space2, // khe dọc giữa 2 hàng
          children: [
            for (final tile in tiles) SizedBox(width: tileWidth, child: tile),
          ],
        );
      },
    );
  }
}
