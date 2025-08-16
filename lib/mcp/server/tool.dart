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