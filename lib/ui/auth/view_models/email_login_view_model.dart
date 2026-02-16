import '../../../common/result.dart';
import '../../../domain/model/auth_user.dart';
import '../../../domain/repository/auth_repository.dart';

class EmailLoginViewModel {
  EmailLoginViewModel(this._authRepository);

  final AuthRepository _authRepository;

  Future<Result<AuthUser>> loginWithEmail({
    required String email,
    required String password,
  }) {
    return _authRepository.loginWithEmail(
      email: email,
      password: password,
    );
  }
}
