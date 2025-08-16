import 'dart:convert';

class JsonRpcNotification {
  final String jsonrpc;
  final String method;
  final Map<String, dynamic>? params;

  JsonRpcNotification({
    this.jsonrpc = '2.0',
    required this.method,
    this.params,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'jsonrpc': jsonrpc,
      'method': method,
    };
    if (params != null) {
      json['params'] = params;
    }
    return json;
  }

  factory JsonRpcNotification.fromJson(Map<String, dynamic> json) {
    return JsonRpcNotification(
      jsonrpc: json['jsonrpc'] ?? '2.0',
      method: json['method'],
      params: json['params'],
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}