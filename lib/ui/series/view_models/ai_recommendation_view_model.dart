import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/series_repository.dart';
import '../../../domain/models/ai_recommendation.dart';
import '../../auth/view_models/auth_session_view_model.dart';

/// Trạng thái của khối Gợi ý AI trên Trang chủ
@immutable
class AiRecommendationState {
  /// Danh sách kết quả gợi ý
  final List<AiRecommendation> items;

  /// Tiêu đề của bộ truyện nguồn (nếu gợi ý dựa trên lịch sử đọc)
  final String? sourceSeriesTitle;

  /// Từ khóa hoặc câu mô tả gu đọc đang được áp dụng (nếu có)
  final String? activePrompt;

  /// Nhãn của chip thể loại đang được chọn (nếu có)
  final String? activeChip;

  const AiRecommendationState({
    this.items = const [],
    this.sourceSeriesTitle,
    this.activePrompt,
    this.activeChip,
  });

  AiRecommendationState copyWith({
    List<AiRecommendation>? items,
    String? sourceSeriesTitle,
    String? activePrompt,
    String? activeChip,
    bool clearSourceSeries = false,
    bool clearPrompt = false,
    bool clearChip = false,
  }) {
    return AiRecommendationState(
      items: items ?? this.items,
      sourceSeriesTitle: clearSourceSeries
          ? null
          : (sourceSeriesTitle ?? this.sourceSeriesTitle),
      activePrompt: clearPrompt ? null : (activePrompt ?? this.activePrompt),
      activeChip: clearChip ? null : (activeChip ?? this.activeChip),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiRecommendationState &&
          runtimeType == other.runtimeType &&
          listEquals(items, other.items) &&
          sourceSeriesTitle == other.sourceSeriesTitle &&
          activePrompt == other.activePrompt &&
          activeChip == other.activeChip;

  @override
  int get hashCode =>
      items.hashCode ^
      sourceSeriesTitle.hashCode ^
      activePrompt.hashCode ^
      activeChip.hashCode;
}

/// RIVERPOD PROVIDER: Quản lý gợi ý truyện AI trên Trang chủ
final aiRecommendationViewModelProvider =
    AsyncNotifierProvider<AiRecommendationViewModel, AiRecommendationState>(
      AiRecommendationViewModel.new,
      retry: (retryCount, error) => null,
    );

/// RIVERPOD PROVIDER: Lấy danh sách truyện tương tự bằng AI cho một bộ truyện cụ thể (US-64)
final similarSeriesProvider =
    FutureProvider.family<List<AiRecommendation>, String>((ref, seriesId) {
      final repo = ref.watch(seriesRepositoryProvider);
      return repo.getSimilarSeries(seriesId, limit: 6);
    });

class AiRecommendationViewModel extends AsyncNotifier<AiRecommendationState> {
  static const String defaultSemanticPrompt = 'truyện hay đặc sắc hấp dẫn';

  @override
  Future<AiRecommendationState> build() async {
    // Lắng nghe thay đổi tài khoản để tải lại gợi ý cá nhân hóa
    ref.listen(authSessionProvider, (prev, next) {
      if (prev?.value?.userId != next.value?.userId) {
        refresh();
      }
    });

    return _fetchInitial();
  }

  /// Tải dữ liệu ban đầu: Ưu tiên truyện tương tự từ lịch sử đọc, nếu không có thì Semantic Search
  Future<AiRecommendationState> _fetchInitial() async {
    final repo = ref.read(seriesRepositoryProvider);
    final session = ref.read(authSessionProvider).value;

    // 1. Nếu đã đăng nhập, thử lấy lịch sử đọc gần nhất để gợi ý Vector Similarity
    if (session != null) {
      try {
        final history = await repo.getReadingHistory();
        if (history.isNotEmpty) {
          final mostRecent = history.first;
          final similar = await repo.getSimilarSeries(
            mostRecent.seriesId,
            limit: 6,
          );
          if (similar.isNotEmpty) {
            return AiRecommendationState(
              items: similar,
              sourceSeriesTitle: mostRecent.series.title,
            );
          }
        }
      } catch (_) {
        // Fallback an toàn sang Semantic Search nếu lấy lịch sử thất bại
      }
    }

    // 2. Fallback hoặc khách vãng lai: Sử dụng Semantic Search AI tuyển chọn
    final items = await repo.getSemanticSearchSeries(
      defaultSemanticPrompt,
      limit: 8,
    );

    return AiRecommendationState(items: items);
  }

  /// Đổi gu đọc AI theo prompt tùy chỉnh hoặc chip bấm nhanh
  Future<void> filterByPrompt(String prompt, {String? chipLabel}) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(seriesRepositoryProvider);
      final items = await repo.getSemanticSearchSeries(cleanPrompt, limit: 8);
      return AiRecommendationState(
        items: items,
        activePrompt: cleanPrompt,
        activeChip: chipLabel,
      );
    });
  }

  /// Khôi phục về gợi ý mặc định
  Future<void> resetToDefault() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchInitial);
  }

  /// Tải lại dữ liệu (Refresh)
  Future<void> refresh() async {
    final currentPrompt = state.value?.activePrompt;
    final currentChip = state.value?.activeChip;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      if (currentPrompt != null && currentPrompt.isNotEmpty) {
        final repo = ref.read(seriesRepositoryProvider);
        final items = await repo.getSemanticSearchSeries(
          currentPrompt,
          limit: 8,
        );
        return AiRecommendationState(
          items: items,
          activePrompt: currentPrompt,
          activeChip: currentChip,
        );
      }
      return _fetchInitial();
    });
  }
}
