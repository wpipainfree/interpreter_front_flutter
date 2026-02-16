class PsychTestItem {
  const PsychTestItem({
    required this.id,
    required this.text,
    this.sequence,
  });

  final int id;
  final String text;
  final int? sequence;
}

enum EvaluationRole {
  self,
  other,
  unknown,
}

class PsychTestChecklist {
  const PsychTestChecklist({
    required this.id,
    required this.name,
    required this.description,
    required this.firstCount,
    required this.secondCount,
    required this.thirdCount,
    required this.sequence,
    required this.question,
    required this.questions,
    this.role = EvaluationRole.unknown,
  });

  final int id;
  final String name;
  final String description;
  final int firstCount;
  final int secondCount;
  final int thirdCount;
  final int sequence;
  final String question;
  final List<PsychTestItem> questions;
  final EvaluationRole role;
}

class WpiSelections {
  const WpiSelections({
    required this.checklistId,
    this.rank1 = const [],
    this.rank2 = const [],
    this.rank3 = const [],
  });

  final int checklistId;
  final List<int> rank1;
  final List<int> rank2;
  final List<int> rank3;

  List<Map<String, dynamic>> toPayload() => [
        {
          'checklist_id': checklistId,
          'ranks': [
            {'rank': 1, 'question_ids': rank1},
            {'rank': 2, 'question_ids': rank2},
            {'rank': 3, 'question_ids': rank3},
          ],
        },
      ];
}

class PsychTestException implements Exception {
  const PsychTestException(this.message, {this.debug});

  final String message;
  final String? debug;

  @override
  String toString() => message;
}
