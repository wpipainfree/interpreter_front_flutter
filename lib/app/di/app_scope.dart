import '../../data/repository/auth_repository_impl.dart';
import '../../domain/repository/auth_repository.dart';
import '../../services/auth_service.dart';

class AppScope {
  AppScope._internal();

  static final AppScope instance = AppScope._internal();

  late final AuthService _authService = AuthService();

  late final AuthRepository authRepository =
      AuthRepositoryImpl(authService: _authService);
}
