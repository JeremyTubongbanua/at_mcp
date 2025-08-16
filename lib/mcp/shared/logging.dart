enum LogLevel { debug, info, notice, warning, error, critical, alert, emergency }

class LoggingMessage {
  final LogLevel level;
  final String? data;
  final String? logger;

  LoggingMessage({
    required this.level,
    this.data,
    this.logger,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'level': level.name,
    };
    if (data != null) json['data'] = data;
    if (logger != null) json['logger'] = logger;
    return json;
  }

  factory LoggingMessage.fromJson(Map<String, dynamic> json) {
    return LoggingMessage(
      level: LogLevel.values.firstWhere((e) => e.name == json['level']),
      data: json['data'],
      logger: json['logger'],
    );
  }
}