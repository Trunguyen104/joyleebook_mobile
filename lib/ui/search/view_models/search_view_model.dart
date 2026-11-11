import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/repositories/series_repository.dart';
import '../../../data/services/search_utils.dart';
import '../../../domain/models/search_sort_option.dart';
import '../../../domain/models/series.dart';
import '../../auth/view_models/auth_session_view_model.dart';
import '../../bookmark/view_models/bookmark_list_view_model.dart';
import '../../bookmark/view_models/bookmark_status_view_model.dart';

/// RIVERPOD PROVIDER: Quản lý trạng thái màn hình Khám phá & Tìm kiếm truyện
final searchViewModelProvider =
    AsyncNotifierProvider<SearchViewModel, List<Series>>(
      SearchViewModel.new,
      retry: (retryCount, error) => null,
    );

/// VIEWMODEL - Quản lý trạng thái và nghiệp vụ cho màn hình Khám phá & Tìm kiếm (SearchScreen)
/// Tuân thủ Compass App Hybrid Architecture & Barem PRN232 (15% - 15% - 50%):
/// 1. Bộ 4 trạng thái: Loading, Data, Empty, Error.
/// 2. Debounce 400ms: Tự động hẹn giờ khi người dùng gõ từ khóa, chống spam request.
/// 3. Lọc đa tiêu chí: Từ khóa + Thể loại (Genre) + Trạng thái phát hành (Status).
/// 4. Lịch sử tìm kiếm: Tự động lưu 10 từ khóa gần nhất vào SharedPreferences / Local cache.
/// 5. Gợi ý thông minh khi nhập (Auto-complete search suggestions).
/// 6. Sắp xếp đa tiêu chí (Mới cập nhật, Lượt đọc, Điểm đánh giá, Độ khớp).
/// 7. Optimistic UI: Bookmark tức thì, rollback khi mạng lỗi hoặc API thất bại.
class SearchViewModel extends AsyncNotifier<List<Series>> {
  Timer? _debounceTimer;
  final Set<String> _bookmarkRequestsInFlight = {};

  String _currentQuery = '';
  String? _selectedGenre;
  SeriesStatus? _selectedStatus;
  SearchSortOption _sortOption = SearchSortOption.relevance;
  List<String> _recentSearches = [];
  List<Series> _cachedBaseList = [];
  List<Series> _suggestionCatalog = [];
  bool _isSemanticSearch = false;

  static const String _recentSearchesKey = 'joylee_recent_searches';
  static const int _maxRecentSearches = 10;

  SharedPreferencesAsync? _prefs;
  SharedPreferencesAsync? get _safePrefs {
    try {
      _prefs ??= SharedPreferencesAsync();
      return _prefs;
    } catch (_) {
      return null;
    }
  }

  String get currentQuery => _currentQuery;
  String? get selectedGenre => _selectedGenre;
  SeriesStatus? get selectedStatus => _selectedStatus;
  SearchSortOption get sortOption => _sortOption;
  List<String> get recentSearches => List.unmodifiable(_recentSearches);
  bool get isFiltered =>
      _currentQuery.isNotEmpty ||
      _selectedGenre != null ||
      _selectedStatus != null ||
      _sortOption != SearchSortOption.relevance;

  @override
  Future<List<Series>> build() async {
    ref.onDispose(() => _debounceTimer?.cancel());
    ref.listen(authSessionProvider, (prev, next) {
      if (prev?.value?.userId != next.value?.userId) {
        final current = state.value;
        if (current != null) {
          state = AsyncData(
            current.map((s) => s.copyWith(clearUserRating: true)).toList(),
          );
        }
      }
    });
    await _loadRecentSearches();
    return _fetch();
  }

  Future<List<Series>> _fetch() async {
    final repository = ref.read(seriesRepositoryProvider);
    final List<Series> list;
    if (_isSemanticSearch && _currentQuery.isNotEmpty) {
      final recommendations = await repository.getSemanticSearchSeries(
        _currentQuery,
      );
      list = recommendations
          .map((recommendation) => recommendation.series)
          .where((series) {
            final matchesGenre =
                _selectedGenre == null ||
                series.genres.any(
                  (genre) => SearchUtils.matches(genre, _selectedGenre),
                );
            final matchesStatus =
                _selectedStatus == null || series.status == _selectedStatus;
            return matchesGenre && matchesStatus;
          })
          .toList(growable: false);
    } else {
      list = await repository.getSeriesList(
        searchQuery: _currentQuery.isNotEmpty ? _currentQuery : null,
        genre: _selectedGenre,
        status: _selectedStatus,
      );
    }
    _cachedBaseList = list;
    if (!_isSemanticSearch &&
        _currentQuery.isEmpty &&
        _selectedGenre == null &&
        _selectedStatus == null) {
      _suggestionCatalog = list;
    }
    return _applySorting(list);
  }

