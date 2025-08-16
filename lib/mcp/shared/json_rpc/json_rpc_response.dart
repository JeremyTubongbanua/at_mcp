import 'dart:convert';
import 'json_rpc_error.dart';

class JsonRpcResponse {
  final String jsonrpc;
  final dynamic id;
  final dynamic result;
  final JsonRpcError? error;

  JsonRpcResponse({
    this.jsonrpc = '2.0',
    required this.id,
    this.result,
    this.error,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'jsonrpc': jsonrpc,
      'id': id,
    };
    if (error != null) {
      json['error'] = error!.toJson();
    } else {
      json['result'] = result;
    }
    return json;
  }

  factory JsonRpcResponse.fromJson(Map<String, dynamic> json) {
    return JsonRpcResponse(
      jsonrpc: json['jsonrpc'] ?? '2.0',
      id: json['id'],
      result: json['result'],
      error: json['error'] != null ? JsonRpcError.fromJson(json['error']) : null,
    );
  }

  @override
  String toString() => jsonEncode(toJson());
}