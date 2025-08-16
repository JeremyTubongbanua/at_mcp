class CompletionReference {
  final String type;
  final String? name;
  final String? uri;

  CompletionReference({
    required this.type,
    this.name,
    this.uri,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': type,
    };
    if (name != null) json['name'] = name;
    if (uri != null) json['uri'] = uri;
    return json;
  }

  factory CompletionReference.fromJson(Map<String, dynamic> json) {
    return CompletionReference(
      type: json['type'],
      name: json['name'],
      uri: json['uri'],
    );
  }

  factory CompletionReference.resource(String uri) {
    return CompletionReference(
      type: 'ref/resource',
      uri: uri,
    );
  }

  factory CompletionReference.prompt(String name) {
    return CompletionReference(
      type: 'ref/prompt',
      name: name,
    );
  }
}

class CompletionOption {
  final CompletionReference reference;
  final String? description;

  CompletionOption({
    required this.reference,
    this.description,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'reference': reference.toJson(),
    };
    if (description != null) json['description'] = description;
    return json;
  }

  factory CompletionOption.fromJson(Map<String, dynamic> json) {
    return CompletionOption(
      reference: CompletionReference.fromJson(json['reference']),
      description: json['description'],
    );
  }
}

class CompletionArgument {
  final String name;
  final String value;

  CompletionArgument({
    required this.name,
    required this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
    };
  }

  factory CompletionArgument.fromJson(Map<String, dynamic> json) {
    return CompletionArgument(
      name: json['name'],
      value: json['value'],
    );
  }
}

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