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