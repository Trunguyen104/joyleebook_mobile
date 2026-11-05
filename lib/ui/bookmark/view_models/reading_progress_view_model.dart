import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/series_repository.dart';

final readingProgressViewModelProvider = FutureProvider.family<double?, String>(
  (ref, seriesId) =>
      ref.watch(seriesRepositoryProvider).getReadingProgress(seriesId),
);
