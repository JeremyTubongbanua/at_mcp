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

class JsonRpcError {
  final int code;
  final String message;
  final dynamic data;

  JsonRpcError({
    required this.code,
    required this.message,
    this.data,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'code': code,
      'message': message,
    };
    if (data != null) {
      json['data'] = data;
    }
    return json;
  }

  factory JsonRpcError.fromJson(Map<String, dynamic> json) {
    return JsonRpcError(
      code: json['code'],
      message: json['message'],
      data: json['data'],
    );
  }

  static JsonRpcError parseError() => JsonRpcError(
    code: -32700,
    message: 'Parse error',
  );

  static JsonRpcError invalidRequest() => JsonRpcError(
    code: -32600,
    message: 'Invalid Request',
  );

  static JsonRpcError methodNotFound() => JsonRpcError(
    code: -32601,
    message: 'Method not found',
  );

  static JsonRpcError invalidParams() => JsonRpcError(
    code: -32602,
    message: 'Invalid params',
  );

  static JsonRpcError internalError() => JsonRpcError(
    code: -32603,
    message: 'Internal error',
  );
}

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
