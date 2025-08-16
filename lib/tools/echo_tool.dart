import '../mcp.dart';

class EchoTool implements McpToolHandler {
  @override
  String get name => 'echo';

  @override
  String get description => 'Echo back the input message';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'message': {
        'type': 'string',
        'description': 'The message to echo back'
      }
    },
    'required': ['message']
  };

  @override
  Future<List<Content>> call(Map<String, dynamic> arguments) async {
    final message = arguments['message'] as String?;
    if (message == null) {
      throw ArgumentError('message parameter is required');
    }
    return [Content.text('Echo: $message')];
  }
}