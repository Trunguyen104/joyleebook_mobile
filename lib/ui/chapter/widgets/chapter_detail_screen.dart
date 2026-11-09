import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/dtos/upsert_reading_progress_dto.dart';
import '../../../data/repositories/series_repository.dart';
import '../../../data/services/api_exceptions.dart';
import '../../../data/services/reading_preferences_service.dart';
import '../../../domain/models/chapter.dart';
import '../../../domain/models/chapter_detail.dart';
import '../../../domain/models/reading_progress.dart';
import '../../../routing/app_paths.dart';
import '../../auth/view_models/auth_session_view_model.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/themes/theme_provider.dart';
import '../../core/widgets/joylee_empty_state.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../view_models/chapter_detail_view_model.dart';
import '../view_models/chapter_list_view_model.dart';
import '../../comments/widgets/chapter_comments_sheet.dart';

/// MÀN HÌNH ĐỌC TRUYỆN / NỘI DUNG CHƯƠNG (ChapterDetailScreen)
/// Thiết kế chuẩn Warm Editorial tối ưu cho trải nghiệm đọc lâu dài:
/// - Chạm vào màn hình để ẩn/hiện header & footer, tăng không gian đọc
/// - Chỉnh cỡ chữ linh hoạt (A- / A+) và tự động lưu vào SharedPreferences
/// - Đổi giao diện Sáng / Tối trực tiếp
/// - Điều hướng chuyển Chương trước / Chương sau mượt mà
/// - Đảm bảo đủ 4 trạng thái: Loading, Error, Empty, Data
class ChapterDetailScreen extends ConsumerStatefulWidget {
  const ChapterDetailScreen({
    super.key,
    required this.seriesId,
    required this.chapterId,
    required this.seriesTitle,
  });

  final String seriesId;
  final String chapterId;
  final String seriesTitle;

  @override
  ConsumerState<ChapterDetailScreen> createState() =>
      _ChapterDetailScreenState();
}

class _ChapterDetailScreenState extends ConsumerState<ChapterDetailScreen> {
  // Cỡ chữ nội dung đọc (mặc định 17.0, có thể tăng/giảm từ 13.0 -> 25.0)
  double _fontSize = 17.0;

  // Controller cuộn trang để reset về đầu trang khi đổi chương
  final ScrollController _scrollController = ScrollController();
  Timer? _progressDebounce;
  ChapterDetail? _activeDetail;
  String? _activeProgressChapterId;
  String? _lastSyncedChapterId;
  String? _lastStoredChapterId;
  double? _lastSyncedProgress;
  double? _lastStoredProgress;
  double? _pendingProgress;
  bool _isSyncingProgress = false;
  bool _isRestoringProgress = false;
  bool _hasRestoredProgress = false;
  Future<void>? _fontSizeFuture;

