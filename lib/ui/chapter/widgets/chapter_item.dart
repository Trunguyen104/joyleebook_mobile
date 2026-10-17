import 'package:flutter/material.dart';
import '../../../domain/models/chapter.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_badge.dart';

/// WIDGET THẺ CHƯƠNG (ChapterItem)
/// Tự động chuyển đổi giữa 2 dạng hiển thị:
/// 1. Active: Thẻ nổi bật có vạch cam, badge NOW, tiến độ đọc và nút Play.
/// 2. Normal: Dòng danh sách gọn gàng có icon checkmark/circle, tag Free, thời lượng và nút tải.
class ChapterItem extends StatelessWidget {
  const ChapterItem({
    super.key,
    required this.chapter,
    required this.onTap,
    this.onDownloadTap,
  });

  final Chapter chapter;
  final VoidCallback onTap;
  final VoidCallback? onDownloadTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return chapter.isActive ? _buildActiveCard(colors) : _buildNormalTile(colors);
  }

  /// 1. Giao diện Thẻ Chương Đang Đọc (Active Card)
  Widget _buildActiveCard(AppColors colors) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space4,
        vertical: AppDimensions.space2,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurfaceSubtle,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: colors.borderDefault.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vạch màu nhấn (Accent Bar) ở mép trái
            Container(
              width: 5,
              color: colors.accent,
            ),
            // Phần nội dung chính của thẻ
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.space3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Icon sóng âm tròn nổi bật
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: colors.accent,
                          child: const Icon(
                            Icons.graphic_eq_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space3),
                        // Tên chương + Badge NOW
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Ch. ${chapter.sortOrder}: ${chapter.title}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  JoyleeBadge(
                                    label: 'NOW',
                                    backgroundColor: colors.accent.withValues(alpha: 0.2),
                                    textColor: colors.accent,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  JoyleeBadge(
                                    label: '${(chapter.readPercentage * 100).toInt()}% read',
                                    backgroundColor: colors.accent.withValues(alpha: 0.12),
                                    textColor: colors.accent,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Active bookmark',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Nút Play tròn trắng
                        IconButton.filled(
                          onPressed: onTap,
                          style: IconButton.styleFrom(
                            backgroundColor: colors.bgSurface,
                            foregroundColor: colors.accent,
                            elevation: 1,
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space3),
                    // Thanh tiến độ đọc (Progress Bar)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      child: LinearProgressIndicator(
                        value: chapter.readPercentage,
                        minHeight: 4,
                        backgroundColor: colors.borderDefault.withValues(alpha: 0.6),
                        valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 2. Giao diện Dòng Chương Tiêu Chuẩn (Normal Tile)
  Widget _buildNormalTile(AppColors colors) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space4,
          vertical: AppDimensions.space3,
        ),
        child: Row(
          children: [
            // Icon trạng thái đã đọc / chưa đọc
            chapter.isCompleted
                ? Icon(Icons.check_circle_rounded, color: colors.accent, size: 24)
                : Icon(
                    Icons.radio_button_unchecked_rounded,
                    color: colors.borderDefault,
                    size: 24,
                  ),
            const SizedBox(width: AppDimensions.space3),
            // Tên chương + Badge Free + Thời lượng
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ch. ${chapter.sortOrder}: ${chapter.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (chapter.isFree) ...[
                        JoyleeBadge(
                          label: 'Free',
                          backgroundColor: colors.borderDefault.withValues(alpha: 0.4),
                          textColor: colors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '${chapter.durationMinutes} mins',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Nút tải offline
            IconButton(
              icon: Icon(Icons.file_download_outlined, color: colors.textSecondary),
              tooltip: 'Tải đọc offline',
              onPressed: onDownloadTap,
            ),
          ],
        ),
      ),
    );
  }
}
