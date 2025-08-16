import 'completion_reference.dart';

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