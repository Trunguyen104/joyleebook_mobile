import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ui/auth/view_models/auth_session_view_model.dart';
import '../dtos/upsert_reading_progress_dto.dart';
import '../repositories/offline_series_repository.dart';
import '../repositories/series_repository.dart';

/// RIVERPOD PROVIDER: Cung cấp dịch vụ đồng bộ tiến độ đọc offline lên máy chủ
final offlineProgressSyncServiceProvider = Provider<OfflineProgressSyncService>(
  (ref) {
    return OfflineProgressSyncService(ref);
  },
);

/// SERVICE - Tự động đồng bộ tiến độ đọc đã lưu trong SQLite khi thiết bị có mạng trở lại
class OfflineProgressSyncService {
  final Ref _ref;
  bool _isSyncing = false;

  OfflineProgressSyncService(this._ref);

  /// Quét và gửi các bản ghi tiến độ chưa đồng bộ (is_synced = 0) lên Gateway
  Future<void> syncUnsyncedProgress() async {
    if (_isSyncing) return;

    final session = _ref.read(authSessionProvider).value;
    if (session == null) return;

    _isSyncing = true;
    try {
      final offlineRepo = _ref.read(offlineSeriesRepositoryProvider);
      final seriesRepo = _ref.read(seriesRepositoryProvider);
      final unsyncedList = await offlineRepo.getUnsyncedProgress();

      for (final item in unsyncedList) {
        try {
          await seriesRepo.updateReadingProgress(
            UpsertReadingProgressDto(
              seriesId: item.seriesId,
              chapterId: item.chapterId,
              chapterSortOrder: item.sortOrder,
              scrollPercentage: item.readPercentage * 100,
              isCompleted: item.readPercentage >= 0.99,
              readAtUtc: item.updatedAt.toUtc(),
            ),
          );
          await offlineRepo.markProgressSynced(item.seriesId);
        } catch (_) {
          // Dừng lại nếu mạng chưa ổn định để tiếp tục trong lần sau
          break;
        }
      }
    } catch (_) {
      // Best-effort sync
    } finally {
      _isSyncing = false;
    }
  }
}