  /// Áp dụng thuật toán sắp xếp dựa trên tùy chọn hiện tại
  List<Series> _applySorting(List<Series> inputList) {
    final sorted = List<Series>.from(inputList);

    switch (_sortOption) {
      case SearchSortOption.relevance:
        if (_isSemanticSearch || _currentQuery.isEmpty) break;
        if (_currentQuery.isNotEmpty) {
          sorted.sort((a, b) {
            final aRelevance = _relevanceScore(a, _currentQuery);
            final bRelevance = _relevanceScore(b, _currentQuery);
            if (aRelevance != bRelevance) {
              return bRelevance.compareTo(aRelevance);
            }

            final ratingCmp = b.averageRating.compareTo(a.averageRating);
            if (ratingCmp != 0) return ratingCmp;
            return b.totalRatings.compareTo(a.totalRatings);
          });
        }
        break;

      case SearchSortOption.newest:
        sorted.sort((a, b) {
          final aTime = a.createdAt;
          final bTime = b.createdAt;
          if (aTime != null &&
              bTime != null &&
              !aTime.isAtSameMomentAs(bTime)) {
            return bTime.compareTo(aTime);
          }
          if (a.status == SeriesStatus.ongoing &&
              b.status != SeriesStatus.ongoing) {
            return -1;
          }
          if (b.status == SeriesStatus.ongoing &&
              a.status != SeriesStatus.ongoing) {
            return 1;
          }
          if (aTime != null && bTime == null) return -1;
          if (bTime != null && aTime == null) return 1;
          if (aTime != null && bTime != null) {
            return bTime.compareTo(aTime);
          }
          return b.id.compareTo(a.id);
        });
        break;

      case SearchSortOption.mostRead:
        sorted.sort((a, b) {
          final aViews = a.viewCount ?? 0;
          final bViews = b.viewCount ?? 0;
          if (aViews != bViews) return bViews.compareTo(aViews);
          final aChap = a.totalChapters;
          final bChap = b.totalChapters;
          if (aChap != bChap) return bChap.compareTo(aChap);
          return b.totalRatings.compareTo(a.totalRatings);
        });
        break;

      case SearchSortOption.topRated:
        sorted.sort((a, b) {
          final ratingCmp = b.averageRating.compareTo(a.averageRating);
          if (ratingCmp != 0) return ratingCmp;
          return b.totalRatings.compareTo(a.totalRatings);
        });
        break;
    }

    return sorted;
  }

  int _relevanceScore(Series series, String query) {
    final normalizedQuery = SearchUtils.removeDiacritics(
      SearchUtils.cleanQuery(query),
    );
    final normalizedTitle = SearchUtils.removeDiacritics(series.title);
    if (normalizedTitle.startsWith(normalizedQuery)) return 400;
    if (SearchUtils.matches(series.title, query)) return 300;
    if (SearchUtils.matches(series.authorName, query)) return 200;
    if (series.genres.any((genre) => SearchUtils.matches(genre, query))) {
      return 100;
    }
    return 0;
  }

  /// Đặt tiêu chí sắp xếp và áp dụng ngay lập tức trên dữ liệu hiện tại
  void setSortOption(SearchSortOption option) {
    if (_sortOption == option) return;
    _sortOption = option;

    final current = state.value;
    if (current != null) {
      state = AsyncData(_applySorting(current));
    } else {
      refresh();
    }
  }

