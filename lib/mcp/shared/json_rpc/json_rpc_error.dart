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