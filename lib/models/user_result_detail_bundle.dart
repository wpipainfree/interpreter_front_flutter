import '../services/psych_tests_service.dart';

class UserResultDetailBundle {
  const UserResultDetailBundle({
    required this.reality,
    required this.ideal,
    required this.mindFocus,
  });

  final UserResultDetail? reality;
  final UserResultDetail? ideal;
  final String? mindFocus;

  bool get isEmpty => reality == null && ideal == null;
}

