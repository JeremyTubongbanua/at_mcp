import 'base.dart';

class SamplingCapability extends Capability {
  SamplingCapability();

  @override
  Map<String, dynamic> toJson() => {};

  factory SamplingCapability.fromJson(Map<String, dynamic> json) {
    return SamplingCapability();
  }
}