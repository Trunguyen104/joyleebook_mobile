import 'package:flutter/material.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';

/// WIDGET ĐÁNH GIÁ TÁC PHẨM TINH GỌN (SeriesRatingCard)
/// Tuân thủ quy chuẩn thiết kế Warm Editorial & Material 3:
/// 1. Tối giản, hiện đại: Cập nhật trực tiếp không cần nút Chỉnh sửa/Hủy.
/// 2. Touch target tối thiểu 48x48 dp cho mỗi ngôi sao.
/// 3. Hiển thị loading spinner xoay mượt mà ngay khi đang gửi đánh giá.
/// 4. Chống spam click (Double-submit prevention).
class SeriesRatingCard extends StatefulWidget {
  final int? userRating;
  final double averageRating;
  final int totalRatings;
  final Future<bool> Function(int score) onRate;
  final bool isAuthenticated;
  final VoidCallback? onRequireAuth;

  const SeriesRatingCard({
    super.key,
    required this.userRating,
    required this.averageRating,
    required this.totalRatings,
    required this.onRate,
    this.isAuthenticated = true,
    this.onRequireAuth,
  });

  @override
  State<SeriesRatingCard> createState() => _SeriesRatingCardState();
}

class _SeriesRatingCardState extends State<SeriesRatingCard> {
  int? _hoveredOrSelectedScore;
  bool _isSubmitting = false;

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
    }
  }

  Future<void> _handleStarTapped(int score) async {
    if (!widget.isAuthenticated) {
      widget.onRequireAuth?.call();
      return;
    }

    if (_isSubmitting) return;

    // Nếu chọn cùng điểm số hiện tại thì không gửi request trùng
    if (widget.userRating == score) return;

    setState(() {
      _isSubmitting = true;
      _hoveredOrSelectedScore = score;
    });

    final success = await widget.onRate(score);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (!success) {
          _hoveredOrSelectedScore = widget.userRating;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentScore = _hoveredOrSelectedScore ?? widget.userRating ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space4,
        vertical: AppDimensions.space3,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: colors.borderDefault.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tiêu đề Card, trạng thái đánh giá & Spinner khi đang gửi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.primaryBrand.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      ),
                      child: Icon(
                        Icons.rate_review_outlined,
                        size: 20,
                        color: colors.primaryBrand,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đánh giá tác phẩm',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.totalRatings > 0
                                ? 'Trung bình: ${widget.averageRating.toStringAsFixed(1)} ★ (${widget.totalRatings} lượt đánh giá)'
                                : 'Tác phẩm chưa có lượt đánh giá nào',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Hiển thị vòng xoay loading khi đang submit
              if (_isSubmitting)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation(colors.primaryBrand),
                  ),
                )
              else if (widget.userRating != null && widget.userRating! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 13, color: colors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Đã đánh giá',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.success,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.space2),

          // 2. Hàng 5 ngôi sao tương tác trực tiếp (Touch target >= 48x48dp)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: colors.bgSurfaceSubtle.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
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
                      scale: isFilled ? 1.12 : 1.0,
                      curve: Curves.easeOutBack,
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        isFilled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: isFilled
                            ? const Color(0xFFF59E0B)
                            : colors.textDisabled.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
