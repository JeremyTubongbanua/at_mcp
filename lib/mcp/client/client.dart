import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../shared.dart';
import '../server/tool.dart';
import '../server/resource.dart';
import '../server/capabilities/client_capabilities.dart';
import 'client_info.dart';

class McpClient {
  final ClientInfo _clientInfo;
  final ClientCapabilities _capabilities;
  Process? _process;
  StreamSubscription<String>? _subscription;
  final Map<dynamic, Completer<JsonRpcResponse>> _pendingRequests = {};
  int _requestId = 0;

  McpClient({
    required ClientInfo clientInfo,
    ClientCapabilities? capabilities,
  }) : _clientInfo = clientInfo,
       _capabilities = capabilities ?? ClientCapabilities();

  Future<void> connect(String executable, List<String> args) async {
    _process = await Process.start(executable, args);
    
    _subscription = _process!.stdout
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .listen(_handleMessage);
  }

  void _handleMessage(String line) {
    try {
      final json = jsonDecode(line) as Map<String, dynamic>;
      
      if (json.containsKey('id')) {
        final response = JsonRpcResponse.fromJson(json);
        final completer = _pendingRequests.remove(response.id);
        completer?.complete(response);
      } else {
        final notification = JsonRpcNotification.fromJson(json);
        _handleNotification(notification);
      }
    } catch (e) {
      // Ignore parse errors
    }
  }

  void _handleNotification(JsonRpcNotification notification) {
  }

  Future<JsonRpcResponse> _sendRequest(String method, [Map<String, dynamic>? params]) async {
    if (_process == null) {
      throw StateError('Client not connected');
    }

    final id = _requestId++;
    final request = JsonRpcRequest(
      id: id,
      method: method,
      params: params,
    );

    final completer = Completer<JsonRpcResponse>();
    _pendingRequests[id] = completer;

    _process!.stdin.writeln(jsonEncode(request.toJson()));

    return completer.future;
  }

  Future<Map<String, dynamic>> initialize() async {
    final response = await _sendRequest('initialize', {
      'protocolVersion': '2024-11-05',
      'capabilities': _capabilities.toJson(),
      'clientInfo': _clientInfo.toJson(),
    });

    if (response.error != null) {
      throw Exception('Initialize failed: ${response.error!.message}');
    }

    return response.result as Map<String, dynamic>;
  }

  Future<List<Tool>> listTools() async {
    final response = await _sendRequest('tools/list');
    
    if (response.error != null) {
      throw Exception('List tools failed: ${response.error!.message}');
    }

    final result = response.result as Map<String, dynamic>;
    final tools = result['tools'] as List;
    return tools.map((tool) => Tool.fromJson(tool)).toList();
  }

  Future<List<Content>> callTool(String name, [Map<String, dynamic>? arguments]) async {
    final response = await _sendRequest('tools/call', {
      'name': name,
      'arguments': arguments ?? {},
    });
    
    if (response.error != null) {
      throw Exception('Call tool failed: ${response.error!.message}');
    }

    final result = response.result as Map<String, dynamic>;
    final content = result['content'] as List;
    return content.map((c) => Content.fromJson(c)).toList();
  }

  Future<List<Resource>> listResources() async {
    final response = await _sendRequest('resources/list');
    
    if (response.error != null) {
      throw Exception('List resources failed: ${response.error!.message}');
    }

    final result = response.result as Map<String, dynamic>;
    final resources = result['resources'] as List;
    return resources.map((resource) => Resource.fromJson(resource)).toList();
  }

  Future<List<ResourceContents>> readResource(String uri) async {
    final response = await _sendRequest('resources/read', {
      'uri': uri,
    });
    
    if (response.error != null) {
      throw Exception('Read resource failed: ${response.error!.message}');
    }

    final result = response.result as Map<String, dynamic>;
    final contents = result['contents'] as List;
    return contents.map((c) => ResourceContents.fromJson(c)).toList();
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _process?.kill();
    _process = null;
    
    for (final completer in _pendingRequests.values) {
      completer.completeError(StateError('Client disconnected'));
    }
    _pendingRequests.clear();
  }
}
