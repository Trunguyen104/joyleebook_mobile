import 'package:flutter/material.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';

/// WIDGET ĐÁNH GIÁ TÁC PHẨM (SeriesRatingCard)
/// Tuân thủ quy chuẩn thiết kế Warm Editorial & Material 3:
/// 1. Bám sát Stitch design (`docs/stitch/story_details.html`).
/// 2. Hỗ trợ Rate (Đánh giá lần đầu) và Update Rating (Cập nhật đánh giá).
/// 3. Touch target tối thiểu 48x48 dp cho mỗi ngôi sao.
/// 4. Instant Feedback Banner thông báo trạng thái trực quan ngay dưới hàng sao.
/// 5. Chống spam click (Double-submit prevention) khi đang gửi request.
class SeriesRatingCard extends StatefulWidget {
  final int? userRating;
  final double averageRating;
  final int totalRatings;
  final Future<bool> Function(int score) onRate;

  const SeriesRatingCard({
    super.key,
    required this.userRating,
    required this.averageRating,
    required this.totalRatings,
    required this.onRate,
  });

  @override
  State<SeriesRatingCard> createState() => _SeriesRatingCardState();
}

class _SeriesRatingCardState extends State<SeriesRatingCard> {
  bool _isEditing = false;
  int? _hoveredOrSelectedScore;
  bool _isSubmitting = false;
  String? _successFeedbackMessage;

  @override
  void initState() {
    super.initState();
    _hoveredOrSelectedScore = widget.userRating;
  }

  @override
  void didUpdateWidget(covariant SeriesRatingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userRating != oldWidget.userRating) {
      _hoveredOrSelectedScore = widget.userRating;
      _isEditing = false;
    }
  }

  Future<void> _handleStarTapped(int score) async {
    if (_isSubmitting) return;

    final isFirstRate = widget.userRating == null;
    final isSameScore = widget.userRating == score;

    if (isSameScore && !_isEditing) return;

    setState(() {
      _isSubmitting = true;
      _hoveredOrSelectedScore = score;
    });

    final success = await widget.onRate(score);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (success) {
          _isEditing = false;
          _successFeedbackMessage = isFirstRate
              ? 'Đã gửi đánh giá thành công! Cảm ơn bạn.'
              : 'Đã cập nhật đánh giá thành công!';
        } else {
          _hoveredOrSelectedScore = widget.userRating;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasRated = (widget.userRating != null && widget.userRating! > 0) ||
        _successFeedbackMessage != null;
    final currentScore = _hoveredOrSelectedScore ?? widget.userRating ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space4),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tiêu đề Card & Nút Chỉnh sửa / Hủy
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đánh giá tác phẩm',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              if (hasRated)
                TextButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          setState(() {
                            if (_isEditing) {
                              _isEditing = false;
                              _hoveredOrSelectedScore = widget.userRating;
                              _successFeedbackMessage = null;
                            } else {
                              _isEditing = true;
                              _successFeedbackMessage = null;
                            }
                          });
                        },
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    foregroundColor: colors.primaryBrand,
                  ),
                  child: Text(
                    _isEditing ? 'Hủy' : 'Chỉnh sửa',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.primaryBrand,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.space2),

          // 2. Hàng 5 ngôi sao tương tác (Touch target >= 48x48dp)
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starScore = index + 1;
                final isFilled = starScore <= currentScore;

                return SizedBox(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    key: Key('star_button_$starScore'),
                    padding: EdgeInsets.zero,
                    iconSize: 32,
                    tooltip: 'Đánh giá $starScore sao',
                    onPressed: _isSubmitting
                        ? null
                        : () => _handleStarTapped(starScore),
                    icon: AnimatedScale(
                      scale: isFilled ? 1.05 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        isFilled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: isFilled
                            ? Colors.amber[600]
                            : colors.textDisabled.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: AppDimensions.space3),

          // 3. Instant Feedback Banner
          _buildFeedbackBanner(colors, hasRated, currentScore),
        ],
      ),
    );
  }

  Widget _buildFeedbackBanner(
    AppColors colors,
    bool hasRated,
    int currentScore,
  ) {
    String message;
    IconData icon;
    Color iconColor;

    if (_isSubmitting) {
      message = 'Đang gửi đánh giá lên hệ thống...';
      icon = Icons.hourglass_top_rounded;
      iconColor = colors.accent;
    } else if (_successFeedbackMessage != null) {
      message = _successFeedbackMessage!;
      icon = Icons.verified_rounded;
      iconColor = colors.success;
    } else if (_isEditing) {
      message = 'Chọn số sao mới để cập nhật đánh giá';
      icon = Icons.edit_note_rounded;
      iconColor = colors.primaryBrand;
    } else if (hasRated) {
      message = 'Bạn đã đánh giá tác phẩm này.';
      icon = Icons.verified_rounded;
      iconColor = colors.success;
    } else {
      message = 'Chạm vào sao để đánh giá tác phẩm này';
      icon = Icons.star_outline_rounded;
      iconColor = colors.textSecondary;
    }

    final scoreDisplay = currentScore > 0 ? '$currentScore / 5 ★' : '- / 5 ★';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgSurfaceSubtle,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(
          color: colors.borderDefault.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
          ),
          Text(
            scoreDisplay,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: currentScore > 0 ? Colors.amber[700] : colors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}
