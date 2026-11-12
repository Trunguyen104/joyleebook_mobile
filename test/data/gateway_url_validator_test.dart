import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:joyleebook_mobile/data/services/api_client.dart';
import 'package:joyleebook_mobile/ui/gateway_test/view_models/gateway_test_view_model.dart';
import 'package:joyleebook_mobile/ui/gateway_test/view_models/gateway_url_validator.dart';

void main() {
  test('Chấp nhận URL gốc HTTPS và khoảng trắng ngoài', () {
    for (final url in [
      'https://example.com',
      ' https://example.com/ ',
      'https://example.com:8443',
    ]) {
      expect(validateGatewayUrl(url), isNull, reason: url);
    }
  });

  test('Chặn địa chỉ rỗng, HTTP, đường dẫn và cổng sai', () {
    for (final url in [
      '',
      '   ',
      'example.com',
      'http://example.com',
      'https://',
      'https://exa mple.com',
      'https://example.com/api/series',
      'https://example.com?token=x',
      'https://example.com#x',
      'https://user:pass@example.com',
      'https://example.com:0',
      'https://example.com:65536',
      'https://example.com:abc',
    ]) {
      expect(validateGatewayUrl(url), isNotNull, reason: url);
    }
  });

  test('URL sai không thay đổi cấu hình hoặc trạng thái Gateway', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final initial = container.read(gatewayTestViewModelProvider);
    container
        .read(gatewayTestViewModelProvider.notifier)
        .updateBaseUrl('https://example.com/api');
    expect(container.read(gatewayTestViewModelProvider), same(initial));
    expect(container.read(gatewayBaseUrlProvider), initial.baseUrl);
  });
}
