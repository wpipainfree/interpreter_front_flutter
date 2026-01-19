import 'package:flutter/foundation.dart';

/// Global tab index controller for [MainShell].
///
/// This avoids pushing tab root screens (which would hide the bottom tab bar)
/// and allows widgets inside tabs to request tab switches.
class MainShellTabController {
  MainShellTabController._();

  static final ValueNotifier<int> index = ValueNotifier<int>(0);
}

