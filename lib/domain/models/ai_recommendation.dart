import 'package:flutter/foundation.dart';

import 'series.dart';

/// PURE DOMAIN MODEL - Kết quả gợi ý truyện từ AI
/// Tích hợp trực tiếp với kết quả từ Qdrant Vector Search & Gemini Semantic Search.
@immutable
class AiRecommendation {
  /// Thông tin bộ truyện
  final Series series;

  /// Điểm số tương quan hoặc tương đồng (từ 0.0 đến 1.0)
  final double score;

  /// Ghi chú / lý do gợi ý hiển thị trên UI (ví dụ: "86% tương đồng", "AI đề xuất")
  final String? rationale;

  /// Cờ đánh dấu nếu kết quả là fallback theo thể loại thay vì vector embeddings
  final bool isFallback;

  const AiRecommendation({
    required this.series,
    required this.score,
    this.rationale,
    this.isFallback = false,
  });

  /// Tỷ lệ phần trăm khớp (0 - 100%)
  int get matchPercentage {
    final pct = (score * 100).round();
    if (pct < 0) return 0;
    if (pct > 100) return 100;
    return pct;
  }

  AiRecommendation copyWith({
    Series? series,
    double? score,
    String? rationale,
    bool? isFallback,
  }) {
    return AiRecommendation(
      series: series ?? this.series,
      score: score ?? this.score,
      rationale: rationale ?? this.rationale,
      isFallback: isFallback ?? this.isFallback,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiRecommendation &&
          runtimeType == other.runtimeType &&
          series == other.series &&
          score == other.score &&
          rationale == other.rationale &&
          isFallback == other.isFallback;

  @override
  int get hashCode =>
      series.hashCode ^
      score.hashCode ^
      rationale.hashCode ^
      isFallback.hashCode;
}
