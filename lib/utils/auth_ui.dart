import 'dart:async';

import 'package:flutter/material.dart';

import '../router/app_routes.dart';
import '../services/auth_service.dart';
import 'app_navigator.dart';

class AuthUi {
  AuthUi._();

  static Completer<bool>? _loginCompleter;

  static Future<T?> withLoginRetry<T>({
    required Future<T> Function() action,
    BuildContext? context,
  }) async {
    try {
      return await action();
    } on AuthRequiredException {
      final ok = await promptLogin(context: context);
      if (!ok) return null;
      return await action();
    }
  }

  static Future<bool> promptLogin({BuildContext? context}) {
    if (AuthService().isLoggedIn) {
      return Future.value(true);
    }

    final existing = _loginCompleter;
    if (existing != null) return existing.future;

    final completer = Completer<bool>();
    _loginCompleter = completer;

    () async {
      try {
        final navigator = context != null
            ? Navigator.of(context, rootNavigator: true)
            : AppNavigator.key.currentState;
        if (navigator == null) {
          completer.complete(false);
          return;
        }

        final ok = await navigator.pushNamed<bool>(AppRoutes.login);
        completer.complete(ok == true);
      } catch (_) {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      } finally {
        _loginCompleter = null;
      }
    }();

    return completer.future;
  }
}
