import 'completion_option.dart';

class CompletionResult {
  final List<CompletionOption> completion;
  final bool? hasMore;
  final int? total;

  CompletionResult({
    required this.completion,
    this.hasMore,
    this.total,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'completion': completion.map((c) => c.toJson()).toList(),
    };
    if (hasMore != null) json['hasMore'] = hasMore;
    if (total != null) json['total'] = total;
    return json;
  }

  factory CompletionResult.fromJson(Map<String, dynamic> json) {
    return CompletionResult(
      completion: (json['completion'] as List)
          .map((c) => CompletionOption.fromJson(c))
          .toList(),
      hasMore: json['hasMore'],
      total: json['total'],
    );
  }
}