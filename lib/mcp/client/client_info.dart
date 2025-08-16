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