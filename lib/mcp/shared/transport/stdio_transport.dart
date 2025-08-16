import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'transport.dart';

class StdioTransport implements McpTransport {
  final StreamController<String> _messageController = StreamController<String>.broadcast();
  StreamSubscription<String>? _subscription;
  bool _connected = false;

  @override
  Stream<String> get messages => _messageController.stream;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> connect() async {
    if (_connected) {
      throw StateError('Already connected');
    }

    _subscription = stdin
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .listen(
          (line) => _messageController.add(line),
          onError: (error) => _messageController.addError(error),
          onDone: () => disconnect(),
        );

    _connected = true;
  }

  @override
  void sendMessage(String message) {
    if (!_connected) {
      throw StateError('Not connected');
    }
    stdout.writeln(message);
  }

  @override
  Future<void> disconnect() async {
    if (!_connected) return;
    
    await _subscription?.cancel();
    _subscription = null;
    _connected = false;
    await _messageController.close();
  }
}