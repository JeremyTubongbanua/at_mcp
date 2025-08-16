import 'base.dart';

class CompletionsCapability extends Capability {
  final bool? listChanged;

  CompletionsCapability({this.listChanged});

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (listChanged != null) json['listChanged'] = listChanged;
    return json;
  }

  factory CompletionsCapability.fromJson(Map<String, dynamic> json) {
    return CompletionsCapability(
      listChanged: json['listChanged'],
    );
  }
}