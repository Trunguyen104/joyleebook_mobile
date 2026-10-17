import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/chapter.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_empty_state.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../view_models/chapter_list_view_model.dart';
import 'chapter_detail_screen.dart';
import 'chapter_item.dart';
import 'resume_reading_bar.dart';

/// MÀN HÌNH DANH SÁCH CHƯƠNG (ChapterListScreen)
/// Áp dụng bộ 4 trạng thái chuẩn: Loading -> Error -> Empty -> Data
/// Kèm thanh Resume ghim đáy nếu có chương đang đọc dở.
class ChapterListScreen extends ConsumerWidget {
  const ChapterListScreen({
    super.key,
    required this.seriesId,
    required this.seriesTitle,
  });

  final String seriesId;
  final String seriesTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final state = ref.watch(chapterListViewModelProvider(seriesId));

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              seriesTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Danh sách chương',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới',
            onPressed: () =>
                ref.read(chapterListViewModelProvider(seriesId).notifier).refresh(),
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

        // 2. Trạng thái Error (Có nút Thử lại)
        error: (error, _) => JoyleeErrorView(
          message: error.toString(),
          onRetry: () =>
              ref.read(chapterListViewModelProvider(seriesId).notifier).refresh(),
        ),

        // 3. Trạng thái Data (Hoặc Empty nếu danh sách rỗng)
        data: (chapters) {
          if (chapters.isEmpty) {
            return JoyleeEmptyState(
              iconData: Icons.menu_book_rounded,
              title: 'Chưa có chương nào',
              message:
                  'Tác giả hiện chưa xuất bản chương nào cho bộ truyện "$seriesTitle".',
              actionLabel: 'Tải lại',
              onAction: () => ref
                  .read(chapterListViewModelProvider(seriesId).notifier)
                  .refresh(),
            );
          }

          // Tìm chương đang đọc dở (nếu có)
          Chapter? activeChapter;
          for (final c in chapters) {
            if (c.isActive) {
              activeChapter = c;
              break;
            }
          }

          return Stack(
            children: [
              // Danh sách chương có tính năng Kéo để làm mới
              RefreshIndicator(
                color: colors.primaryBrand,
                backgroundColor: colors.bgSurface,
                onRefresh: () => ref
                    .read(chapterListViewModelProvider(seriesId).notifier)
                    .refresh(),
                child: ListView.builder(
                  padding: EdgeInsets.only(
                    top: AppDimensions.space2,
                    bottom: activeChapter != null ? 96.0 : AppDimensions.space4,
                  ),
                  itemCount: chapters.length,
                  itemBuilder: (context, index) {
                    final chapter = chapters[index];
                    return ChapterItem(
                      chapter: chapter,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChapterDetailScreen(
                              chapterId: chapter.id,
                              seriesTitle: seriesTitle,
                              allChapters: chapters,
                            ),
                          ),
                        );
                      },
                      onDownloadTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã lưu Ch. ${chapter.sortOrder} vào bộ nhớ đọc offline.',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Thanh nút ghim đáy tiếp tục đọc (Chỉ hiện khi có active chapter)
              if (activeChapter != null)
                ResumeReadingBar(
                  title: 'Ch. ${activeChapter.sortOrder}',
                  progressPercentage:
                      (activeChapter.readPercentage * 100).toInt(),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChapterDetailScreen(
                          chapterId: activeChapter!.id,
                          seriesTitle: seriesTitle,
                          allChapters: chapters,
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
