import 'dart:convert';

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
    final parsed = _parseViewModel(viewModelRaw, requireHint: false);
    if (parsed != null || viewModelRaw != null) {
      return OpenAIInterpretation(
        title: title,
        response: response,
        viewModel: parsed,
        viewModelMalformed: viewModelRaw != null && parsed == null,
      );
    }

    if (_looksLikeInitialInterpretation(json)) {
      final interpreted = _parseViewModel(json, requireHint: false);
      return OpenAIInterpretation(
        title: title,
        response: response,
        viewModel: interpreted,
        viewModelMalformed: interpreted == null,
      );
    }

    final responseModel = _parseViewModel(response, requireHint: true);
    return OpenAIInterpretation(
      title: title,
      response: response,
      viewModel: responseModel,
      viewModelMalformed: false,
    );
  }
}

int? _asIntOrNull(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

bool _looksLikeInitialInterpretation(Map<String, dynamic> json) {
  final version = json['version']?.toString().trim();
  if (version != null && version.startsWith('initial_interpretation_v1')) {
    return true;
  }
  if (json['cards'] is List || json['headline'] != null || json['next'] != null) {
    return true;
  }
  return false;
}

InitialInterpretationV1? _parseViewModel(
  dynamic raw, {
  required bool requireHint,
}) {
  if (raw == null) return null;
  if (raw is Map) {
    final map = raw.cast<String, dynamic>();
    if (requireHint && !_looksLikeInitialInterpretation(map)) return null;
    try {
      return InitialInterpretationV1.fromJson(map);
    } catch (_) {
      return null;
    }
  }
  if (raw is String) {
    final map = _decodeJsonMap(raw);
    if (map == null) return null;
    if (requireHint && !_looksLikeInitialInterpretation(map)) return null;
    try {
      return InitialInterpretationV1.fromJson(map);
    } catch (_) {
      return null;
    }
  }
  return null;
}

Map<String, dynamic>? _decodeJsonMap(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  Map<String, dynamic>? tryDecode(String candidate) {
    try {
      final decoded = jsonDecode(candidate);
      if (decoded is Map) {
        return decoded.cast<String, dynamic>();
      }
      if (decoded is String) {
        final inner = decoded.trim();
        if (inner.startsWith('{') && inner.endsWith('}')) {
          final innerDecoded = jsonDecode(inner);
          if (innerDecoded is Map) {
            return innerDecoded.cast<String, dynamic>();
          }
        }
      }
    } catch (_) {
      final sanitized = _sanitizeJsonLike(candidate);
      if (sanitized != candidate) {
        try {
          final decoded = jsonDecode(sanitized);
          if (decoded is Map) {
            return decoded.cast<String, dynamic>();
          }
        } catch (_) {}
      }
    }
    return null;
  }

  if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
    final direct = tryDecode(trimmed);
    if (direct != null) return direct;
  }

  if (trimmed.startsWith('```')) {
    final fenceStart = trimmed.indexOf('\n');
    final fenceEnd = trimmed.lastIndexOf('```');
    if (fenceStart != -1 && fenceEnd > fenceStart) {
      final fenced = trimmed.substring(fenceStart, fenceEnd).trim();
      final decoded = tryDecode(fenced);
      if (decoded != null) return decoded;
    }
  }

  final firstBrace = trimmed.indexOf('{');
  final lastBrace = trimmed.lastIndexOf('}');
  if (firstBrace != -1 && lastBrace > firstBrace) {
    final sliced = trimmed.substring(firstBrace, lastBrace + 1);
    final decoded = tryDecode(sliced);
    if (decoded != null) return decoded;
  }

  return null;
}

String _sanitizeJsonLike(String raw) {
  final buffer = StringBuffer();
  var inString = false;
  var escaped = false;
  for (var i = 0; i < raw.length; i++) {
    final ch = raw[i];
    if (inString) {
      final code = ch.codeUnitAt(0);
      if (escaped) {
        escaped = false;
        buffer.write(ch);
        continue;
      }
      if (ch == '\\') {
        escaped = true;
        buffer.write(ch);
        continue;
      }
      if (ch == '"') {
        inString = false;
        buffer.write(ch);
        continue;
      }
      if (code < 0x20) {
        switch (ch) {
          case '\n':
            buffer.write('\\n');
            break;
          case '\r':
            buffer.write('\\r');
            break;
          case '\t':
            buffer.write('\\t');
            break;
          case '\b':
            buffer.write('\\b');
            break;
          case '\f':
            buffer.write('\\f');
            break;
          default:
            buffer.write('\\u${code.toRadixString(16).padLeft(4, '0')}');
            break;
        }
        continue;
      }
      buffer.write(ch);
      continue;
    }

    if (ch == '"') {
      inString = true;
      buffer.write(ch);
      continue;
    }

    if (ch == ',') {
      var j = i + 1;
      while (j < raw.length && _isWhitespace(raw[j])) {
        j++;
      }
      if (j < raw.length && (raw[j] == '}' || raw[j] == ']')) {
        continue;
      }
    }

    buffer.write(ch);
  }
  return buffer.toString();
}

bool _isWhitespace(String ch) =>
    ch == ' ' || ch == '\n' || ch == '\r' || ch == '\t';

