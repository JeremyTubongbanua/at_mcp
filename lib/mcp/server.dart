import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'protocol.dart';
import 'models.dart';
import 'capabilities.dart';

abstract class McpToolHandler {
  String get name;
  String get description;
  Map<String, dynamic> get inputSchema;
  
  Future<List<Content>> call(Map<String, dynamic> arguments);
}

abstract class McpResourceHandler {
  String get uri;
  String get name;
  String get description;
  String get mimeType;
  
  Future<ResourceContents> read();
}

class McpServer {
  final ServerInfo _serverInfo;
  final ServerCapabilities _capabilities;
  final Map<String, McpToolHandler> _tools = {};
  final Map<String, McpResourceHandler> _resources = {};
  
  StreamController<JsonRpcNotification>? _notificationController;
  
  McpServer({
    required ServerInfo serverInfo,
    ServerCapabilities? capabilities,
  }) : _serverInfo = serverInfo,
       _capabilities = capabilities ?? ServerCapabilities(
         tools: ToolsCapability(listChanged: true),
         resources: ResourcesCapability(listChanged: true),
       );

  void addTool(McpToolHandler tool) {
    _tools[tool.name] = tool;
  }

  void removeTool(String name) {
    _tools.remove(name);
  }

  void addResource(McpResourceHandler resource) {
    _resources[resource.uri] = resource;
  }

  void removeResource(String uri) {
    _resources.remove(uri);
  }

  Stream<JsonRpcNotification> get notifications {
    _notificationController ??= StreamController<JsonRpcNotification>.broadcast();
    return _notificationController!.stream;
  }

  void sendNotification(String method, [Map<String, dynamic>? params]) {
    _notificationController?.add(JsonRpcNotification(
      method: method,
      params: params,
    ));
  }

  Future<void> start() async {
    await for (String line in stdin.transform(utf8.decoder).transform(LineSplitter())) {
      try {
        final json = jsonDecode(line) as Map<String, dynamic>;
        
        if (json.containsKey('id')) {
          final request = JsonRpcRequest.fromJson(json);
          final response = await _handleRequest(request);
          print(jsonEncode(response.toJson()));
        } else {
          final notification = JsonRpcNotification.fromJson(json);
          await _handleNotification(notification);
        }
      } catch (e) {
        final errorResponse = JsonRpcResponse(
          id: null,
          error: JsonRpcError.parseError(),
        );
        print(jsonEncode(errorResponse.toJson()));
      }
    }
  }

  Future<JsonRpcResponse> _handleRequest(JsonRpcRequest request) async {
    try {
      switch (request.method) {
        case 'initialize':
          return JsonRpcResponse(
            id: request.id,
            result: {
              'protocolVersion': '2024-11-05',
              'capabilities': _capabilities.toJson(),
              'serverInfo': _serverInfo.toJson(),
            },
          );

        case 'tools/list':
          final tools = _tools.values.map((tool) => Tool(
            name: tool.name,
            description: tool.description,
            inputSchema: tool.inputSchema,
          ).toJson()).toList();
          
          return JsonRpcResponse(
            id: request.id,
            result: {'tools': tools},
          );

        case 'tools/call':
          final params = request.params ?? {};
          final toolName = params['name'] as String?;
          final arguments = params['arguments'] as Map<String, dynamic>? ?? {};
          
          if (toolName == null) {
            return JsonRpcResponse(
              id: request.id,
              error: JsonRpcError.invalidParams(),
            );
          }
          
          final tool = _tools[toolName];
          if (tool == null) {
            return JsonRpcResponse(
              id: request.id,
              error: JsonRpcError.methodNotFound(),
            );
          }
          
          try {
            final content = await tool.call(arguments);
            return JsonRpcResponse(
              id: request.id,
              result: {'content': content.map((c) => c.toJson()).toList()},
            );
          } catch (e) {
            return JsonRpcResponse(
              id: request.id,
              error: JsonRpcError.internalError(),
            );
          }

        case 'resources/list':
          final resources = _resources.values.map((resource) => Resource(
            uri: resource.uri,
            name: resource.name,
            description: resource.description,
            mimeType: resource.mimeType,
          ).toJson()).toList();
          
          return JsonRpcResponse(
            id: request.id,
            result: {'resources': resources},
          );

        case 'resources/read':
          final params = request.params ?? {};
          final uri = params['uri'] as String?;
          
          if (uri == null) {
            return JsonRpcResponse(
              id: request.id,
              error: JsonRpcError.invalidParams(),
            );
          }
          
          final resource = _resources[uri];
          if (resource == null) {
            return JsonRpcResponse(
              id: request.id,
              error: JsonRpcError.methodNotFound(),
            );
          }
          
          try {
            final contents = await resource.read();
            return JsonRpcResponse(
              id: request.id,
              result: {'contents': [contents.toJson()]},
            );
          } catch (e) {
            return JsonRpcResponse(
              id: request.id,
              error: JsonRpcError.internalError(),
            );
          }

        default:
          return JsonRpcResponse(
            id: request.id,
            error: JsonRpcError.methodNotFound(),
          );
      }
    } catch (e) {
      return JsonRpcResponse(
        id: request.id,
        error: JsonRpcError.internalError(),
      );
    }
  }

  Future<void> _handleNotification(JsonRpcNotification notification) async {
  }

  void dispose() {
    _notificationController?.close();
  }
}