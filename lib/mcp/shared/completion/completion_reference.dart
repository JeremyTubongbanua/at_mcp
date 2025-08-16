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