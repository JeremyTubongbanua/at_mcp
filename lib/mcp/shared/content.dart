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
