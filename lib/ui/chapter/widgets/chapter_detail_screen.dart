import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/chapter.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/themes/theme_provider.dart';
import '../../core/widgets/joylee_empty_state.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../view_models/chapter_detail_view_model.dart';

/// MÀN HÌNH ĐỌC TRUYỆN / NỘI DUNG CHƯƠNG (ChapterDetailScreen)
/// Thiết kế chuẩn Warm Editorial tối ưu cho trải nghiệm đọc lâu dài:
/// - Chỉnh cỡ chữ linh hoạt (A- / A+)
/// - Đổi giao diện Sáng / Tối trực tiếp
/// - Điều hướng chuyển Chương trước / Chương sau mượt mà
/// - Đảm bảo đủ 4 trạng thái: Loading, Error, Empty, Data
class ChapterDetailScreen extends ConsumerStatefulWidget {
  const ChapterDetailScreen({
    super.key,
    required this.chapterId,
    required this.seriesTitle,
    this.allChapters = const [],
  });

  final String chapterId;
  final String seriesTitle;
  final List<Chapter> allChapters;

  @override
  ConsumerState<ChapterDetailScreen> createState() => _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends ConsumerState<ChapterDetailScreen> {
  // Cỡ chữ nội dung đọc (mặc định 17.0, có thể tăng/giảm từ 13.0 -> 25.0)
  double _fontSize = 17.0;

  // Controller cuộn trang để reset về đầu trang khi đổi chương
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _increaseFontSize() {
    if (_fontSize < 25.0) {
      setState(() => _fontSize += 1.5);
    }
  }

  void _decreaseFontSize() {
    if (_fontSize > 13.0) {
      setState(() => _fontSize -= 1.5);
    }
  }

  void _navigateToChapter(Chapter chapter) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ChapterDetailScreen(
          chapterId: chapter.id,
          seriesTitle: widget.seriesTitle,
          allChapters: widget.allChapters,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final state = ref.watch(chapterDetailViewModelProvider(widget.chapterId));

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.seriesTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            state.maybeWhen(
              data: (detail) => Text(
                'Chương ${detail.sortOrder} / ${detail.totalChapters}',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                ),
              ),
              orElse: () => Text(
                'Đang tải...',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Nút giảm cỡ chữ
          IconButton(
            icon: const Icon(Icons.text_decrease_rounded),
            tooltip: 'Giảm cỡ chữ',
            onPressed: _decreaseFontSize,
          ),
          // Nút tăng cỡ chữ
          IconButton(
            icon: const Icon(Icons.text_increase_rounded),
            tooltip: 'Tăng cỡ chữ',
            onPressed: _increaseFontSize,
          ),
          // Nút đổi theme Sáng / Tối
          IconButton(
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            tooltip: 'Đổi giao diện Sáng / Tối',
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
        ],
      ),
      body: state.when(
        // 1. Trạng thái Loading
        loading: () => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colors.primaryBrand),
          ),
        ),

        // 2. Trạng thái Error
        error: (error, _) => JoyleeErrorView(
          message: error.toString(),
          onRetry: () => ref
              .read(chapterDetailViewModelProvider(widget.chapterId).notifier)
              .refresh(),
        ),

        // 3. Trạng thái Data
        data: (detail) {
          if (detail.content.trim().isEmpty) {
            return JoyleeEmptyState(
              iconData: Icons.article_outlined,
              title: 'Chương chưa có nội dung',
              message: 'Tác giả chưa cập nhật nội dung cho chương này.',
              actionLabel: 'Tải lại',
              onAction: () => ref
                  .read(chapterDetailViewModelProvider(widget.chapterId).notifier)
                  .refresh(),
            );
          }

          // Tách nội dung thành từng đoạn văn
          final paragraphs = detail.content
              .split('\n')
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty)
              .toList();

          // Tìm chương trước và chương sau từ danh sách widget.allChapters
          Chapter? previousChapter;
          Chapter? nextChapter;
          if (widget.allChapters.isNotEmpty) {
            for (final c in widget.allChapters) {
              if (c.sortOrder == detail.sortOrder - 1) {
                previousChapter = c;
              } else if (c.sortOrder == detail.sortOrder + 1) {
                nextChapter = c;
              }
            }
          }

          return SafeArea(
            child: Column(
              children: [
                // Phần thân nội dung đọc (Cuộn mượt mà)
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space5,
                      vertical: AppDimensions.space4,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tiêu đề chương
                        Text(
                          detail.title,
                          style: TextStyle(
                            fontSize: _fontSize + 5,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space2),

                        // Thông tin phụ: Số từ & Thời gian đọc ước tính
                        Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: 14,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Khoảng ${detail.estimatedReadingMinutes} phút đọc',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.menu_book_rounded,
                              size: 14,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${detail.wordCount} từ',
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.space3),
                        Divider(color: colors.borderDefault.withValues(alpha: 0.5)),
                        const SizedBox(height: AppDimensions.space3),

                        // Nội dung từng đoạn văn bản
                        ...paragraphs.map((p) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppDimensions.space4,
                              ),
                              child: Text(
                                p,
                                style: TextStyle(
                                  fontSize: _fontSize,
                                  height: 1.85, // Giãn dòng rộng rãi chống mỏi mắt
                                  color: colors.textPrimary,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            )),

                        const SizedBox(height: AppDimensions.space6),
                        Center(
                          child: Text(
                            '— Hết Chương ${detail.sortOrder} —',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: colors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space6),
                      ],
                    ),
                  ),
                ),

                // Thanh điều hướng cố định dưới đáy: [Chương trước] [Chương sau]
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space4,
                    vertical: AppDimensions.space2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.bgSurface,
                    border: Border(
                      top: BorderSide(
                        color: colors.borderDefault.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Nút Chương trước
                      TextButton.icon(
                        onPressed: previousChapter != null
                            ? () => _navigateToChapter(previousChapter!)
                            : null,
                        icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                        label: const Text('Chương trước'),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.primaryBrand,
                          disabledForegroundColor: colors.textDisabled,
                        ),
                      ),

                      // Chỉ số chương hiện tại
                      Text(
                        '${detail.sortOrder} / ${detail.totalChapters}',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),

                      // Nút Chương sau
                      TextButton.icon(
                        onPressed: nextChapter != null
                            ? () => _navigateToChapter(nextChapter!)
                            : null,
                        icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        label: const Text('Chương sau'),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.primaryBrand,
                          disabledForegroundColor: colors.textDisabled,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
