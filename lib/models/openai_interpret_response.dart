import 'initial_interpretation_v1.dart';

class OpenAIInterpretResponse {
  const OpenAIInterpretResponse({
    required this.session,
    required this.interpretation,
  });

  final OpenAIInterpretSession? session;
  final OpenAIInterpretation? interpretation;

  factory OpenAIInterpretResponse.fromJson(Map<String, dynamic> json) {
    final sessionRaw = json['session'];
    final session = sessionRaw is Map
        ? OpenAIInterpretSession.fromJson(sessionRaw.cast<String, dynamic>())
        : null;

    final interpretationRaw = json['interpretation'];
    final OpenAIInterpretation? interpretation;
    if (interpretationRaw is Map) {
      interpretation =
          OpenAIInterpretation.fromJson(interpretationRaw.cast<String, dynamic>());
    } else if (interpretationRaw != null) {
      interpretation = OpenAIInterpretation(
        title: '',
        response: interpretationRaw.toString(),
        viewModel: null,
        viewModelMalformed: false,
      );
    } else {
      interpretation = null;
    }

    return OpenAIInterpretResponse(
      session: session,
      interpretation: interpretation,
    );
  }
}

class OpenAIInterpretSession {
  const OpenAIInterpretSession({
    required this.sessionId,
    required this.turn,
  });

  final String sessionId;
  final int? turn;

  factory OpenAIInterpretSession.fromJson(Map<String, dynamic> json) {
    final sessionId = (json['session_id'] ?? json['sessionId'] ?? '')
        .toString()
        .trim();
    final turn = _asIntOrNull(json['turn']);
    return OpenAIInterpretSession(sessionId: sessionId, turn: turn);
  }
}

class OpenAIInterpretation {
  const OpenAIInterpretation({
    required this.title,
    required this.response,
    required this.viewModel,
    required this.viewModelMalformed,
  });

  final String title;
  final String response;
  final InitialInterpretationV1? viewModel;
  final bool viewModelMalformed;

  factory OpenAIInterpretation.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] ?? '').toString().trim();
    final response = (json['response'] ?? '').toString().trim();

    final viewModelRaw = json['view_model'] ?? json['viewModel'];
    if (viewModelRaw == null) {
      return OpenAIInterpretation(
        title: title,
        response: response,
        viewModel: null,
        viewModelMalformed: false,
      );
    }

    if (viewModelRaw is! Map) {
      return OpenAIInterpretation(
        title: title,
        response: response,
        viewModel: null,
        viewModelMalformed: true,
      );
    }

    try {
      final viewModel =
          InitialInterpretationV1.fromJson(viewModelRaw.cast<String, dynamic>());
      return OpenAIInterpretation(
        title: title,
        response: response,
        viewModel: viewModel,
        viewModelMalformed: false,
      );
    } catch (_) {
      return OpenAIInterpretation(
        title: title,
        response: response,
        viewModel: null,
        viewModelMalformed: true,
      );
    }
  }
}

int? _asIntOrNull(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

