import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:http/http.dart' as http;

import 'transport.dart';

class HttpServerTransport implements McpTransport {
  final int port;
  final String? host;
  final StreamController<String> _messageController = StreamController<String>.broadcast();
  HttpServer? _server;
  bool _connected = false;

  HttpServerTransport({
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

    final router = Router();
    
    router.post('/rpc', (Request request) async {
      final body = await request.readAsString();
      _messageController.add(body);
      
      // Wait for response from handler
      final completer = Completer<String>();
      _responseCompleters[body] = completer;
      final response = await completer.future;
      
      return Response.ok(
        response,
        headers: {'Content-Type': 'application/json'},
      );
    });

    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addHandler(router);

    _server = await shelf_io.serve(
      handler,
      host ?? 'localhost',
      port,
    );

    _connected = true;
  }

  final Map<String, Completer<String>> _responseCompleters = {};

  @override
  void sendMessage(String message) {
    if (!_connected) {
      throw StateError('Not connected');
    }
    
    // Find matching request and complete it
    for (final entry in _responseCompleters.entries) {
      entry.value.complete(message);
      _responseCompleters.remove(entry.key);
      break;
    }
  }

  @override
  Future<void> disconnect() async {
    if (!_connected) return;
    
    await _server?.close();
    _server = null;
    _connected = false;
    await _messageController.close();
  }
}

class HttpClientTransport implements McpTransport {
  final String baseUrl;
  final Map<String, String>? headers;
  final StreamController<String> _messageController = StreamController<String>.broadcast();
  final http.Client _client = http.Client();
  bool _connected = false;

  HttpClientTransport({
    required this.baseUrl,
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
    _connected = true;
  }

  @override
  void sendMessage(String message) async {
    if (!_connected) {
      throw StateError('Not connected');
    }

    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/rpc'),
        headers: {
          'Content-Type': 'application/json',
          ...?headers,
        },
        body: message,
      );

      if (response.statusCode == 200) {
        _messageController.add(response.body);
      } else {
        _messageController.addError(
          Exception('HTTP error: ${response.statusCode}'),
        );
      }
    } catch (e) {
      _messageController.addError(e);
    }
  }

  @override
  Future<void> disconnect() async {
    if (!_connected) return;
    
    _client.close();
    _connected = false;
    await _messageController.close();
  }
}