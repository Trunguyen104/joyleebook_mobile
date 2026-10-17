import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joyleebook_mobile/ui/core/themes/theme_provider.dart';

import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_empty_state.dart';
import '../../core/widgets/joylee_error_view.dart';
import '../view_models/series_list_view_model.dart';
import '../../chapter/widgets/chapter_list_screen.dart';
import 'series_card.dart';

/// MÀN HÌNH KHÁM PHÁ TRUYỆN (SeriesListScreen)
/// Bước 5 trong kiến trúc Compass App:
/// Màn hình mẫu dành riêng cho Actor Reader (Độc giả).
///
/// 4 NGUYÊN TẮC BẮT BUỘC ĐƯỢC ÁP DỤNG TRONG MÃ NGUỒN:
/// 1. Bộ 4 Trạng thái (4 States): Loading -> Error -> Empty -> Data.
/// 2. Riverpod State Consumer: ref.watch() để đọc dữ liệu, ref.read() để gọi sự kiện.
/// 3. Material 3 & Warm Editorial: Sử dụng màu sắc thương hiệu từ context.colors.
/// 4. Chống lỗi giao diện: Bọc SafeArea, không bị lỗi tràn viền vàng đen (RenderFlex overflow).
class SeriesListScreen extends ConsumerStatefulWidget {
  const SeriesListScreen({super.key});

  @override
  ConsumerState<SeriesListScreen> createState() => _SeriesListScreenState();
}

class _SeriesListScreenState extends ConsumerState<SeriesListScreen> {
  // Controller điều khiển ô nhập tìm kiếm
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    // Luôn nhớ giải phóng controller khi thoát màn hình để tránh rò rỉ bộ nhớ
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Lấy bảng màu Warm Editorial từ Theme của app
    final colors = context.colors;

    // 2. Lắng nghe trạng thái bất đồng bộ từ Riverpod ViewModel
    final seriesState = ref.watch(seriesListViewModelProvider);

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        title: Text(
          'Kho Truyện JoyleeBook',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            tooltip: 'Đổi giao diện Sáng / Tối',
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          // Nút làm mới thủ công trên AppBar
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới danh sách',
            onPressed: () =>
                ref.read(seriesListViewModelProvider.notifier).refresh(),
          ),
        ],
        // Ô tìm kiếm được đặt ở phần bottom của AppBar
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space4,
              vertical: AppDimensions.space2,
            ),
            child: _buildSearchBar(colors),
          ),
        ),
      ),

      // 3. THỰC HIỆN BỘ 4 TRẠNG THÁI BẰNG HÀM .when() CỦA RIVERPOD
      body: seriesState.when(
        // TRẠNG THÁI 1: LOADING (Đang tải từ API Gateway)
        // Hiển thị vòng xoay spinner màu Plum chính giữa màn hình
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colors.primaryBrand),
              ),
              const SizedBox(height: AppDimensions.space3),
              Text(
                'Đang tải kho truyện...',
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),

        // TRẠNG THÁI 2: ERROR (Lỗi mạng hoặc Gateway chưa bật)
        // Hiển thị giao diện báo lỗi kèm nút "Thử lại" thân thiện
        error: (err, stack) => JoyleeErrorView(
          message: err.toString(),
          onRetry: () =>
              ref.read(seriesListViewModelProvider.notifier).refresh(),
        ),

        // TRẠNG THÁI 3 & 4: CÓ DỮ LIỆU HOẶC DANH SÁCH RỖNG
        data: (seriesList) {
          // A. Nếu danh sách không có truyện nào -> Hiển thị Empty State
          if (seriesList.isEmpty) {
            return JoyleeEmptyState(
              title: 'Không tìm thấy truyện nào',
              message: _searchController.text.isNotEmpty
                  ? 'Không có kết quả nào khớp với từ khóa "${_searchController.text}".'
                  : 'Hiện tại chưa có tác phẩm nào được xuất bản trên hệ thống.',
              actionLabel: 'Tải lại toàn bộ',
              onAction: () {
                _searchController.clear();
                ref.read(seriesListViewModelProvider.notifier).search('');
              },
            );
          }

          // B. Nếu có dữ liệu -> Hiển thị ListView có tính năng Kéo để làm mới
          return RefreshIndicator(
            color: colors.primaryBrand,
            backgroundColor: colors.bgSurface,
            onRefresh: () =>
                ref.read(seriesListViewModelProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.space4),
              itemCount: seriesList.length,
              itemBuilder: (context, index) {
                final item = seriesList[index];

                return SeriesCard(
                  series: item,
                  onTap: () {
                    // Chuyển sang màn hình danh sách chương của bộ truyện
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChapterListScreen(
                          seriesId: item.id,
                          seriesTitle: item.title,
                        ),
                      ),
                    );
                  },
                  onBookmarkTap: () async {
                    // Gọi hàm lưu/bỏ lưu truyện (Optimistic UI)
                    final success = await ref
                        .read(seriesListViewModelProvider.notifier)
                        .toggleBookmark(item.id);

                    // Nếu API thất bại (mạng đứt), báo lỗi hoàn tác
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'Không thể cập nhật tủ sách. Đã hoàn tác trạng thái.',
                          ),
                          backgroundColor: colors.danger,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// Khung tìm kiếm có hỗ trợ nút Xóa nhanh và debounce 400ms
  Widget _buildSearchBar(AppColors colors) {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        // Gọi hàm search trong ViewModel (đã tích hợp sẵn Debounce 400ms)
        ref.read(seriesListViewModelProvider.notifier).search(value);
        setState(() {}); // Cập nhật để ẩn/hiện nút Xóa clear
      },
      decoration: InputDecoration(
        hintText: 'Tìm kiếm tựa truyện, tác giả...',
        hintStyle: TextStyle(color: colors.textDisabled, fontSize: 14),
        prefixIcon: Icon(Icons.search, color: colors.textSecondary),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 20),
                onPressed: () {
                  _searchController.clear();
                  ref.read(seriesListViewModelProvider.notifier).search('');
                  setState(() {});
                },
              )
            : null,
        filled: true,
        fillColor: colors.bgSurface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space4,
          vertical: AppDimensions.space3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          borderSide: BorderSide(color: colors.borderDefault),
        ),
      ),
    );
  }
}
