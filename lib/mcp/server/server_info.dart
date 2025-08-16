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