import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'transport.dart';

class WebSocketServerTransport implements McpTransport {
  final int port;
  final String? host;
  final StreamController<String> _messageController = StreamController<String>.broadcast();
  HttpServer? _server;
  WebSocket? _webSocket;
  bool _connected = false;

  WebSocketServerTransport({
    required this.port,
    this.host = 'localhost',
  });

  @override
  Stream<String> get messages => _messageController.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    if (_connected) {
      throw StateError('Already connected');
    }

    _server = await HttpServer.bind(host ?? 'localhost', port);
    
    _server!.listen((HttpRequest request) async {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        _webSocket = await WebSocketTransformer.upgrade(request);
        _webSocket!.listen(
          (message) {
            if (message is String) {
              _messageController.add(message);
            }
          },
          onError: (error) => _messageController.addError(error),
          onDone: () => disconnect(),
        );
        _connected = true;
      } else {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
      }
    });
  }

  @override
  void sendMessage(String message) {
    if (!_connected || _webSocket == null) {
      throw StateError('Not connected');
    }
    _webSocket!.add(message);
  }

  @override
  Future<void> disconnect() async {
    if (!_connected) return;
    
    await _webSocket?.close();
    await _server?.close();
    _webSocket = null;
    _server = null;
    _connected = false;
    await _messageController.close();
  }
}

class WebSocketClientTransport implements McpTransport {
  final String url;
  final Map<String, String>? headers;
  final StreamController<String> _messageController = StreamController<String>.broadcast();
  WebSocket? _webSocket;
  bool _connected = false;

  WebSocketClientTransport({
    required this.url,
    this.headers,
  });

  @override
  Stream<String> get messages => _messageController.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    if (_connected) {
      throw StateError('Already connected');
    }

    _webSocket = await WebSocket.connect(
      url,
      headers: headers,
    );

    _webSocket!.listen(
      (message) {
        if (message is String) {
          _messageController.add(message);
        }
      },
      onError: (error) => _messageController.addError(error),
      onDone: () => disconnect(),
    );

    _connected = true;
  }

  @override
  void sendMessage(String message) {
    if (!_connected || _webSocket == null) {
      throw StateError('Not connected');
    }
    _webSocket!.add(message);
  }

  @override
  Future<void> disconnect() async {
    if (!_connected) return;
    
    await _webSocket?.close();
    _webSocket = null;
    _connected = false;
    await _messageController.close();
  }
}