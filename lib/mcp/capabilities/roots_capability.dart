import 'base.dart';

class RootsCapability extends Capability {
  final bool? listChanged;

  RootsCapability({this.listChanged});

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (listChanged != null) json['listChanged'] = listChanged;
    return json;
  }

  factory RootsCapability.fromJson(Map<String, dynamic> json) {
    return RootsCapability(
      listChanged: json['listChanged'],
    );
  }
}