import 'dart:convert';

class JsonRpcRequest {
  final String jsonrpc;
  final dynamic id;
  final String method;
  final Map<String, dynamic>? params;

  JsonRpcRequest({
    this.jsonrpc = '2.0',
    required this.id,
    required this.method,
    this.params,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'jsonrpc': jsonrpc,
      'id': id,
      'method': method,
    };
    if (params != null) {
      json['params'] = params;
    }
    return json;
  }

  factory JsonRpcRequest.fromJson(Map<String, dynamic> json) {
    return JsonRpcRequest(
      jsonrpc: json['jsonrpc'] ?? '2.0',
      id: json['id'],
      method: json['method'],
      params: json['params'],
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}