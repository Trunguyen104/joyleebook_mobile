import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joyleebook_mobile/ui/core/themes/app_colors.dart';
import 'package:joyleebook_mobile/ui/series/view_models/series_list_view_model.dart';

import '../../core/themes/app_dimensions.dart';
import '../../../domain/models/series.dart';
import '../../core/widgets/joylee_button.dart';

class SeriesDetailScreen extends ConsumerStatefulWidget {
  final Series initialSeries;
  const SeriesDetailScreen({super.key, required this.initialSeries});

  @override
  ConsumerState<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends ConsumerState<SeriesDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final initialSeries = widget.initialSeries;

    final seriesList = ref.watch(seriesListViewModelProvider).value;
    final series =
        seriesList?.firstWhere(
          (s) => s.id == initialSeries.id,
          orElse: () => initialSeries,
        ) ??
        initialSeries;

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        title: Text(
          series.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: .bold,
            fontSize: 18,
          ),
        ),
        actions: [
          //Btn bookmark
          IconButton(
            icon: Icon(
              series.isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              color: series.isBookmarked
                  ? colors.primaryBrand
                  : colors.textSecondary,
            ),
            tooltip: series.isBookmarked ? "Bỏ lưu tủ sách" : "Lưu vào tủ sách",
            onPressed: () => ,
          ),
        ],
      ),
    );
  }
}

