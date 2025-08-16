class Prompt {
  final String name;
  final String? description;
  final List<PromptArgument>? arguments;

  Prompt({
    required this.name,
    this.description,
    this.arguments,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
    };
    if (description != null) json['description'] = description;
    if (arguments != null) {
      json['arguments'] = arguments!.map((arg) => arg.toJson()).toList();
    }
    return json;
  }

  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      name: json['name'],
      description: json['description'],
      arguments: json['arguments'] != null
          ? (json['arguments'] as List).map((arg) => PromptArgument.fromJson(arg)).toList()
          : null,
    );
  }
}

class PromptArgument {
  final String name;
  final String? description;
  final bool? required;

  PromptArgument({
    required this.name,
    this.description,
    this.required,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
    };
    if (description != null) json['description'] = description;
    if (required != null) json['required'] = required;
    return json;
  }

  factory PromptArgument.fromJson(Map<String, dynamic> json) {
    return PromptArgument(
      name: json['name'],
      description: json['description'],
      required: json['required'],
    );
  }
}