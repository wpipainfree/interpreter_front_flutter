import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../domain/model/result_models.dart';
import '../../../domain/repository/result_repository.dart';
import '../../../models/openai_interpret_response.dart';
import '../../../utils/strings.dart';

enum InitialInterpretationLoadState { idle, loading, success, error }

class UserResultDetailViewModel extends ChangeNotifier {
  UserResultDetailViewModel(
    this._repository, {
    required this.resultId,
    this.testId,
  });

  final ResultRepository _repository;
  final int resultId;
  final int? testId;

  bool _loading = true;
  String? _error;
  UserResultDetail? _realityDetail;
  UserResultDetail? _idealDetail;
  String? _mindFocus;

  InitialInterpretationLoadState _initialState =
      InitialInterpretationLoadState.idle;
  OpenAIInterpretResponse? _initialInterpretation;
  String? _initialError;

  bool _started = false;
  bool _lastLoggedIn = false;
  String? _lastUserId;

  bool get loading => _loading;
  String? get error => _error;
  UserResultDetail? get realityDetail => _realityDetail;
  UserResultDetail? get idealDetail => _idealDetail;
  String? get mindFocus => _mindFocus;
  bool get isLoggedIn => _repository.isLoggedIn;

  InitialInterpretationLoadState get initialState => _initialState;
  OpenAIInterpretResponse? get initialInterpretation => _initialInterpretation;
  String? get initialError => _initialError;

  String get initialSessionId =>
      (_initialInterpretation?.session?.sessionId ?? '').trim();

  bool get canOpenPhase3 => initialSessionId.isNotEmpty;

  int? get nextTurn {
    if (initialSessionId.isEmpty) return null;
    final serverTurn = _initialInterpretation?.session?.turn;
    if (serverTurn == null) return 2;
    return serverTurn + 1;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _lastLoggedIn = _repository.isLoggedIn;
    _lastUserId = _repository.currentUserId;
    _repository.addAuthListener(_handleAuthChanged);
    await load();
  }

  void stop() {
    if (!_started) return;
    _repository.removeAuthListener(_handleAuthChanged);
    _started = false;
  }

  Future<void> reloadAfterLogin() => load();

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();

    if (!_repository.isLoggedIn) {
      _setLoggedOutState();
      return;
    }

    try {
      final bundle = await _repository.loadBundle(
        resultId: resultId,
        testId: testId,
      );
      final story = (bundle.mindFocus ?? '').trim();
      _mindFocus = story.isEmpty ? null : story;
      _realityDetail = bundle.reality;
      _idealDetail = bundle.ideal;
      _error = null;
      notifyListeners();

      unawaited(
        _loadInitialInterpretation(
          reality: _realityDetail,
          ideal: _idealDetail,
          mindFocus: _mindFocus,
        ),
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> submitStory(String story) async {
    final trimmed = story.trim();
    _mindFocus = trimmed.isEmpty ? null : trimmed;
    notifyListeners();

    await _loadInitialInterpretation(
      reality: _realityDetail,
      ideal: _idealDetail,
      mindFocus: _mindFocus,
      force: false,
    );
  }

  Future<void> retryInitialInterpretation() {
    return _loadInitialInterpretation(
      reality: _realityDetail,
      ideal: _idealDetail,
      mindFocus: _mindFocus,
      force: true,
    );
  }

  Future<void> _loadInitialInterpretation({
    required UserResultDetail? reality,
    required UserResultDetail? ideal,
    required String? mindFocus,
    bool force = false,
  }) async {
    final story = (mindFocus ?? '').trim();
    final realityDetail = reality;

    if (story.isEmpty || realityDetail == null) {
      _initialState = InitialInterpretationLoadState.idle;
      _initialInterpretation = null;
      _initialError = null;
      notifyListeners();
      return;
    }

    _initialState = InitialInterpretationLoadState.loading;
    _initialInterpretation = null;
    _initialError = null;
    notifyListeners();

    try {
      final parsed = await _repository.fetchInitialInterpretation(
        reality: realityDetail,
        ideal: ideal,
        story: story,
        force: force,
      );
      _initialState = InitialInterpretationLoadState.success;
      _initialInterpretation = parsed;
      _initialError = null;
    } catch (e) {
      _initialState = InitialInterpretationLoadState.error;
      _initialError = _repository.mapAiError(e);
    }
    notifyListeners();
  }

  void _handleAuthChanged() {
    final nowLoggedIn = _repository.isLoggedIn;
    final nowUserId = _repository.currentUserId;
    if (nowLoggedIn == _lastLoggedIn && nowUserId == _lastUserId) return;

    _lastLoggedIn = nowLoggedIn;
    _lastUserId = nowUserId;

    if (nowLoggedIn) {
      unawaited(load());
      return;
    }

    _setLoggedOutState();
  }

  void _setLoggedOutState() {
    _realityDetail = null;
    _idealDetail = null;
    _mindFocus = null;
    _initialState = InitialInterpretationLoadState.idle;
    _initialInterpretation = null;
    _initialError = null;
    _loading = false;
    _error = AppStrings.loginRequired;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
