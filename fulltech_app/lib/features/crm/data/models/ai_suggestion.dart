class AiSuggestion {
  final String id;
  final String text;
  final double? confidence;
  final List<String> tags;

  const AiSuggestion({
    required this.id,
    required this.text,
    required this.confidence,
    required this.tags,
  });

  factory AiSuggestion.fromJson(Map<String, dynamic> json) {
    return AiSuggestion(
      id: (json['id'] ?? '') as String,
      text: (json['text'] ?? '') as String,
      confidence: (json['confidence'] is num) ? (json['confidence'] as num).toDouble() : null,
      tags: (json['tags'] is List)
          ? (json['tags'] as List).map((e) => e.toString()).toList()
          : const <String>[],
    );
  }
}

class AiSuggestResponse {
  final List<AiSuggestion> suggestions;
  final List<String> usedKnowledge;

  const AiSuggestResponse({
    required this.suggestions,
    required this.usedKnowledge,
  });

  factory AiSuggestResponse.fromJson(Map<String, dynamic> json) {
    final items = (json['suggestions'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(AiSuggestion.fromJson)
        .toList();

    final used = (json['usedKnowledge'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();

    return AiSuggestResponse(suggestions: items, usedKnowledge: used);
  }
}
