import 'sampling_capability.dart';
import 'roots_capability.dart';

class ClientCapabilities {
  final SamplingCapability? sampling;
  final RootsCapability? roots;

  ClientCapabilities({
    this.sampling,
    this.roots,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (sampling != null) json['sampling'] = sampling!.toJson();
    if (roots != null) json['roots'] = roots!.toJson();
    return json;
  }

  factory ClientCapabilities.fromJson(Map<String, dynamic> json) {
    return ClientCapabilities(
      sampling: json['sampling'] != null ? SamplingCapability.fromJson(json['sampling']) : null,
      roots: json['roots'] != null ? RootsCapability.fromJson(json['roots']) : null,
    );
  }
}