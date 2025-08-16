import 'dart:async';

abstract class McpTransport {
  Stream<String> get messages;
  
  void sendMessage(String message);
  
  Future<void> connect();
  
  Future<void> disconnect();
  
  bool get isConnected;
}