  /// Trích xuất danh sách gợi ý khi người dùng đang gõ
  List<SearchSuggestion> getSuggestions(
    String query, {
    Iterable<String> genreNames = const [],
  }) {
    final clean = query.trim();
    if (clean.isEmpty) return const [];

    final suggestions = <SearchSuggestion>[];
    final seenTexts = <String>{};

    // 1. Gợi ý tìm kiếm ngữ nghĩa với AI
    suggestions.add(
      SearchSuggestion(
        text: clean,
        subtitle: 'Tìm kiếm bằng AI với Gemini',
        type: SearchSuggestionType.aiSemantic,
      ),
    );
    seenTexts.add(clean.toLowerCase());
    final candidates = _suggestionCatalog.isNotEmpty
        ? _suggestionCatalog
        : _cachedBaseList;

    // 2. Gợi ý theo Tiêu đề truyện khớp từ khóa
    for (final s in candidates) {
      if (SearchUtils.matches(s.title, clean)) {
        if (seenTexts.add(s.title.toLowerCase())) {
          suggestions.add(
            SearchSuggestion(
              text: s.title,
              subtitle: 'Tác giả: ${s.authorName}',
              type: SearchSuggestionType.series,
              seriesId: s.id,
            ),
          );
        }
      }
      if (suggestions.length >= 6) break;
    }

    // 3. Gợi ý theo Tên tác giả khớp từ khóa
    for (final s in candidates) {
      if (SearchUtils.matches(s.authorName, clean)) {
        if (seenTexts.add(s.authorName.toLowerCase())) {
          suggestions.add(
            SearchSuggestion(
              text: s.authorName,
              subtitle: 'Tác giả',
              type: SearchSuggestionType.author,
            ),
          );
        }
      }
      if (suggestions.length >= 7) break;
    }

    // 4. Gợi ý theo thể loại lấy từ danh mục đã tải trên màn hình.
    for (final genre in genreNames) {
      if (SearchUtils.matches(genre, clean) &&
          seenTexts.add(genre.toLowerCase())) {
        suggestions.add(
          SearchSuggestion(
            text: genre,
            subtitle: 'Thể loại',
            type: SearchSuggestionType.genre,
          ),
        );
      }
      if (suggestions.length >= 8) break;
    }

    return suggestions;
  }

