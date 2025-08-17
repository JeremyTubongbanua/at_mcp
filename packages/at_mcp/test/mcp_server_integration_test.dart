import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('MCP Server Integration Tests', () {
    late Process serverProcess;
    late StreamController<String> inputController;
    late StreamController<String> outputController;
    late Stream<String> outputStream;
    late StreamSubscription outputSubscription;

    Future<void> _initializeServer() async {
      final initRequest = {
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': {
          'protocolVersion': '2024-11-05',
          'capabilities': {},
          'clientInfo': {'name': 'test', 'version': '1.0.0'}
        }
      };

      inputController.add(jsonEncode(initRequest));
      await outputStream.first; // Wait for init response

      // Send initialized notification
      final initializedNotification = {
        'jsonrpc': '2.0',
        'method': 'notifications/initialized'
      };

      inputController.add(jsonEncode(initializedNotification));
    }

    setUp(() async {
      // Start the MCP server process
      serverProcess = await Process.start(
        'dart',
        ['run', 'bin/at_mcp.dart'],
        workingDirectory: Directory.current.path,
      );

      // Create input controller for sending JSON-RPC messages
      inputController = StreamController<String>();
      inputController.stream.listen((message) {
        serverProcess.stdin.writeln(message);
      });

      // Create output controller and stream
      outputController = StreamController<String>.broadcast();
      outputStream = outputController.stream;

      // Listen to server output and forward to our controller
      outputSubscription = serverProcess.stdout
          .transform(utf8.decoder)
          .transform(LineSplitter())
          .listen((line) {
        if (line.trim().isNotEmpty) {
          outputController.add(line);
        }
      });

      // Initialize the server
      await _initializeServer();
    });

    tearDown(() async {
      await outputSubscription.cancel();
      await outputController.close();
      await inputController.close();
      serverProcess.kill();
      await serverProcess.exitCode;
    });

    group('AT Server Operations Tools', () {
      test('should list all REPL tools', () async {
        final toolsRequest = {
          'jsonrpc': '2.0',
          'id': 100,
          'method': 'tools/list'
        };

        inputController.add(jsonEncode(toolsRequest));

        final response = await outputStream.first;
        final responseData = jsonDecode(response);

        expect(responseData['result']['tools'], isList);

        final tools = responseData['result']['tools'] as List;
        final toolNames = tools.map((tool) => tool['name']).toList();

        // Check that all AT server operation tools are present
        expect(toolNames, contains('at_repl_get'));
        expect(toolNames, contains('at_repl_put'));
        expect(toolNames, contains('at_repl_delete'));
        expect(toolNames, contains('at_repl_scan'));
        expect(toolNames, contains('at_repl_inspect'));
        expect(toolNames, contains('at_repl_notifications'));
        expect(toolNames, contains('at_repl_raw_command'));
        expect(toolNames, contains('at_repl_stats'));
      });

      test('should validate at_repl_get tool schema', () async {
        final toolsRequest = {
          'jsonrpc': '2.0',
          'id': 101,
          'method': 'tools/list'
        };

        inputController.add(jsonEncode(toolsRequest));

        final response = await outputStream.first;
        final responseData = jsonDecode(response);

        final tools = responseData['result']['tools'] as List;
        final getReplTool = tools.firstWhere(
          (tool) => tool['name'] == 'at_repl_get',
        );

        expect(getReplTool['description'], contains('Get a value from the atServer'));
        expect(getReplTool['inputSchema']['type'], equals('object'));
        expect(getReplTool['inputSchema']['properties']['atsign'], isNotNull);
        expect(getReplTool['inputSchema']['properties']['atkey'], isNotNull);
        expect(getReplTool['inputSchema']['properties']['keys_file_path'], isNotNull);
        expect(getReplTool['inputSchema']['required'], contains('atsign'));
        expect(getReplTool['inputSchema']['required'], contains('atkey'));
      });

      test('should execute at_repl_get with error for invalid atSign', () async {
        final callRequest = {
          'jsonrpc': '2.0',
          'id': 102,
          'method': 'tools/call',
          'params': {
            'name': 'at_repl_get',
            'arguments': {
              'atsign': 'invalid_atsign',
              'atkey': 'test.key'
            }
          }
        };

        inputController.add(jsonEncode(callRequest));

        final response = await outputStream.first;
        final responseData = jsonDecode(response);

        expect(responseData['id'], equals(102));
        expect(responseData['result']['isError'], isTrue);
        expect(responseData['result']['content'][0]['text'], contains('Error getting value'));
      });

      test('should execute at_repl_put with error for invalid atSign', () async {
        final callRequest = {
          'jsonrpc': '2.0',
          'id': 103,
          'method': 'tools/call',
          'params': {
            'name': 'at_repl_put',
            'arguments': {
              'atsign': 'invalid_atsign',
              'atkey': 'test.key',
              'value': 'test_value'
            }
          }
        };

        inputController.add(jsonEncode(callRequest));

        final response = await outputStream.first;
        final responseData = jsonDecode(response);

        expect(responseData['result']['isError'], isTrue);
        expect(responseData['result']['content'][0]['text'], contains('Error storing value'));
      });

      test('should execute at_repl_delete with error for invalid atSign', () async {
        final callRequest = {
          'jsonrpc': '2.0',
          'id': 104,
          'method': 'tools/call',
          'params': {
            'name': 'at_repl_delete',
            'arguments': {
              'atsign': 'invalid_atsign',
              'atkey': 'test.key'
            }
          }
        };

        inputController.add(jsonEncode(callRequest));

        final response = await outputStream.first;
        final responseData = jsonDecode(response);

        expect(responseData['result']['isError'], isTrue);
        expect(responseData['result']['content'][0]['text'], contains('Error deleting'));
      });

      test('should execute at_repl_scan with error for invalid atSign', () async {
        final callRequest = {
          'jsonrpc': '2.0',
          'id': 105,
          'method': 'tools/call',
          'params': {
            'name': 'at_repl_scan',
            'arguments': {
              'atsign': 'invalid_atsign'
            }
          }
        };

        inputController.add(jsonEncode(callRequest));

        final response = await outputStream.first;
        final responseData = jsonDecode(response);

        expect(responseData['result']['isError'], isTrue);
        expect(responseData['result']['content'][0]['text'], contains('Error scanning keys'));
      });

      test('should execute at_repl_inspect with error for invalid atSign', () async {
        final callRequest = {
          'jsonrpc': '2.0',
          'id': 106,
          'method': 'tools/call',
          'params': {
            'name': 'at_repl_inspect',
            'arguments': {
              'atsign': 'invalid_atsign',
              'atkey': 'test.key'
            }
          }
        };

        inputController.add(jsonEncode(callRequest));

        final response = await outputStream.first;
        final responseData = jsonDecode(response);

        expect(responseData['result']['isError'], isTrue);
        expect(responseData['result']['content'][0]['text'], contains('Error inspecting key'));
      });

      test('should execute at_repl_notifications with placeholder response', () async {
        final callRequest = {
          'jsonrpc': '2.0',
          'id': 107,
          'method': 'tools/call',
          'params': {
            'name': 'at_repl_notifications',
            'arguments': {
              'atsign': '@test'
            }
          }
        };

        inputController.add(jsonEncode(callRequest));

        final response = await outputStream.first;
        final responseData = jsonDecode(response);

        expect(responseData['result']['isError'], isFalse);
        expect(responseData['result']['content'][0]['text'], contains('Notification monitoring'));
        expect(responseData['result']['content'][0]['text'], contains('would be available'));
      });

      test('should execute at_repl_raw_command with error for invalid atSign', () async {
        final callRequest = {
          'jsonrpc': '2.0',
          'id': 108,
          'method': 'tools/call',
          'params': {
            'name': 'at_repl_raw_command',
            'arguments': {
              'atsign': 'invalid_atsign',
              'command': 'scan'
            }
          }
        };

        inputController.add(jsonEncode(callRequest));

        final response = await outputStream.first;
        final responseData = jsonDecode(response);

        expect(responseData['result']['isError'], isTrue);
        expect(responseData['result']['content'][0]['text'], contains('Error executing command'));
      });

      test('should execute at_repl_stats with error for invalid atSign', () async {
        final callRequest = {
          'jsonrpc': '2.0',
          'id': 109,
          'method': 'tools/call',
          'params': {
            'name': 'at_repl_stats',
            'arguments': {
              'atsign': 'invalid_atsign'
            }
          }
        };

        inputController.add(jsonEncode(callRequest));

        final response = await outputStream.first;
        final responseData = jsonDecode(response);

        expect(responseData['result']['isError'], isTrue);
        expect(responseData['result']['content'][0]['text'], contains('Error getting stats'));
      });
    });

    group('Virtualenv Tools', () {
      test('should list virtualenv tools', () async {
        final toolsRequest = {
          'jsonrpc': '2.0',
          'id': 200,
          'method': 'tools/list'
        };

        inputController.add(jsonEncode(toolsRequest));

        final response = await outputStream.first;
        final responseData = jsonDecode(response);

        final tools = responseData['result']['tools'] as List;
        final toolNames = tools.map((tool) => tool['name']).toList();

        expect(toolNames, contains('virtualenv_up'));
        expect(toolNames, contains('virtualenv_down'));
        expect(toolNames, contains('pkam_load'));
        expect(toolNames, contains('check_docker_readiness'));
        expect(toolNames, contains('get_virtualenv_status'));
      });

      test('should execute get_virtualenv_status', () async {
        final callRequest = {
          'jsonrpc': '2.0',
          'id': 201,
          'method': 'tools/call',
          'params': {
            'name': 'get_virtualenv_status',
            'arguments': {}
          }
        };

        inputController.add(jsonEncode(callRequest));

        final response = await outputStream.first;
        final responseData = jsonDecode(response);

        expect(responseData['result']['isError'], isFalse);
        expect(responseData['result']['content'][0]['text'], contains('Virtual Environment Status'));
        expect(responseData['result']['content'][0]['text'], contains('Docker Running'));
        expect(responseData['result']['content'][0]['text'], contains('Container Running'));
      });
    });

    group('AT Protocol Tools', () {
      test('should list AT Protocol tools', () async {
        final toolsRequest = {
          'jsonrpc': '2.0',
          'id': 300,
          'method': 'tools/list'
        };

        inputController.add(jsonEncode(toolsRequest));

        final response = await outputStream.first;
        final responseData = jsonDecode(response);

        final tools = responseData['result']['tools'] as List;
        final toolNames = tools.map((tool) => tool['name']).toList();

        expect(toolNames, contains('download_pkam_keys'));
        expect(toolNames, contains('get_cram_key'));
        expect(toolNames, contains('onboard_atsign'));
        expect(toolNames, contains('setup_development_atsigns'));
      });

      test('should execute get_cram_key for valid atSign', () async {
        final callRequest = {
          'jsonrpc': '2.0',
          'id': 301,
          'method': 'tools/call',
          'params': {
            'name': 'get_cram_key',
            'arguments': {
              'atsign': '@gary'
            }
          }
        };

        inputController.add(jsonEncode(callRequest));

        final response = await outputStream.first;
        final responseData = jsonDecode(response);

        expect(responseData['result']['isError'], isFalse);
        expect(responseData['result']['content'][0]['text'], contains('CRAM key for @gary'));
      });

      test('should execute get_cram_key for invalid atSign', () async {
        final callRequest = {
          'jsonrpc': '2.0',
          'id': 302,
          'method': 'tools/call',
          'params': {
            'name': 'get_cram_key',
            'arguments': {
              'atsign': '@unknown'
            }
          }
        };

        inputController.add(jsonEncode(callRequest));

        final response = await outputStream.first;
        final responseData = jsonDecode(response);

        expect(responseData['result']['isError'], isTrue);
        expect(responseData['result']['content'][0]['text'], contains('No CRAM key available'));
      });
    });

    group('Parameter Validation', () {
      test('should handle at_repl_put with optional parameters', () async {
        final callRequest = {
          'jsonrpc': '2.0',
          'id': 400,
          'method': 'tools/call',
          'params': {
            'name': 'at_repl_put',
            'arguments': {
              'atsign': 'invalid_atsign',
              'atkey': 'test.key',
              'value': 'test_value',
              'ttl': '3600000',
              'is_public': 'true',
              'is_hidden': 'false'
            }
          }
        };

        inputController.add(jsonEncode(callRequest));

        final response = await outputStream.first;
        final responseData = jsonDecode(response);

        expect(responseData['result']['isError'], isTrue);
        expect(responseData['result']['content'][0]['text'], contains('Error storing value'));
      });

      test('should handle at_repl_scan with regex and limit', () async {
        final callRequest = {
          'jsonrpc': '2.0',
          'id': 401,
          'method': 'tools/call',
          'params': {
            'name': 'at_repl_scan',
            'arguments': {
              'atsign': 'invalid_atsign',
              'regex': '.*\\.publickey',
              'limit': '10'
            }
          }
        };

        inputController.add(jsonEncode(callRequest));

        final response = await outputStream.first;
        final responseData = jsonDecode(response);

        expect(responseData['result']['isError'], isTrue);
        expect(responseData['result']['content'][0]['text'], contains('Error scanning keys'));
      });

      test('should handle at_repl_inspect with include flags', () async {
        final callRequest = {
          'jsonrpc': '2.0',
          'id': 402,
          'method': 'tools/call',
          'params': {
            'name': 'at_repl_inspect',
            'arguments': {
              'atsign': 'invalid_atsign',
              'atkey': 'test.key',
              'include_value': 'false',
              'include_metadata': 'true'
            }
          }
        };

        inputController.add(jsonEncode(callRequest));

        final response = await outputStream.first;
        final responseData = jsonDecode(response);

        expect(responseData['result']['isError'], isTrue);
        expect(responseData['result']['content'][0]['text'], contains('Error inspecting key'));
      });

      test('should handle at_repl_notifications with filters', () async {
        final callRequest = {
          'jsonrpc': '2.0',
          'id': 403,
          'method': 'tools/call',
          'params': {
            'name': 'at_repl_notifications',
            'arguments': {
              'atsign': '@test',
              'regex': '.*\\.notification',
              'limit': '5'
            }
          }
        };

        inputController.add(jsonEncode(callRequest));

        final response = await outputStream.first;
        final responseData = jsonDecode(response);

        expect(responseData['result']['isError'], isFalse);
        expect(responseData['result']['content'][0]['text'], contains('.*\\.notification'));
        expect(responseData['result']['content'][0]['text'], contains('5'));
      });
    });

    group('Error Handling', () {
      test('should handle missing required parameters', () async {
        final callRequest = {
          'jsonrpc': '2.0',
          'id': 500,
          'method': 'tools/call',
          'params': {
            'name': 'at_repl_get',
            'arguments': {
              'atsign': '@test'
              // Missing required 'atkey' parameter
            }
          }
        };

        inputController.add(jsonEncode(callRequest));

        final response = await outputStream.first;
        final responseData = jsonDecode(response);

        expect(responseData.containsKey('error'), isTrue);
      });

      test('should handle unknown tool name', () async {
        final callRequest = {
          'jsonrpc': '2.0',
          'id': 501,
          'method': 'tools/call',
          'params': {
            'name': 'unknown_tool',
            'arguments': {}
          }
        };

        inputController.add(jsonEncode(callRequest));

        final response = await outputStream.first;
        final responseData = jsonDecode(response);

        expect(responseData.containsKey('error'), isTrue);
      });

      test('should handle malformed requests gracefully', () async {
        final malformedRequest = {
          'jsonrpc': '2.0',
          'id': 502,
          'method': 'tools/call'
          // Missing 'params'
        };

        inputController.add(jsonEncode(malformedRequest));

        final response = await outputStream.first;
        final responseData = jsonDecode(response);

        expect(responseData.containsKey('error'), isTrue);
      });
    });
  });
}