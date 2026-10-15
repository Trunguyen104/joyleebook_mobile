import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/environment.dart';
import '../../core/themes/app_colors.dart';
import '../../core/themes/app_dimensions.dart';
import '../../core/widgets/joylee_button.dart';
import '../models/gateway_check_result.dart';
import '../view_models/gateway_test_view_model.dart';

class GatewayTestScreen extends ConsumerStatefulWidget {
  const GatewayTestScreen({super.key});

  @override
  ConsumerState<GatewayTestScreen> createState() => _GatewayTestScreenState();
}

class _GatewayTestScreenState extends ConsumerState<GatewayTestScreen> {
  late final TextEditingController _urlController;

  @override
  void initState() {
    super.initState();
    final currentUrl = ref.read(gatewayTestViewModelProvider).baseUrl;
    _urlController = TextEditingController(text: currentUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _applyUrl(String url) {
    _urlController.text = url;
    ref.read(gatewayTestViewModelProvider.notifier).updateBaseUrl(url);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã cập nhật Base URL: $url'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final testState = ref.watch(gatewayTestViewModelProvider);

    return Scaffold(
      backgroundColor: colors.bgCanvas,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kiểm tra Kết nối Gateway',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'JoyleeBook-V3.0 Backend',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Kiểm tra lại toàn bộ',
            icon: const Icon(Icons.refresh),
            onPressed: testState.isCheckingAll
                ? null
                : () => ref.read(gatewayTestViewModelProvider.notifier).checkAll(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Card Cấu hình Base URL
              _buildUrlConfigCard(context, testState, colors),
              const SizedBox(height: AppDimensions.space4),

              // 2. Nút bấm Chạy Kiểm tra
              JoyleeButton(
                label: testState.isCheckingAll
                    ? 'Đang kiểm tra kết nối...'
                    : 'Bắt đầu Kiểm tra Kết nối',
                icon: const Icon(Icons.network_ping_rounded),
                isLoading: testState.isCheckingAll,
                onPressed: () =>
                    ref.read(gatewayTestViewModelProvider.notifier).checkAll(),
              ),
              const SizedBox(height: AppDimensions.space6),

              // 3. Tiêu đề danh sách endpoint
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trạng thái Endpoints (${testState.results.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (testState.lastChecked != null)
                    Text(
                      'Lần cuối: ${_formatTime(testState.lastChecked!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.space3),

              // 4. Danh sách các kết quả test
              ...List.generate(
                testState.results.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.space3),
                  child: _buildEndpointResultCard(
                    context,
                    testState.results[index],
                    index,
                    colors,
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.space4),

              // 5. Hộp hướng dẫn khởi động Backend JoyleeBook-V3.0
              _buildGatewayInfoCard(context, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrlConfigCard(
    BuildContext context,
    GatewayTestState testState,
    AppColors colors,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.router_outlined, color: colors.primaryBrand, size: 22),
                const SizedBox(width: AppDimensions.space2),
                Text(
                  'Cấu hình JoyleeBook Gateway URL',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space1),
            Text(
              'Gateway là Reverse Proxy tập trung, đã deploy dùng chung qua HTTPS.',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: AppDimensions.space3),

            // Ô nhập URL
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'Gateway Base URL',
                      hintText: Environment.hostedBaseUrl,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.space2),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryBrand,
                    foregroundColor: colors.textOnBrand,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    ),
                  ),
                  onPressed: () => _applyUrl(_urlController.text),
                  child: const Text('Lưu'),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space3),

            // Khôi phục nhanh về Gateway dùng chung
            ActionChip(
              label: const Text('Server dùng chung (HTTPS)'),
              avatar: const Icon(Icons.cloud_outlined, size: 16),
              onPressed: () => _applyUrl(Environment.hostedBaseUrl),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndpointResultCard(
    BuildContext context,
    GatewayCheckResult result,
    int index,
    AppColors colors,
  ) {
    // Xác định màu sắc và biểu tượng theo trạng thái
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    if (result.isLoading) {
      statusColor = colors.accent;
      statusIcon = Icons.hourglass_top_rounded;
      statusLabel = 'Đang gọi...';
    } else if (result.statusCode != null && result.isSuccess) {
      statusColor = colors.success;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = '${result.statusCode} OK';
    } else if (result.errorMessage != null || (result.statusCode != null && !result.isSuccess)) {
      statusColor = colors.danger;
      statusIcon = Icons.error_rounded;
      statusLabel = result.statusCode != null ? '${result.statusCode}' : 'Lỗi kết nối';
    } else {
      statusColor = colors.textDisabled;
      statusIcon = Icons.radio_button_unchecked;
      statusLabel = 'Chưa test';
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: result.statusCode != null || result.errorMessage != null,
        leading: Icon(statusIcon, color: statusColor, size: 28),
        title: Row(
          children: [
            Expanded(
              child: Text(
                result.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(color: statusColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                'GET ${result.endpoint}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: colors.primaryBrand,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (result.latencyMs != null) ...[
                const SizedBox(width: AppDimensions.space2),
                Text(
                  '• ${result.latencyMs} ms',
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.play_arrow_rounded),
          tooltip: 'Test riêng endpoint này',
          onPressed: result.isLoading
              ? null
              : () => ref
                  .read(gatewayTestViewModelProvider.notifier)
                  .checkSingleEndpoint(index),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.space4,
              0,
              AppDimensions.space4,
              AppDimensions.space4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                Text(
                  result.description,
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                const SizedBox(height: AppDimensions.space2),

                // Lỗi nếu có
                if (result.errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.space3),
                    decoration: BoxDecoration(
                      color: colors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chi tiết sự cố:',
                          style: TextStyle(
                            color: colors.danger,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          result.errorMessage!,
                          style: TextStyle(color: colors.danger, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space2),
                ],

                // Dữ liệu phản hồi nếu có
                if (result.rawBody != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Phản hồi từ Gateway (JSON):',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        'HTTP ${result.statusCode}',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 180),
                    padding: const EdgeInsets.all(AppDimensions.space2),
                    decoration: BoxDecoration(
                      color: colors.bgSurfaceSubtle,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                      border: Border.all(color: colors.borderDefault),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        result.rawBody!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGatewayInfoCard(BuildContext context, AppColors colors) {
    return Card(
      color: colors.bgSurfaceSubtle,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: colors.accent, size: 20),
                const SizedBox(width: AppDimensions.space2),
                Text(
                  'Thông tin Gateway JoyleeBook',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space2),
            Text(
              'Backend được deploy dùng chung cho cả nhóm; không cần chạy backend trên máy. Swagger để đối chiếu contract:',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: AppDimensions.space2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.space3),
              decoration: BoxDecoration(
                color: colors.bgCanvas,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(color: colors.borderDefault),
              ),
              child: const SelectableText(
                '${Environment.hostedBaseUrl}/docs/authentication/swagger/index.html\n'
                '${Environment.hostedBaseUrl}/docs/series/swagger/index.html',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space2),
            Text(
              '• Mọi request đều đi qua Gateway, không gọi trực tiếp microservice.\n'
              '• HTTP 502: Gateway đang chạy nhưng microservice đích chưa sẵn sàng.',
              style: TextStyle(fontSize: 11, color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
