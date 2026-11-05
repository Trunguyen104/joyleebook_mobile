import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/repositories/series_repository.dart';
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
/// 5. Optimistic UI: Bookmark tức thì, rollback khi mạng lỗi hoặc API thất bại.
class SearchViewModel extends AsyncNotifier<List<Series>> {
  Timer? _debounceTimer;
  final Set<String> _bookmarkRequestsInFlight = {};

  String _currentQuery = '';
  String? _selectedGenre;
  SeriesStatus? _selectedStatus;
  List<String> _recentSearches = [];

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
  List<String> get recentSearches => List.unmodifiable(_recentSearches);
  bool get isFiltered =>
      _currentQuery.isNotEmpty ||
      _selectedGenre != null ||
      _selectedStatus != null;

  @override
  Future<List<Series>> build() async {
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

  Future<List<Series>> _fetch() {
    return ref.read(seriesRepositoryProvider).getSeriesList(
          searchQuery: _currentQuery.isNotEmpty ? _currentQuery : null,
          genre: _selectedGenre,
          status: _selectedStatus,
        );
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

    _recentSearches.removeWhere((item) => item.toLowerCase() == trimmed.toLowerCase());
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
    _recentSearches.removeWhere((item) => item.toLowerCase() == keyword.trim().toLowerCase());
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

    if (_currentQuery.isNotEmpty) {
      addRecentSearch(_currentQuery);
    }

    if (immediate) {
      state = const AsyncLoading();
      state = await AsyncValue.guard(_fetch);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      state = const AsyncLoading();
      state = await AsyncValue.guard(_fetch);
    });
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
