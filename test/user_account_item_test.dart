import 'package:flutter_test/flutter_test.dart';
import 'package:wpi_app/services/psych_tests_service.dart';

void main() {
  test('UserAccountItem.fromJson supports legacy uppercase keys', () {
    final item = UserAccountItem.fromJson({
      'ID': 10,
      'USER_ID': 20,
      'TEST_ID': 1,
      'RESULT_ID': 123,
      'STATUS': '3',
      'CREATE_DATE': '2026-01-01T00:00:00Z',
      'result': {'TEST_TARGET_NAME': '홍길동'},
    });

    expect(item.id, 10);
    expect(item.userId, 20);
    expect(item.testId, 1);
    expect(item.resultId, 123);
    expect(item.status, '3');
    expect(item.createDate, '2026-01-01T00:00:00Z');
    expect(item.result, isNotNull);
  });

  test('UserAccountItem.fromJson supports snake_case keys', () {
    final item = UserAccountItem.fromJson({
      'id': 10,
      'user_id': 20,
      'test_id': 1,
      'result_id': 123,
      'status': 4,
      'create_date': '2026-01-01T00:00:00Z',
      'result': {'TEST_TARGET_NAME': '홍길동'},
    });

    expect(item.id, 10);
    expect(item.userId, 20);
    expect(item.testId, 1);
    expect(item.resultId, 123);
    expect(item.status, '4');
    expect(item.createDate, '2026-01-01T00:00:00Z');
    expect(item.result, isNotNull);
  });

  test('UserAccountItem.fromJson keeps resultId null when missing/zero', () {
    final missing = UserAccountItem.fromJson({
      'id': 10,
      'user_id': 20,
      'test_id': 1,
      'status': '3',
    });
    expect(missing.resultId, isNull);

    final zero = UserAccountItem.fromJson({
      'id': 10,
      'user_id': 20,
      'test_id': 1,
      'result_id': 0,
      'status': '3',
    });
    expect(zero.resultId, isNull);
  });
}

