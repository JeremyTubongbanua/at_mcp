import 'base.dart';

class PromptsCapability extends Capability {
  final bool? listChanged;

  PromptsCapability({this.listChanged});

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (listChanged != null) json['listChanged'] = listChanged;
    return json;
  }

  factory PromptsCapability.fromJson(Map<String, dynamic> json) {
    return PromptsCapability(
      listChanged: json['listChanged'],
    );
  }
}