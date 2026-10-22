import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// DTO / Model lưu tiến độ đọc của một bộ truyện trong Local Storage
class ReadingProgress {
  final String seriesId;
  final String chapterId;
  final int sortOrder;
  final double readPercentage;
  final DateTime updatedAt;

  const ReadingProgress({
    required this.seriesId,
    required this.chapterId,
    required this.sortOrder,
    required this.readPercentage,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'seriesId': seriesId,
        'chapterId': chapterId,
        'sortOrder': sortOrder,
        'readPercentage': readPercentage,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ReadingProgress.fromJson(Map<String, dynamic> json) =>
      ReadingProgress(
        seriesId: json['seriesId'] as String? ?? '',
        chapterId: json['chapterId'] as String? ?? '',
        sortOrder: json['sortOrder'] as int? ?? 1,
        readPercentage: (json['readPercentage'] as num?)?.toDouble() ?? 0.0,
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Service quản lý cấu hình đọc sách và tiến độ đọc dở bằng SharedPreferences
/// Tích hợp bộ nhớ đệm an toàn tự động fallback khi chạy môi trường Unit / Widget test.
class ReadingPreferencesService {
  final Map<String, dynamic> _memoryCache = {};
  SharedPreferencesAsync? _prefs;

  static const String _keyFontSize = 'user_reading_font_size';
  static const String _prefixSeriesProgress = 'reading_progress_series_';

  SharedPreferencesAsync? get _safePrefs {
    try {
      _prefs ??= SharedPreferencesAsync();
      return _prefs;
    } catch (_) {
      return null;
    }
  }

  /// 1. Cỡ chữ đọc sách (mặc định 17.0, từ 13.0 đến 25.0)
  Future<double> getFontSize() async {
    try {
      final p = _safePrefs;
      if (p != null) {
        final val = await p.getDouble(_keyFontSize);
        if (val != null) return val;
      }
    } catch (_) {}
    return (_memoryCache[_keyFontSize] as double?) ?? 17.0;
  }

  Future<void> setFontSize(double size) async {
    final clamped = size.clamp(13.0, 25.0);
    _memoryCache[_keyFontSize] = clamped;
    try {
      final p = _safePrefs;
      if (p != null) {
        await p.setDouble(_keyFontSize, clamped);
      }
    } catch (_) {}
  }

  /// 2. Tiến độ đọc gần nhất theo seriesId (dùng cho ResumeReadingBar & Active Card)
  Future<ReadingProgress?> getLastReadProgress(String seriesId) async {
    final key = '$_prefixSeriesProgress$seriesId';
    String? rawJson;
    try {
      final p = _safePrefs;
      if (p != null) {
        rawJson = await p.getString(key);
      }
    } catch (_) {}

    rawJson ??= _memoryCache[key] as String?;

    if (rawJson == null || rawJson.trim().isEmpty) return null;
    try {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      return ReadingProgress.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveReadingProgress({
    required String seriesId,
    required String chapterId,
    required int sortOrder,
    double readPercentage = 1.0,
  }) async {
    final progress = ReadingProgress(
      seriesId: seriesId,
      chapterId: chapterId,
      sortOrder: sortOrder,
      readPercentage: readPercentage.clamp(0.0, 1.0),
      updatedAt: DateTime.now(),
    );
    final key = '$_prefixSeriesProgress$seriesId';
    final jsonStr = jsonEncode(progress.toJson());
    _memoryCache[key] = jsonStr;

    try {
      final p = _safePrefs;
      if (p != null) {
        await p.setString(key, jsonStr);
      }
    } catch (_) {}
  }
}

/// RIVERPOD PROVIDER: Đăng ký ReadingPreferencesService
final readingPreferencesServiceProvider =
    Provider<ReadingPreferencesService>((ref) {
  return ReadingPreferencesService();
});
