import 'package:flutter_test/flutter_test.dart';
import 'package:wpi_app/domain/model/psych_test_models.dart';
import 'package:wpi_app/domain/usecase/resolve_test_start_permission_use_case.dart';

void main() {
  group('ResolveTestStartPermissionUseCase', () {
    const useCase = ResolveTestStartPermissionUseCase();

    test('allows start when there is a paid and unused account row', () {
      final permission = useCase.resolve(
        accounts: const [
          PsychTestAccountSnapshot(
            status: '2',
            resultId: null,
            useFlag: 'N',
            paymentDate: '2026-02-19T10:00:00Z',
          ),
        ],
      );

      expect(permission.canStart, isTrue);
      expect(permission.reason, TestStartBlockReason.none);
    });

    test('blocks start when no account rows exist', () {
      final permission = useCase.resolve(accounts: const []);

      expect(permission.canStart, isFalse);
      expect(permission.reason, TestStartBlockReason.noEntitlement);
    });

    test('returns resume-required when only in-progress row exists', () {
      final permission = useCase.resolve(
        accounts: const [
          PsychTestAccountSnapshot(
            status: '3',
            resultId: 501,
            paymentDate: '2026-02-19T10:00:00Z',
          ),
        ],
      );

      expect(permission.canStart, isFalse);
      expect(permission.reason, TestStartBlockReason.inProgressResume);
      expect(permission.resumeResultId, 501);
      expect(permission.canResumeExisting, isTrue);
    });

    test('allows new start when unused entitlement exists even with resume row',
        () {
      final permission = useCase.resolve(
        accounts: const [
          PsychTestAccountSnapshot(
            status: '3',
            resultId: 700,
            paymentDate: '2026-02-19T09:00:00Z',
          ),
          PsychTestAccountSnapshot(
            status: '2',
            resultId: null,
            useFlag: 'N',
            paymentDate: '2026-02-19T11:00:00Z',
          ),
        ],
      );

      expect(permission.canStart, isTrue);
    });

    test('blocks pending payment rows', () {
      final permission = useCase.resolve(
        accounts: const [
          PsychTestAccountSnapshot(
            status: '1',
            resultId: null,
          ),
        ],
      );

      expect(permission.canStart, isFalse);
      expect(permission.reason, TestStartBlockReason.pendingPayment);
    });

    test('blocks cancelled/refunded rows', () {
      final permission = useCase.resolve(
        accounts: const [
          PsychTestAccountSnapshot(
            status: '5',
            resultId: null,
          ),
        ],
      );

      expect(permission.canStart, isFalse);
      expect(permission.reason, TestStartBlockReason.cancelledOrRefunded);
    });
  });
}
