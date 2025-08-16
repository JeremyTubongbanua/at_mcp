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