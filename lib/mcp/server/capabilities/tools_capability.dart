import 'base.dart';

class ToolsCapability extends Capability {
  final bool? listChanged;

  ToolsCapability({this.listChanged});

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (listChanged != null) json['listChanged'] = listChanged;
    return json;
  }

  factory ToolsCapability.fromJson(Map<String, dynamic> json) {
    return ToolsCapability(
      listChanged: json['listChanged'],
    );
  }
}