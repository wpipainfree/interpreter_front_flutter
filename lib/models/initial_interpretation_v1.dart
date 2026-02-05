class InitialInterpretationV1 {
  const InitialInterpretationV1({
    required this.headline,
    required this.cards,
    required this.next,
    required this.suggestedPrompts,
  });

  static const List<String> orderedCardIds = [
    'story_link',
    'standard',
    'belief',
    'emotion_body',
    'direction',
  ];

  final String headline;
  final List<InitialInterpretationCard> cards;
  final InitialInterpretationNext next;
  final List<String> suggestedPrompts;

  factory InitialInterpretationV1.fromJson(Map<String, dynamic> json) {
    final headline = (json['headline'] ?? '').toString().trim();

    final cardsRaw = json['cards'];
    final cards = (cardsRaw is List ? cardsRaw : const [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .map(InitialInterpretationCard.fromJson)
        .toList();

    final ordered = _orderCards(cards);

    final nextRaw = json['next'];
    final next = nextRaw is Map
        ? InitialInterpretationNext.fromJson(nextRaw.cast<String, dynamic>())
        : const InitialInterpretationNext(ctaLabel: '');

    var promptsRaw = json['suggested_prompts'] ?? json['suggestedPrompts'];
    if (promptsRaw == null && nextRaw is Map) {
      promptsRaw =
          nextRaw['suggested_prompts'] ?? nextRaw['suggestedPrompts'];
    }
    final suggestedPrompts = (promptsRaw is List ? promptsRaw : const [])
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .take(3)
        .toList(growable: false);

    return InitialInterpretationV1(
      headline: headline,
      cards: ordered,
      next: next,
      suggestedPrompts: suggestedPrompts,
    );
  }

  Map<String, dynamic> toJson() => {
        'headline': headline,
        'cards': cards.map((e) => e.toJson()).toList(),
        'next': next.toJson(),
        'suggested_prompts': suggestedPrompts,
      };

  static List<InitialInterpretationCard> _orderCards(
    List<InitialInterpretationCard> cards,
  ) {
    if (cards.isEmpty) return cards;
    final byId = {for (final card in cards) card.id: card};
    final ordered = <InitialInterpretationCard>[];
    for (final id in orderedCardIds) {
      final card = byId.remove(id);
      if (card != null) ordered.add(card);
    }
    ordered.addAll(byId.values);
    return ordered;
  }
}

class InitialInterpretationCard {
  const InitialInterpretationCard({
    required this.id,
    required this.title,
    required this.summary,
    required this.bullets,
    required this.checkQuestion,
  });

  final String id;
  final String title;
  final String summary;
  final List<String> bullets;
  final String? checkQuestion;

  factory InitialInterpretationCard.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString().trim();
    final title = (json['title'] ?? '').toString().trim();
    final summary = (json['summary'] ?? '').toString().trim();

    final bulletsRaw = json['bullets'];
    final bullets = (bulletsRaw is List ? bulletsRaw : const [])
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    final checkQuestion =
        (json['check_question'] ?? json['checkQuestion'])?.toString().trim();
    final normalizedCheck =
        (checkQuestion != null && checkQuestion.isNotEmpty) ? checkQuestion : null;

    return InitialInterpretationCard(
      id: id,
      title: title,
      summary: summary,
      bullets: bullets,
      checkQuestion: normalizedCheck,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'bullets': bullets,
        'check_question': checkQuestion,
      };
}

class InitialInterpretationNext {
  const InitialInterpretationNext({
    required this.ctaLabel,
    this.action,
  });

  final String ctaLabel;
  final String? action;

  factory InitialInterpretationNext.fromJson(Map<String, dynamic> json) {
    final ctaLabel = (json['cta_label'] ?? json['ctaLabel'] ?? '')
        .toString()
        .trim();
    final action = json['action']?.toString().trim();
    final normalizedAction = (action != null && action.isNotEmpty) ? action : null;
    return InitialInterpretationNext(ctaLabel: ctaLabel, action: normalizedAction);
  }

  Map<String, dynamic> toJson() => {
        'cta_label': ctaLabel,
        'action': action,
      };
}

