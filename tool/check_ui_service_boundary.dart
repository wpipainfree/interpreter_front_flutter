import 'dart:io';

void main(List<String> args) {
  final checkAll = args.contains('--all');
  final explicitPaths = _collectOptionValues(args, '--path');

  final targets = explicitPaths.isNotEmpty
      ? explicitPaths
      : (checkAll
          ? const ['lib/screens']
          : const [
              'lib/screens/auth',
              'lib/screens/dashboard_screen.dart',
              'lib/screens/result/user_result_single_screen.dart',
              'lib/screens/result/user_result_detail_screen.dart',
              'lib/screens/result/user_result_detail',
              'lib/screens/payment/payment_webview_screen.dart',
              'lib/screens/main_shell.dart',
              'lib/screens/mymind/interpretation_panel.dart',
              'lib/screens/mymind/interpretation_record_panel.dart',
              'lib/screens/mymind/my_mind_page.dart',
              'lib/screens/mymind/today_mind_read_flow_screen.dart',
              'lib/screens/test/wpi_review_screen.dart',
              'lib/screens/test/wpi_selection_flow_new.dart',
              'lib/screens/test/wpi_selection_screen.dart',
              'lib/screens/profile/my_page_screen.dart',
              'lib/screens/profile/payment_history_screen.dart',
              'lib/screens/settings/notification_settings_screen.dart',
              'lib/screens/settings/terms_agreement_settings_screen.dart',
            ]);

  final violations = <String>[];
  for (final target in targets) {
    final entityType = FileSystemEntity.typeSync(target);
    if (entityType == FileSystemEntityType.notFound) {
      stderr.writeln('[check_ui_service_boundary] missing target: $target');
      exitCode = 2;
      return;
    }
    if (entityType == FileSystemEntityType.file) {
      _collectViolationsFromFile(File(target), violations);
      continue;
    }
    if (entityType == FileSystemEntityType.directory) {
      final directory = Directory(target);
      for (final entity in directory.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        _collectViolationsFromFile(entity, violations);
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln(
      '[check_ui_service_boundary] forbidden services import detected:',
    );
    for (final violation in violations) {
      stderr.writeln('  - $violation');
    }
    exitCode = 1;
    return;
  }

  stdout.writeln(
    '[check_ui_service_boundary] passed: no forbidden services imports.',
  );
}

List<String> _collectOptionValues(List<String> args, String option) {
  final values = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] != option) continue;
    if (i + 1 >= args.length) {
      stderr.writeln('[check_ui_service_boundary] missing value for $option');
      exitCode = 2;
      return values;
    }
    values.add(args[i + 1]);
    i += 1;
  }
  return values;
}

void _collectViolationsFromFile(File file, List<String> violations) {
  final lines = file.readAsLinesSync();
  final importPattern =
      RegExp(r'''^\s*import\s+['"][^'"]*services/[^'"]*['"];''');
  for (var i = 0; i < lines.length; i++) {
    if (!importPattern.hasMatch(lines[i])) continue;
    violations.add('${file.path}:${i + 1}');
  }
}
