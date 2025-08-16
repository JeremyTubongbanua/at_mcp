import 'base.dart';

class LoggingCapability extends Capability {
  LoggingCapability();

  @override
  Map<String, dynamic> toJson() => {};

  factory LoggingCapability.fromJson(Map<String, dynamic> json) {
    return LoggingCapability();
  }
}