// class SeriesDetailScreen extends ConsumerWidget {
//   final Series initialSeries;
//
//   const SeriesDetailScreen({super.key, required this.initialSeries});
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final colors = context.colors;
//
//     final seriesList = ref.watch(seriesListViewModelProvider).value;
//     final series =
//         seriesList?.firstWhere(
//               (s) => s.id == initialSeries.id,
//           orElse: () => initialSeries,
//         ) ??
//             initialSeries;
//
//     return Scaffold(
//       backgroundColor: colors.bgCanvas,
//       appBar: AppBar(
//         title: Text(
//           series.title,
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//           style: TextStyle(
//             color: colors.textPrimary,
//             fontWeight: .bold,
//             fontSize: 18,
//           ),
//         ),
//         actions: [
//           // btn bookmark
//           IconButton(
//             icon: Icon(
//               series.isBookmarked
//                   ? Icons.bookmark_rounded
//                   : Icons.bookmark_border_rounded,
//               color: series.isBookmarked
//                   ? colors.primaryBrand
//                   : colors.textSecondary,
//             ),
//             tooltip: series.isBookmarked ? 'Bỏ lưu tủ sách' : 'Lưu vào tủ sách',
//             onPressed: () => _toggleBookmark(context, ref, series.id),
//           ),
//         ],
//       ),
//
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(AppDimensions.space4),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // 1. Header: Anhr biaf dung, thong tin tac gia, status
//             _buildHeader(context, colors, series),
//             const SizedBox(height: AppDimensions.space4),
//
//             // 2. Danh sach Tag the loai
//             if (series.genres.isNotEmpty) ...[
//               _buildGenres(colors, series.genres),
//               const SizedBox(height: AppDimensions.space4),
//             ],
//
//             // 3. Các nút hành động chính (Đọc ngay / Lưu tủ sách)
//             _buildActionButtons(context, ref, colors, series),
//             const SizedBox(height: AppDimensions.space5),
//             // 4. Khối Giới thiệu / Tóm tắt nội dung
//             _buildDescription(colors, series.description),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// 1. Khối Header ảnh bài và thông tin cơ bản
//   Widget _buildHeader(BuildContext context, AppColors colors, Series series) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Anh bia sach ty le chuan
//         ClipRRect(
//           borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
//           child: Container(
//             width: 110,
//             height: 160,
//             color: colors.bgSurfaceSubtle,
//             child: series.coverImageUrl.isNotEmpty
//                 ? Image.network(
//               series.coverImageUrl,
//               fit: BoxFit.cover,
//               errorBuilder: (_, _, _) =>
//                   _buildPlaceholderImage(colors),
//             )
//                 : _buildPlaceholderImage(colors),
//           ),
//         ),
//         const SizedBox(width: AppDimensions.space4),
//
//         // Tên truyện, tác giả, trạng thái
//         Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   series.title,
//                   style: TextStyle(
//                     fontSize: 20,
//                     fontWeight: .bold,
//                     color: colors.textPrimary,
//                     height: 1.2,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Icon(Icons.edit_note_rounded, size: 18, color: colors.textSecondary),
//                     const SizedBox(width: 4),
//                     Expanded(
//                         child: Text(
//                       series.authorName,
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: colors.textSecondary,
//                         fontWeight: FontWeight.w500,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                         ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//
//                 // Badge trạng thái
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//                   decoration: BoxDecoration(
//                     color: series.status == SeriesStatus.completed
//                         ? colors.success.withValues(alpha: 0.15)
//                         : colors.primaryBrand.withValues(alpha: 0.15),
//                     borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
//                   ),
//                   child: Text(
//                     series.status.label,
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: .w600,
//                       color: series.status == SeriesStatus.completed
//                         ? colors.success
//                           : colors.primaryBrand,
//                     ),
//                   ),
//                 )
//               ],
//             ),
//         )
//       ],
//     );
//   }
//
//
//   /// 2. Danh sach cac the loai
//
//   Widget _buildGenres(AppColors colors, List<String> genres) {
//     return Wrap(
//       spacing: 8,
//       runSpacing: 8,
//       children: genres.map((genre) {
//         return Container(
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//           decoration: BoxDecoration(
//             color: colors.bgSurface,
//             borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
//             border: Border.all(color: colors.borderDefault),
//           ),
//           child: Text(
//             genre,
//             style: TextStyle(fontSize: 12, color: colors.textSecondary),
//           ),
//         );
//       }).toList(),
//     );
//   }
//
//   /// 3. Hàng nút bấm hành động
//   Widget _buildActionButtons(
//       BuildContext context, WidgetRef ref, AppColors colors, Series series) {
//     return Row(
//       children: [
//         // Nút Đọc sách (chính)
//         Expanded(
//           child: JoyleeButton(
//             label: 'Đọc ngay',
//             icon: const Icon(Icons.menu_book_rounded, size: 18),
//             onPressed: () {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Tính năng đọc chương đang phát triển.')),
//               );
//             },
//           ),
//         ),
//         const SizedBox(width: AppDimensions.space3),
//         // Nút Lưu/Bỏ lưu tủ sách (phụ)
//         Expanded(
//           child: JoyleeButton(
//             label: series.isBookmarked ? 'Đã lưu' : 'Lưu tủ sách',
//             variant: JoyleeButtonVariant.secondary,
//             icon: Icon(
//               series.isBookmarked
//                   ? Icons.bookmark_added_rounded
//                   : Icons.bookmark_add_outlined,
//               size: 18,
//             ),
//             onPressed: () => _toggleBookmark(context, ref, series.id),
//           ),
//         ),
//       ],
//     );
//   }
//   /// 4. Khối tóm tắt nội dung
//   Widget _buildDescription(AppColors colors, String description) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Giới thiệu nội dung',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: colors.textPrimary,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.all(AppDimensions.space3),
//           decoration: BoxDecoration(
//             color: colors.bgSurface,
//             borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
//             border: Border.all(color: colors.borderDefault),
//           ),
//           child: Text(
//             description,
//             style: TextStyle(
//               fontSize: 14,
//               height: 1.6, // Giãn dòng chuẩn editorial dễ đọc
//               color: colors.textSecondary,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildPlaceholderImage(AppColors colors) {
//     return Center(
//       child: Icon(
//         Icons.auto_stories_rounded,
//         size: 36,
//         color: colors.textDisabled,
//       ),
//     );
//   }
//
  Future<void> _toggleBookmark(
      BuildContext context,
      WidgetRef ref,
      String seriesId,
      ) async {
    final success = await ref
        .read(seriesListViewModelProvider.notifier)
        .toggleBookmark(seriesId);

    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật tủ sách. Đã hoàn tác.'),
        ),
      );
//     }
//   }
// }
