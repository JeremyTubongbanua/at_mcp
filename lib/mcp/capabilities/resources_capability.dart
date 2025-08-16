import 'base.dart';

class ResourcesCapability extends Capability {
  final bool? subscribe;
  final bool? listChanged;

  ResourcesCapability({
    this.subscribe,
    this.listChanged,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (subscribe != null) json['subscribe'] = subscribe;
    if (listChanged != null) json['listChanged'] = listChanged;
    return json;
  }

  factory ResourcesCapability.fromJson(Map<String, dynamic> json) {
    return ResourcesCapability(
      subscribe: json['subscribe'],
      listChanged: json['listChanged'],
    );
  }
}