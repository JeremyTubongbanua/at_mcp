class ServerInfo {
  final String name;
  final String version;

  ServerInfo({
    required this.name,
    required this.version,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'version': version,
    };
  }

  factory ServerInfo.fromJson(Map<String, dynamic> json) {
    return ServerInfo(
      name: json['name'],
      version: json['version'],
    );
  }
}

class ClientInfo {
  final String name;
  final String version;

  ClientInfo({
    required this.name,
    required this.version,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'version': version,
    };
  }

  factory ClientInfo.fromJson(Map<String, dynamic> json) {
    return ClientInfo(
      name: json['name'],
      version: json['version'],
    );
  }
}

class Tool {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;

  Tool({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'inputSchema': inputSchema,
    };
  }

  factory Tool.fromJson(Map<String, dynamic> json) {
    return Tool(
      name: json['name'],
      description: json['description'],
      inputSchema: json['inputSchema'],
    );
  }
}

class Resource {
  final String uri;
  final String name;
  final String? description;
  final String? mimeType;

  Resource({
    required this.uri,
    required this.name,
    this.description,
    this.mimeType,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'uri': uri,
      'name': name,
    };
    if (description != null) json['description'] = description;
    if (mimeType != null) json['mimeType'] = mimeType;
    return json;
  }

  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      uri: json['uri'],
      name: json['name'],
      description: json['description'],
      mimeType: json['mimeType'],
    );
  }
}

class ResourceContents {
  final String uri;
  final String? mimeType;
  final String? text;
  final String? blob;

  ResourceContents({
    required this.uri,
    this.mimeType,
    this.text,
    this.blob,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'uri': uri,
    };
    if (mimeType != null) json['mimeType'] = mimeType;
    if (text != null) json['text'] = text;
    if (blob != null) json['blob'] = blob;
    return json;
  }

  factory ResourceContents.fromJson(Map<String, dynamic> json) {
    return ResourceContents(
      uri: json['uri'],
      mimeType: json['mimeType'],
      text: json['text'],
      blob: json['blob'],
    );
  }
}

class Prompt {
  final String name;
  final String? description;
  final List<PromptArgument>? arguments;

  Prompt({
    required this.name,
    this.description,
    this.arguments,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
    };
    if (description != null) json['description'] = description;
    if (arguments != null) {
      json['arguments'] = arguments!.map((arg) => arg.toJson()).toList();
    }
    return json;
  }

  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      name: json['name'],
      description: json['description'],
      arguments: json['arguments'] != null
          ? (json['arguments'] as List).map((arg) => PromptArgument.fromJson(arg)).toList()
          : null,
    );
  }
}

class PromptArgument {
  final String name;
  final String? description;
  final bool? required;

  PromptArgument({
    required this.name,
    this.description,
    this.required,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
    };
    if (description != null) json['description'] = description;
    if (required != null) json['required'] = required;
    return json;
  }

  factory PromptArgument.fromJson(Map<String, dynamic> json) {
    return PromptArgument(
      name: json['name'],
      description: json['description'],
      required: json['required'],
    );
  }
}

class Content {
  final String type;
  final String? text;
  final String? data;
  final String? mimeType;

  Content({
    required this.type,
    this.text,
    this.data,
    this.mimeType,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'type': type,
    };
    if (text != null) json['text'] = text;
    if (data != null) json['data'] = data;
    if (mimeType != null) json['mimeType'] = mimeType;
    return json;
  }

  factory Content.fromJson(Map<String, dynamic> json) {
    return Content(
      type: json['type'],
      text: json['text'],
      data: json['data'],
      mimeType: json['mimeType'],
    );
  }

  factory Content.text(String text) {
    return Content(type: 'text', text: text);
  }

  factory Content.image(String data, String mimeType) {
    return Content(type: 'image', data: data, mimeType: mimeType);
  }
}

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
