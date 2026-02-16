import '../../../common/failure.dart';
import '../../../domain/repository/auth_repository.dart';

enum LoginAction {
  success,
  signupRequired,
  failed,
}

class LoginFlowResult {
  const LoginFlowResult._(this.action, [this.failure]);

  final LoginAction action;
  final Failure? failure;

  const LoginFlowResult.success() : this._(LoginAction.success);

  const LoginFlowResult.signupRequired() : this._(LoginAction.signupRequired);

  const LoginFlowResult.failed(Failure failure)
      : this._(LoginAction.failed, failure);
}

class LoginViewModel {
  LoginViewModel(this._authRepository);

  final AuthRepository _authRepository;

  Future<LoginFlowResult> loginWithSocial(String provider) async {
    final result = await _authRepository.loginWithSocial(provider);
    return result.when(
      success: (_) => const LoginFlowResult.success(),
      failure: (failure) {
        if (failure.hasCode('USER_NOT_REGISTERED')) {
          return const LoginFlowResult.signupRequired();
        }
        return LoginFlowResult.failed(failure);
      },
    );
  }

  Future<LoginFlowResult> loginAsGuest() async {
    final result = await _authRepository.loginAsGuest();
    return result.when(
      success: (_) => const LoginFlowResult.success(),
      failure: LoginFlowResult.failed,
    );
  }
}
