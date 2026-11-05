import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/api_exceptions.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../view_models/reading_progress_view_model.dart';

class ReadingProgressView extends ConsumerWidget {
  const ReadingProgressView({super.key, required this.seriesId, this.progress});

  final String seriesId;
  final double? progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (progress != null) return _buildProgress(context, progress!);

    return ref
        .watch(readingProgressViewModelProvider(seriesId))
        .when(
          loading: () =>
              const SizedBox(height: 4, child: LinearProgressIndicator()),
          error: (error, _) => Row(
            children: [
              Expanded(
                child: Text(
                  error is AppException
                      ? error.message
                      : 'Không thể tải tiến độ đọc.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              IconButton(
                tooltip: 'Thử tải tiến độ lại',
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    ref.invalidate(readingProgressViewModelProvider(seriesId)),
                icon: const Icon(Icons.refresh_rounded, size: 18),
              ),
            ],
          ),
          data: (value) => value == null
              ? const SizedBox.shrink()
              : _buildProgress(context, value),
        );
  }

  Widget _buildProgress(BuildContext context, double value) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: value,
          minHeight: 4,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          color: colors.primaryBrand,
          backgroundColor: colors.bgSurfaceSubtle,
        ),
        const SizedBox(height: AppDimensions.space1),
        Text(
          'Tiến độ ${(value * 100).round()}%',
          style: TextStyle(fontSize: 10, color: colors.textSecondary),
        ),
      ],
    );
  }
}
