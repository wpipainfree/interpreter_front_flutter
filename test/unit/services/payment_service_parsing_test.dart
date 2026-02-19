import 'package:flutter_test/flutter_test.dart';
import 'package:wpi_app/services/payment_service.dart';

void main() {
  group('PaymentHistoryResponse parsing', () {
    test('parses mobile-payments history response shape', () {
      final response = PaymentHistoryResponse.fromJson({
        'items': [
          {
            'payment_id': 101,
            'order_id': 'ORD-101',
            'test_id': 1,
            'test_name': 'WPI 현실검사',
            'amount': 33000,
            'status': '2',
            'status_text': '결제완료',
            'payment_type': 20,
            'payment_type_name': '신용카드',
            'payment_date': '2026-02-19T09:00:00',
            'created_at': '2026-02-19T08:55:00',
          },
        ],
        'total': 1,
        'page': 1,
        'page_size': 20,
        'has_more': false,
      });

      expect(response.total, 1);
      expect(response.page, 1);
      expect(response.pageSize, 20);
      expect(response.hasMore, isFalse);
      expect(response.items, hasLength(1));
      expect(response.items.first.paymentId, 101);
      expect(response.items.first.status, '2');
      expect(response.items.first.amount, 33000);
    });

    test('parses legacy psych-test accounts response shape', () {
      final response = PaymentHistoryResponse.fromJson({
        'items': [
          {
            'ID': 222,
            'TEST_ID': 2,
            'ORDER_ID': 'ORD-222',
            'AMOUNT': 55000,
            'STATUS': 2,
            'TYPE': 20,
            'PAYMENT_DATE': '2026-02-18T10:00:00',
            'CREATE_DATE': '2026-02-18T09:30:00',
          },
        ],
        'total_count': 1,
        'page': 1,
        'page_size': 50,
        'has_next': false,
      });

      final item = response.items.first;
      expect(response.total, 1);
      expect(response.hasMore, isFalse);
      expect(item.paymentId, 222);
      expect(item.status, '2');
      expect(item.statusText, isNotEmpty);
      expect(item.paymentTypeName, isNotEmpty);
    });

    test('supports data key and derives hasMore from total/page/page_size', () {
      final response = PaymentHistoryResponse.fromJson({
        'data': [
          {
            'payment_id': 1,
            'amount': 1000,
            'status': '1',
            'created_at': '2026-02-17T11:00:00',
          },
        ],
        'total': 30,
        'page': 1,
        'page_size': 20,
      });

      expect(response.items, hasLength(1));
      expect(response.hasMore, isTrue);
    });
  });
}
