import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:joyleebook_mobile/config/api_endpoints.dart';
import 'package:joyleebook_mobile/data/repositories/payment_repository.dart';
import 'package:joyleebook_mobile/data/services/api_exceptions.dart';
import 'package:joyleebook_mobile/domain/models/deposit_order.dart';

typedef _MockHandler = ResponseBody Function(
  RequestOptions options,
  Map<String, dynamic>? body,
);

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this._handler);

  final _MockHandler _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    Map<String, dynamic>? body;
    if (options.data is Map<String, dynamic>) {
      body = options.data as Map<String, dynamic>;
    }
    return _handler(options, body);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Object data, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  Dio createDio(_MockHandler handler) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.joyleebook.duckdns.org'));
    dio.httpClientAdapter = _FakeHttpClientAdapter(handler);
    return dio;
  }

  group('PaymentRepository DTO mapping & validation', () {
    test(
      'getWallet và getTransactions ánh xạ JSON sang domain models',
      () async {
        final dio = createDio((options, _) {
          if (options.path == ApiEndpoints.paymentsWallet) {
            return _jsonResponse({
              'userId': 'u-123',
              'balance': 12500,
              'updatedAtUtc': '2026-05-01T10:30:00Z',
            });
          }
          if (options.path == ApiEndpoints.paymentsTransactions) {
            return _jsonResponse([
              {
                'id': 'tx-1',
                'orderCode': 8899001,
                'amountVnd': 50000,
                'coins': 5000,
                'status': 'Success',
                'paymentUrl': 'https://pay.payos.vn/web/8899001',
                'createdAtUtc': '2026-05-01T10:00:00Z',
                'completedAtUtc': '2026-05-01T10:05:00Z',
              },
              {
                'id': 'tx-2',
                'orderCode': 8899002,
                'amountVnd': 20000,
                'coins': 2000,
                'status': 'Cancelled',
                'createdAtUtc': '2026-05-01T09:00:00Z',
              },
            ]);
          }
          return _jsonResponse({'detail': 'Not found'}, statusCode: 404);
        });

        final repo = PaymentRepository(dio);
        final wallet = await repo.getWallet();
        expect(wallet.userId, 'u-123');
        expect(wallet.balance, 12500);
        expect(wallet.updatedAt, DateTime.utc(2026, 5, 1, 10, 30));

        final txs = await repo.getTransactions();
        expect(txs, hasLength(2));
        expect(txs[0].orderCode, 8899001);
        expect(txs[0].status, DepositStatus.success);
        expect(txs[1].status, DepositStatus.cancelled);
      },
    );

    test('createDeposit kiểm tra biên số tiền trước khi gọi mạng', () async {
      var networkCalled = false;
      final repo = PaymentRepository(
        createDio((_, _) {
          networkCalled = true;
          return _jsonResponse({});
        }),
      );

      await expectLater(
        () => repo.createDeposit(amountVnd: 9999),
        throwsA(
          isA<AppException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.message, 'message', contains('10.000 VNĐ')),
        ),
      );
      await expectLater(
        () => repo.createDeposit(amountVnd: 50000001),
        throwsA(
          isA<AppException>().having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
      expect(networkCalled, isFalse);
    });

    test(
      'createDeposit trích xuất ProblemDetails.detail và statusCode 503',
      () async {
        final repo503 = PaymentRepository(
          createDio((_, _) {
            return _jsonResponse({
              'title': 'Service Unavailable',
              'detail': 'Cổng thanh toán PayOS đang bảo trì.',
              'status': 503,
            }, statusCode: 503);
          }),
        );

        await expectLater(
          () => repo503.createDeposit(amountVnd: 20000),
          throwsA(
            isA<AppException>()
                .having((e) => e.statusCode, 'statusCode', 503)
                .having(
                  (e) => e.message,
                  'message',
                  'Cổng thanh toán PayOS đang bảo trì.',
                ),
          ),
        );
      },
    );

    test('donateToStory kiểm tra biên số xu, độ dài lời nhắn và trích xuất ModelState.errors', () async {
      var networkCalled = false;
      final guardRepo = PaymentRepository(
        createDio((_, _) {
          networkCalled = true;
          return _jsonResponse({});
        }),
      );

      await expectLater(
        () => guardRepo.donateToStory(storyId: 's1', coins: 9),
        throwsA(
          isA<AppException>().having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
      await expectLater(
        () => guardRepo.donateToStory(storyId: 's1', coins: 10000001),
        throwsA(
          isA<AppException>().having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
      await expectLater(
        () => guardRepo.donateToStory(
          storyId: 's1',
          coins: 50,
          message: 'a' * 501,
        ),
        throwsA(
          isA<AppException>().having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
      expect(networkCalled, isFalse);

      final modelStateRepo = PaymentRepository(
        createDio((options, body) {
          expect(options.path, ApiEndpoints.paymentsDonate);
          expect(body?['storyId'], 's1');
          expect(body?['coins'], 100);
          return _jsonResponse({
            'errors': {
              'Coins': ['Số dư xu trong ví không đủ để tặng.'],
            },
          }, statusCode: 400);
        }),
      );

      await expectLater(
        () => modelStateRepo.donateToStory(storyId: 's1', coins: 100),
        throwsA(
          isA<AppException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having(
                (e) => e.message,
                'message',
                'Số dư xu trong ví không đủ để tặng.',
              ),
        ),
      );
    });

    test(
      'donateToStory và getStoryDonations ánh xạ kết quả thành công',
      () async {
        final repo = PaymentRepository(
          createDio((options, body) {
            if (options.path == ApiEndpoints.paymentsDonate) {
              return _jsonResponse({
                'donationId': 'don-99',
                'storyId': 'story-1',
                'coins': 200,
                'message': 'Chúc tác giả ra chương mới!',
                'senderBalanceRemaining': 800,
                'createdAtUtc': '2026-05-01T12:00:00Z',
              });
            }
            if (options.path ==
                ApiEndpoints.paymentsStoryDonations('story-1')) {
              return _jsonResponse([
                {
                  'id': 'don-99',
                  'senderUserId': 'reader-1',
                  'coins': 200,
                  'message': 'Chúc tác giả ra chương mới!',
                  'createdAtUtc': '2026-05-01T12:00:00Z',
                },
              ]);
            }
            return _jsonResponse({}, statusCode: 404);
          }),
        );

        final result = await repo.donateToStory(
          storyId: 'story-1',
          coins: 200,
          message: '  Chúc tác giả ra chương mới!  ',
        );
        expect(result.donationId, 'don-99');
        expect(result.coins, 200);
        expect(result.senderBalanceRemaining, 800);

        final donations = await repo.getStoryDonations('story-1');
        expect(donations, hasLength(1));
        expect(donations.first.senderUserId, 'reader-1');
        expect(donations.first.message, 'Chúc tác giả ra chương mới!');
      },
    );
  });
}