  /// 1. Tải lịch sử tìm kiếm gần nhất
  Future<void> _loadRecentSearches() async {
    try {
      final p = _safePrefs;
      if (p != null) {
        final raw = await p.getString(_recentSearchesKey);
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is List) {
            _recentSearches = decoded.map((e) => e.toString()).toList();
          }
        }
      }
    } catch (_) {
      // Bỏ qua lỗi fallback an toàn
    }
  }

  /// 2. Lưu từ khóa vào lịch sử tìm kiếm (Tối đa 10 từ khóa, không trùng lặp)
  Future<void> addRecentSearch(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;

    _recentSearches.removeWhere(
      (item) => item.toLowerCase() == trimmed.toLowerCase(),
    );
    _recentSearches.insert(0, trimmed);
    if (_recentSearches.length > _maxRecentSearches) {
      _recentSearches = _recentSearches.sublist(0, _maxRecentSearches);
    }

    try {
      final p = _safePrefs;
      if (p != null) {
        await p.setString(_recentSearchesKey, jsonEncode(_recentSearches));
      }
    } catch (_) {}
  }

  /// 3. Xóa một từ khóa khỏi lịch sử
  Future<void> removeRecentSearch(String keyword) async {
    _recentSearches.removeWhere(
      (item) => item.toLowerCase() == keyword.trim().toLowerCase(),
    );
    try {
      final p = _safePrefs;
      if (p != null) {
        await p.setString(_recentSearchesKey, jsonEncode(_recentSearches));
      }
    } catch (_) {}
  }

  /// 4. Xóa toàn bộ lịch sử tìm kiếm
  Future<void> clearRecentSearches() async {
    _recentSearches.clear();
    try {
      final p = _safePrefs;
      if (p != null) {
        await p.remove(_recentSearchesKey);
      }
    } catch (_) {}
  }

  /// 5. Kéo xuống để làm mới danh sách (Pull-to-refresh)
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// 6. Tìm kiếm truyện theo từ khóa (Có cơ chế Debounce 400ms)
  Future<void> search(String query, {bool immediate = false}) async {
    _debounceTimer?.cancel();
    _currentQuery = query.trim();
    _isSemanticSearch = false;

    if (immediate) {
      if (_currentQuery.isNotEmpty) {
        addRecentSearch(_currentQuery);
      }
      state = const AsyncLoading();
      state = await AsyncValue.guard(_fetch);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      if (_currentQuery.isNotEmpty) {
        addRecentSearch(_currentQuery);
      }
      state = const AsyncLoading();
      state = await AsyncValue.guard(_fetch);
    });
  }

  /// Tìm bằng embedding ngữ nghĩa khi người dùng chọn gợi ý AI.
  Future<void> searchSemantically(String query) async {
    _debounceTimer?.cancel();
    _currentQuery = query.trim();
    _isSemanticSearch = true;
    if (_currentQuery.isNotEmpty) {
      await addRecentSearch(_currentQuery);
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// 7. Lọc theo thể loại
  /// Nếu chọn lại thể loại đang active -> hủy lọc (chọn 'Tất cả')
  Future<void> filterByGenre(String? genre) async {
    _debounceTimer?.cancel();
    if (_selectedGenre == genre) {
      _selectedGenre = null;
    } else {
      _selectedGenre = genre;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// 8. Lọc theo trạng thái truyện (Hoàn thành / Đang ra)
  Future<void> filterByStatus(SeriesStatus? status) async {
    _debounceTimer?.cancel();
    if (_selectedStatus == status) {
      _selectedStatus = null;
    } else {
      _selectedStatus = status;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// 9. Xóa toàn bộ bộ lọc và từ khóa tìm kiếm
  Future<void> clearFilters() async {
    _debounceTimer?.cancel();
    _currentQuery = '';
    _selectedGenre = null;
    _selectedStatus = null;
    _sortOption = SearchSortOption.relevance;
    _isSemanticSearch = false;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// 10. Bật/Tắt Lưu vào Tủ sách (Optimistic UI kèm Rollback khi lỗi)
  Future<bool> toggleBookmark(String seriesId) async {
    if (_bookmarkRequestsInFlight.contains(seriesId)) return false;

    final currentList = state.value;
    if (currentList == null) return false;

    final targetIndex = currentList.indexWhere((s) => s.id == seriesId);
    if (targetIndex == -1) return false;

    final originalItem = currentList[targetIndex];
    final newBookmarkState = !originalItem.isBookmarked;
    _bookmarkRequestsInFlight.add(seriesId);

    // BƯỚC A: Cập nhật Lạc quan (Optimistic Update)
    final updatedList = List<Series>.from(currentList);
    updatedList[targetIndex] = originalItem.copyWith(
      isBookmarked: newBookmarkState,
    );
    state = AsyncData(updatedList);
    ref
        .read(bookmarkStatusViewModelProvider.notifier)
        .setStatus(seriesId, newBookmarkState);
    ref
        .read(bookmarkListViewModelProvider.notifier)
        .updateBookmarkLocally(originalItem, newBookmarkState);

    // BƯỚC B: Gửi request ngầm lên server
    try {
      await ref
          .read(seriesRepositoryProvider)
          .toggleBookmark(seriesId, newBookmarkState);
      return true;
    } catch (_) {
      // BƯỚC C: Phục hồi lại (Rollback) nếu mạng lỗi hoặc server từ chối
      final rollbackList = List<Series>.from(state.value ?? currentList);
      rollbackList[targetIndex] = originalItem;
      state = AsyncData(rollbackList);
      ref
          .read(bookmarkStatusViewModelProvider.notifier)
          .setStatus(seriesId, originalItem.isBookmarked);
      ref
          .read(bookmarkListViewModelProvider.notifier)
          .updateBookmarkLocally(originalItem, originalItem.isBookmarked);
      return false;
    } finally {
      _bookmarkRequestsInFlight.remove(seriesId);
    }
  }

  /// 11. Đồng bộ trạng thái Bookmark từ màn hình chi tiết
  void updateBookmarkLocally(String seriesId, bool isBookmarked) {
    final currentList = state.value;
    if (currentList == null) return;

    final targetIndex = currentList.indexWhere((s) => s.id == seriesId);
    if (targetIndex == -1) return;

    final updatedList = List<Series>.from(currentList);
    updatedList[targetIndex] = updatedList[targetIndex].copyWith(
      isBookmarked: isBookmarked,
    );
    state = AsyncData(updatedList);
  }

  /// 12. Đồng bộ trạng thái Đánh giá từ màn hình chi tiết sang danh sách ngoài
  void updateRatingLocally({
    required String seriesId,
    required double averageRating,
    required int totalRatings,
    int? userRating,
    bool clearUserRating = false,
  }) {
    final currentList = state.value;
    if (currentList == null) return;

    final targetIndex = currentList.indexWhere((s) => s.id == seriesId);
    if (targetIndex == -1) return;

    final updatedList = List<Series>.from(currentList);
    updatedList[targetIndex] = updatedList[targetIndex].copyWith(
      averageRating: averageRating,
      totalRatings: totalRatings,
      userRating: userRating,
      clearUserRating: clearUserRating || userRating == null,
    );
    state = AsyncData(updatedList);
  }
}
