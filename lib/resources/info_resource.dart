import '../mcp.dart';

class InfoResource implements McpResourceHandler {
  @override
  String get uri => 'info://server';

  @override
  String get name => 'Server Information';

  @override
  String get description => 'Basic information about this MCP server';

  @override
  String get mimeType => 'text/plain';

  @override
  Future<ResourceContents> read() async {
    return ResourceContents(
      uri: uri,
      mimeType: mimeType,
      text: 'AT MCP Server v1.0.0\nA basic MCP server implementation in Dart\nProtocol Version: 2024-11-05',
    );
  }
}