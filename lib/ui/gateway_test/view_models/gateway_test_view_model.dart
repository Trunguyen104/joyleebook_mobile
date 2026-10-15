import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/api_endpoints.dart';
import '../../../config/environment.dart';
import '../../../data/services/api_client.dart';
import '../models/gateway_check_result.dart';

class GatewayTestState {
  const GatewayTestState({
    required this.baseUrl,
    required this.results,
    this.isCheckingAll = false,
    this.lastChecked,
  });

  final String baseUrl;
  final List<GatewayCheckResult> results;
  final bool isCheckingAll;
  final DateTime? lastChecked;

  GatewayTestState copyWith({
    String? baseUrl,
    List<GatewayCheckResult>? results,
    bool? isCheckingAll,
    DateTime? lastChecked,
  }) {
    return GatewayTestState(
      baseUrl: baseUrl ?? this.baseUrl,
      results: results ?? this.results,
      isCheckingAll: isCheckingAll ?? this.isCheckingAll,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }
}

final gatewayTestViewModelProvider =
    NotifierProvider<GatewayTestViewModel, GatewayTestState>(
  GatewayTestViewModel.new,
);

class GatewayTestViewModel extends Notifier<GatewayTestState> {
  @override
  GatewayTestState build() {
    final defaultUrl = ref.watch(gatewayBaseUrlProvider);

    return GatewayTestState(
      baseUrl: defaultUrl,
      results: _getInitialEndpoints(),
    );
  }

  static List<GatewayCheckResult> _getInitialEndpoints() {
    return const [
      GatewayCheckResult(
        endpoint: ApiEndpoints.healthLive,
        name: 'Gateway Health (Live)',
        description: 'Kiểm tra trực tiếp JoyleeBook.Gateway (trả về status: Healthy).',
      ),
      GatewayCheckResult(
        endpoint: ApiEndpoints.series,
        name: 'Series Service (Downstream Proxy)',
        description: 'Kiểm tra Gateway chuyển tiếp YARP thành công sang Series Microservice.',
      ),
      GatewayCheckResult(
        endpoint: ApiEndpoints.notificationsHealth,
        name: 'Notification Health (Downstream Proxy)',
        description: 'Kiểm tra Gateway chuyển tiếp YARP sang Notification Service.',
      ),
    ];
  }

  void updateBaseUrl(String newUrl) {
    state = state.copyWith(
      baseUrl: newUrl.trim(),
      results: state.results.map((r) => r.copyWith(
        statusCode: null,
        statusMessage: null,
        latencyMs: null,
        isSuccess: false,
        rawBody: null,
        errorMessage: null,
      )).toList(),
    );
    ref.read(gatewayBaseUrlProvider.notifier).setUrl(newUrl.trim());
  }

  Future<void> checkAll() async {
    if (state.isCheckingAll) return;

    state = state.copyWith(isCheckingAll: true);
    for (var i = 0; i < state.results.length; i++) {
      await checkSingleEndpoint(i);
    }
    state = state.copyWith(
      isCheckingAll: false,
      lastChecked: DateTime.now(),
    );
  }

  Future<void> checkSingleEndpoint(int index) async {
    if (index < 0 || index >= state.results.length) return;

    final target = state.results[index];

    // Cập nhật trạng thái loading cho item
    final updatedList = List<GatewayCheckResult>.from(state.results);
    updatedList[index] = target.copyWith(isLoading: true, errorMessage: null);
    state = state.copyWith(results: updatedList);

    final stopwatch = Stopwatch()..start();

    try {
      final dio = Dio(BaseOptions(
        baseUrl: Environment.parseUri(state.baseUrl).toString(),
        connectTimeout: const Duration(seconds: 4),
        receiveTimeout: const Duration(seconds: 6),
        headers: const {'Accept': 'application/json'},
        validateStatus: (status) => true, // Đón mọi mã HTTP để phân tích
      ));

      final response = await dio.get<dynamic>(target.endpoint);
      stopwatch.stop();

      final statusCode = response.statusCode ?? 0;
      final isSuccess = statusCode >= 200 && statusCode < 300;

      String rawData;
      if (response.data is Map || response.data is List) {
        const encoder = JsonEncoder.withIndent('  ');
        rawData = encoder.convert(response.data);
      } else {
        rawData = response.data?.toString() ?? 'Không có nội dung phản hồi';
      }

      String? errorMsg;
      if (!isSuccess) {
        if (statusCode == 502) {
          errorMsg = 'HTTP 502 Bad Gateway: Gateway đang chạy nhưng microservice đích chưa được khởi động!';
        } else if (statusCode == 404) {
          errorMsg = 'HTTP 404 Not Found: Đường dẫn không tồn tại hoặc chưa cấu hình route trên Gateway.';
        } else {
          errorMsg = 'HTTP $statusCode: ${response.statusMessage ?? "Yêu cầu không thành công"}';
        }
      }

      updatedList[index] = target.copyWith(
        statusCode: statusCode,
        statusMessage: response.statusMessage,
        latencyMs: stopwatch.elapsedMilliseconds,
        isSuccess: isSuccess,
        isLoading: false,
        rawBody: rawData,
        errorMessage: errorMsg,
        timestamp: DateTime.now(),
      );
    } on DioException catch (e) {
      stopwatch.stop();
      String errorMsg;

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMsg = 'Quá hạn kết nối (${stopwatch.elapsedMilliseconds}ms). Gateway không phản hồi kịp thời.';
          break;
        case DioExceptionType.connectionError:
          errorMsg = 'Lỗi kết nối (Connection Refused): Không tìm thấy máy chủ tại ${state.baseUrl}.\n'
              'Hãy kiểm tra kết nối mạng hoặc địa chỉ Gateway.';
          break;
        default:
          errorMsg = e.message ?? 'Lỗi mạng không xác định: ${e.toString()}';
      }

      updatedList[index] = target.copyWith(
        statusCode: null,
        latencyMs: stopwatch.elapsedMilliseconds,
        isSuccess: false,
        isLoading: false,
        errorMessage: errorMsg,
        rawBody: null,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      stopwatch.stop();
      updatedList[index] = target.copyWith(
        isSuccess: false,
        isLoading: false,
        errorMessage: 'Lỗi không mong muốn: $e',
        timestamp: DateTime.now(),
      );
    }

    state = state.copyWith(results: updatedList);
  }
}
