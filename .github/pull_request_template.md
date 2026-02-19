## Summary

- What changed:
- Why:

## Architecture Boundary Checklist

- [ ] No direct `lib/services` import from `lib/screens` files in changed scope
- [ ] `ViewModel`/`Use-case` does not depend on `BuildContext`
- [ ] External dependencies are injected by constructor (replaceable with fake/mock)
- [ ] Failure paths (network/auth/permission) are explicitly handled

## Test Checklist

- [ ] Unit test added or updated
- [ ] Widget test added or updated (if UI changed)
- [ ] `dart run tool/check_ui_service_boundary.dart --all` passed locally
- [ ] `flutter analyze --no-fatal-infos` passed locally
- [ ] `flutter test` passed locally
