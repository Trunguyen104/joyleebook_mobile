import 'package:flutter/material.dart';
import '../../../domain/models/series.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';

/// WIDGET THẺ TRUYỆN (SeriesCard)
/// Thành phần giao diện con hiển thị thông tin tóm tắt của một bộ truyện trong danh sách.
/// 
/// NGUYÊN TẮC THIẾT KẾ:
/// 1. Chuẩn Warm Editorial: Nền thẻ bgSurface, viền nhẹ borderDefault, chữ rõ nét.
/// 2. Touch target tối thiểu: Nút bookmark đạt diện tích bấm 48x48dp để dễ chạm trên điện thoại.
/// 3. Ảnh bìa có fallback placeholder dịu mắt khi mất mạng hoặc link ảnh lỗi.
class SeriesCard extends StatelessWidget {
  final Series series;
  final VoidCallback onTap;
  final VoidCallback onBookmarkTap;

  const SeriesCard({
    super.key,
    required this.series,
    required this.onTap,
    required this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.space3),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Ảnh bìa truyện (Tỷ lệ sách đứng)
              _buildCoverImage(colors),
              const SizedBox(width: AppDimensions.space3),

              // 2. Thông tin chi tiết truyện
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiêu đề truyện
                    Text(
                      series.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Tên tác giả
                    Text(
                      series.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space1),

                    // Tóm tắt ngắn nội dung truyện
                    Text(
                      series.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space2),

                    // Nhãn thể loại và trạng thái
                    Wrap(
                      spacing: AppDimensions.space1,
                      runSpacing: 4,
                      children: [
                        // Huy hiệu trạng thái: Hoàn thành / Đang tiến hành
                        _buildBadge(
                          label: series.status.label,
                          bgColor: series.status == SeriesStatus.completed
                              ? colors.success.withValues(alpha: 0.15)
                              : colors.accent.withValues(alpha: 0.15),
                          textColor: series.status == SeriesStatus.completed
                              ? colors.success
                              : colors.accent,
                        ),

                        // Các thẻ thể loại truyện (nếu có)
                        ...series.genres.take(2).map(
                              (genre) => _buildBadge(
                                label: genre,
                                bgColor: colors.bgSurfaceSubtle,
                                textColor: colors.textSecondary,
                              ),
                            ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. Nút Lưu Tủ Sách (Bookmark Icon Button)
              // Đảm bảo touch target >= 48dp theo tiêu chí PRN232
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  icon: Icon(
                    series.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: series.isBookmarked
                        ? colors.primaryBrand
                        : colors.textDisabled,
                    size: 26,
                  ),
                  tooltip: series.isBookmarked ? 'Bỏ lưu' : 'Lưu vào tủ sách',
                  onPressed: onBookmarkTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Khung hiển thị ảnh bìa có xử lý khi tải ảnh mạng hoặc link bị lỗi
  Widget _buildCoverImage(AppColors colors) {
    return Container(
      width: 76,
      height: 104,
      decoration: BoxDecoration(
        color: colors.bgSurfaceSubtle,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: colors.borderDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: series.coverImageUrl.isNotEmpty
          ? Image.network(
              series.coverImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stackTrace) => _buildPlaceholderIcon(colors),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primaryBrand),
                  ),
                );
              },
            )
          : _buildPlaceholderIcon(colors),
    );
  }

  Widget _buildPlaceholderIcon(AppColors colors) {
    return Center(
      child: Icon(
        Icons.auto_stories_rounded,
        size: 32,
        color: colors.textDisabled,
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
