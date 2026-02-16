import '../../data/repository/auth_repository_impl.dart';
import '../../data/repository/dashboard_repository_impl.dart';
import '../../data/repository/notification_repository_impl.dart';
import '../../data/repository/payment_repository_impl.dart';
import '../../data/repository/profile_repository_impl.dart';
import '../../data/repository/result_repository_impl.dart';
import '../../domain/repository/auth_repository.dart';
import '../../domain/repository/dashboard_repository.dart';
import '../../domain/repository/notification_repository.dart';
import '../../domain/repository/payment_repository.dart';
import '../../domain/repository/profile_repository.dart';
import '../../domain/repository/result_repository.dart';
import '../../services/auth_service.dart';
import '../../services/ai_assistant_service.dart';
import '../../services/notification_service.dart';
import '../../services/psych_tests_service.dart';
import '../../services/payment_service.dart';

class AppScope {
  AppScope._internal();

  static final AppScope instance = AppScope._internal();

  late final AuthService _authService = AuthService();

  late final AuthRepository authRepository =
      AuthRepositoryImpl(authService: _authService);

  late final DashboardRepository dashboardRepository = DashboardRepositoryImpl(
    authService: _authService,
    psychTestsService: PsychTestsService(),
    aiAssistantService: AiAssistantService(),
    paymentService: PaymentService(),
  );

  late final ResultRepository resultRepository = ResultRepositoryImpl(
    authService: _authService,
    psychTestsService: PsychTestsService(),
    aiAssistantService: AiAssistantService(),
  );

  late final PaymentRepository paymentRepository = PaymentRepositoryImpl(
    paymentService: PaymentService(),
  );

  late final NotificationRepository notificationRepository =
      NotificationRepositoryImpl(
    service: NotificationService(),
  );

  late final ProfileRepository profileRepository = ProfileRepositoryImpl(
    authService: _authService,
  );
}