  // Trạng thái ẩn/hiện thanh header & footer để tối đa không gian đọc
  static const Duration _chromeAnimationDuration = Duration(milliseconds: 250);
  static const Duration _chromeOpacityDuration = Duration(milliseconds: 200);
  static const double _footerHeight = 56.0;
  bool _isChromeVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scheduleProgressSync);
    _fontSizeFuture = _loadSavedFontSize();
  }

  @override
  void dispose() {
    _progressDebounce?.cancel();
    _scrollController.removeListener(_scheduleProgressSync);
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleChrome() {
    setState(() => _isChromeVisible = !_isChromeVisible);
  }

  void _scheduleProgressSync() {
    if (_isRestoringProgress) return;
    final detail = _activeDetail;
    final progress = _currentProgress();
    if (detail != null &&
        (_lastStoredChapterId != detail.id ||
            _lastStoredProgress == null ||
            progress - _lastStoredProgress! >= 0.02)) {
      _lastStoredChapterId = detail.id;
      _lastStoredProgress = progress;
      unawaited(
        ref
            .read(readingPreferencesServiceProvider)
            .saveReadingProgress(
              seriesId: detail.seriesId,
              chapterId: detail.id,
              sortOrder: detail.sortOrder,
              readPercentage: progress,
            ),
      );
    }

    _progressDebounce?.cancel();
    _progressDebounce = Timer(
      const Duration(milliseconds: 700),
      () => unawaited(_syncProgress(_currentProgress())),
    );
  }

  double _currentProgress() {
    if (!_scrollController.hasClients) return 0;
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return 1;
    return (position.pixels / position.maxScrollExtent).clamp(0.0, 1.0);
  }

  Future<void> _syncProgress(double progress, {bool showError = true}) async {
    if (_isRestoringProgress || _activeDetail == null) return;

    _pendingProgress = progress > (_pendingProgress ?? 0)
        ? progress
        : _pendingProgress;
    if (_isSyncingProgress) return;
    _isSyncingProgress = true;
    String? syncingChapterId;
    final readingPreferences = ref.read(readingPreferencesServiceProvider);
    final authSession = ref.read(authSessionProvider.future);
    final seriesRepository = ref.read(seriesRepositoryProvider);

    try {
      while (_pendingProgress != null) {
        final detail = _activeDetail;
        if (detail == null) break;
        syncingChapterId = detail.id;
        final value = _pendingProgress!;
        _pendingProgress = null;
        if (_lastSyncedChapterId == detail.id &&
            _lastSyncedProgress != null &&
            value - _lastSyncedProgress! < 0.02 &&
            value < 1) {
          continue;
        }

        await readingPreferences.saveReadingProgress(
          seriesId: detail.seriesId,
          chapterId: detail.id,
          sortOrder: detail.sortOrder,
          readPercentage: value,
        );
        // Cập nhật ngay danh sách chương đang nằm dưới trình đọc để khi quay ra
        // không còn hiển thị chương cũ.
        ref
            .read(chapterListViewModelProvider(detail.seriesId).notifier)
            .updateProgressLocally(
              chapterId: detail.id,
              sortOrder: detail.sortOrder,
              progress: value,
              isCompleted: value >= 0.99,
            );
        final session = await authSession;
        if (session == null) {
          _lastSyncedProgress = value;
          _lastSyncedChapterId = detail.id;
          continue;
        }
        await seriesRepository.updateReadingProgress(
          UpsertReadingProgressDto(
            seriesId: detail.seriesId,
            chapterId: detail.id,
            chapterSortOrder: detail.sortOrder,
            scrollPercentage: value * 100,
            isCompleted: value >= 0.99,
            readAtUtc: DateTime.now().toUtc(),
          ),
        );
        _lastSyncedProgress = value;
        _lastSyncedChapterId = detail.id;
      }
    } catch (error) {
      if (showError && mounted && _activeDetail?.id == syncingChapterId) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is AppException
                  ? error.message
                  : 'Không thể cập nhật tiến độ đọc.',
            ),
          ),
        );
      }
    } finally {
      _isSyncingProgress = false;
    }
  }

  /// Khôi phục vị trí cuộn đã lưu của chương hiện tại rồi mới ghi nhận tiến độ.
  /// Server là nguồn chính; bản local chỉ dùng khi chưa đăng nhập hoặc lỗi mạng.
  Future<void> _restoreProgressAndSync(ChapterDetail detail) async {
    if (_hasRestoredProgress) return;
    _hasRestoredProgress = true;
    _isRestoringProgress = true;

    // Chờ cỡ chữ đã lưu được áp dụng để đo đúng chiều cao nội dung.
    await _fontSizeFuture;
    final saved = await _loadSavedProgress(detail.seriesId);
    if (!mounted || _activeDetail?.id != detail.id) {
      _isRestoringProgress = false;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _activeDetail?.id != detail.id) {
        _isRestoringProgress = false;
        return;
      }

      if (saved != null &&
          _matchesChapter(saved, detail) &&
          _scrollController.hasClients &&
          _scrollController.position.pixels <= 0) {
        final maxExtent = _scrollController.position.maxScrollExtent;
        final target = saved.progress.clamp(0.0, 1.0) * maxExtent;
        if (target > 0) {
          _scrollController.jumpTo(target);
        }
      }

      _isRestoringProgress = false;
      unawaited(_syncProgress(_currentProgress()));
    });
  }

  Future<ReadingProgress?> _loadSavedProgress(String seriesId) async {
    final session = ref.read(authSessionProvider).value;
    if (session != null) {
      try {
        final serverProgress = await ref
            .read(seriesRepositoryProvider)
            .getReadingProgressDetail(seriesId);
        // Server xác nhận chưa có tiến độ -> không dùng bản local cũ.
        return serverProgress;
      } catch (_) {
        // Lỗi mạng: tạm dùng tiến độ lưu cục bộ.
      }
    }

    final local = await ref
        .read(readingPreferencesServiceProvider)
        .getLastReadProgress(seriesId);
    if (local == null) return null;
    return ReadingProgress(
      seriesId: local.seriesId,
      chapterId: local.chapterId,
      chapterSortOrder: local.sortOrder,
      progress: local.readPercentage,
    );
  }

  bool _matchesChapter(ReadingProgress progress, ChapterDetail detail) {
    if (progress.chapterId != null && progress.chapterId!.isNotEmpty) {
      return progress.chapterId == detail.id;
    }
    return progress.chapterSortOrder == detail.sortOrder;
  }

  /// Nạp cỡ chữ đã lưu từ SharedPreferences
  Future<void> _loadSavedFontSize() async {
    final savedSize = await ref
        .read(readingPreferencesServiceProvider)
        .getFontSize();
    if (mounted) {
      setState(() => _fontSize = savedSize);
    }
  }

  void _increaseFontSize() {
    if (_fontSize < 25.0) {
      final newSize = _fontSize + 1.5;
      setState(() => _fontSize = newSize);
      ref.read(readingPreferencesServiceProvider).setFontSize(newSize);
    }
  }

  void _decreaseFontSize() {
    if (_fontSize > 13.0) {
      final newSize = _fontSize - 1.5;
      setState(() => _fontSize = newSize);
      ref.read(readingPreferencesServiceProvider).setFontSize(newSize);
    }
  }

  /// Đổi sang chương khác: thay trang hiện tại để nút Back vẫn về màn trước đó
  void _navigateToChapter(Chapter chapter) {
    _progressDebounce?.cancel();
    unawaited(_syncProgress(_currentProgress()));
    context.pushReplacement(
      AppPaths.chapterReader(widget.seriesId, chapter.id),
      extra: widget.seriesTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chapterDetailViewModelProvider(widget.chapterId));
    final mediaQuery = MediaQuery.of(context);
    final topInset = mediaQuery.padding.top;
    final bottomInset = mediaQuery.padding.bottom;
    final detail = state.whenOrNull(data: (value) => value);
    final hasReadableContent =
        detail != null && detail.content.trim().isNotEmpty;

    final chaptersList =
        ref.watch(chapterListViewModelProvider(widget.seriesId)).value ??
        <Chapter>[];
    Chapter? previousChapter;
    Chapter? nextChapter;
    if (detail != null && chaptersList.isNotEmpty) {
      for (final c in chaptersList) {
        if (c.sortOrder == detail.sortOrder - 1) {
          previousChapter = c;
        } else if (c.sortOrder == detail.sortOrder + 1) {
          nextChapter = c;
        }
      }
    }

    return Scaffold(
      backgroundColor: context.colors.bgCanvas,
      body: Stack(
        children: [
          // Nội dung đọc: chạm vào đây để ẩn/hiện thanh công cụ
          Positioned.fill(
            child: AnimatedPadding(
              duration: _chromeAnimationDuration,
              curve: Curves.easeInOut,
              padding: EdgeInsets.only(
                top: _isChromeVisible ? topInset + kToolbarHeight : topInset,
                bottom: hasReadableContent && _isChromeVisible
                    ? bottomInset + _footerHeight
                    : bottomInset,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleChrome,
                child: _buildBody(state),
              ),
            ),
          ),

          // Header trượt lên khỏi màn hình khi ẩn
          Positioned(top: 0, left: 0, right: 0, child: _buildHeader(state)),

          // Footer trượt xuống khỏi màn hình khi ẩn
          if (hasReadableContent)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildFooter(
                detail: detail,
                previousChapter: previousChapter,
                nextChapter: nextChapter,
                bottomInset: bottomInset,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(AsyncValue<ChapterDetail> state) {
    final colors = context.colors;

    return AnimatedSlide(
      key: const Key('chapter-reader-header'),
      duration: _chromeAnimationDuration,
      curve: Curves.easeInOut,
      offset: _isChromeVisible ? Offset.zero : const Offset(0, -1),
      child: IgnorePointer(
        ignoring: !_isChromeVisible,
        child: AnimatedOpacity(
          opacity: _isChromeVisible ? 1 : 0,
          duration: _chromeOpacityDuration,
          child: AppBar(
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
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                  orElse: () => Text(
                    'Đang tải...',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            ),
            actions: [
              // Nút giảm cỡ chữ (A-)
              IconButton(
                icon: const Text(
                  'A-',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                tooltip: 'Giảm cỡ chữ',
                onPressed: _fontSize > 13.0 ? _decreaseFontSize : null,
              ),

              // Nút tăng cỡ chữ (A+)
              IconButton(
                icon: const Text(
                  'A+',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                tooltip: 'Tăng cỡ chữ',
                onPressed: _fontSize < 25.0 ? _increaseFontSize : null,
              ),

              // Nút đổi theme Sáng / Tối
              IconButton(
                icon: Icon(
                  ref.watch(themeModeProvider) == ThemeMode.dark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                ),
                tooltip: 'Đổi giao diện Sáng / Tối',
                onPressed: () =>
                    ref.read(themeModeProvider.notifier).toggleTheme(),
              ),

              // Nút xem bình luận chương
              state.maybeWhen(
                data: (detail) => IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  tooltip: 'Bình luận chương',
                  onPressed: () => ChapterCommentsSheet.show(
                    context,
                    seriesId: widget.seriesId,
                    chapterId: detail.id,
                    chapterTitle: detail.title,
                    sortOrder: detail.sortOrder,
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter({
    required ChapterDetail detail,
    required Chapter? previousChapter,
    required Chapter? nextChapter,
    required double bottomInset,
  }) {
    final colors = context.colors;

    return AnimatedSlide(
      key: const Key('chapter-reader-footer'),
      duration: _chromeAnimationDuration,
      curve: Curves.easeInOut,
      offset: _isChromeVisible ? Offset.zero : const Offset(0, 1),
      child: IgnorePointer(
        ignoring: !_isChromeVisible,
        child: AnimatedOpacity(
          opacity: _isChromeVisible ? 1 : 0,
          duration: _chromeOpacityDuration,
          child: Container(
            padding: EdgeInsets.only(bottom: bottomInset),
            decoration: BoxDecoration(
              color: colors.bgSurface,
              border: Border(
                top: BorderSide(
                  color: colors.borderDefault.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: SizedBox(
              height: _footerHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space4,
                  vertical: AppDimensions.space2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nút Chương trước
                    TextButton.icon(
                      onPressed: previousChapter != null
                          ? () => _navigateToChapter(previousChapter)
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
                          ? () => _navigateToChapter(nextChapter)
                          : null,
                      icon: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                      ),
                      label: const Text('Chương sau'),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primaryBrand,
                        disabledForegroundColor: colors.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AsyncValue<ChapterDetail> state) {
    final colors = context.colors;

    return state.when(
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

        _activeDetail = detail;
        if (_activeProgressChapterId != detail.id) {
          _activeProgressChapterId = detail.id;
          _lastSyncedProgress = null;
          _lastSyncedChapterId = null;
          _lastStoredProgress = null;
          _lastStoredChapterId = null;
          _pendingProgress = null;
          _hasRestoredProgress = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _activeDetail?.id == detail.id) {
              unawaited(_restoreProgressAndSync(detail));
            }
          });
        }

        // Tách nội dung thành từng đoạn văn
        final paragraphs = detail.content
            .split('\n')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();

        // Khung đọc nội dung cuộn mượt mà
        return SingleChildScrollView(
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
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
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
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space3),
              Divider(color: colors.borderDefault.withValues(alpha: 0.5)),
              const SizedBox(height: AppDimensions.space3),

              // Nội dung từng đoạn văn bản
              ...paragraphs.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.space4),
                  child: Text(
                    p,
                    style: TextStyle(
                      fontSize: _fontSize,
                      height: 1.85, // Giãn dòng rộng rãi chống mỏi mắt
                      color: colors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),

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
              const SizedBox(height: AppDimensions.space4),
              Center(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primaryBrand,
                    side: BorderSide(
                      color: colors.primaryBrand.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space4,
                      vertical: AppDimensions.space2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLg,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                  label: const Text('Bình luận chương này'),
                  onPressed: () => ChapterCommentsSheet.show(
                    context,
                    seriesId: widget.seriesId,
                    chapterId: detail.id,
                    chapterTitle: detail.title,
                    sortOrder: detail.sortOrder,
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space6),
            ],
          ),
        );
      },
    );
  }
}
