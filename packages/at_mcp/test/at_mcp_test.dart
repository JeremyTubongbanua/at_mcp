import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('AT MCP Server Tests', () {
    late Process serverProcess;
    late StreamController<String> inputController;
    late StreamController<String> outputController;
    late Stream<String> outputStream;
    late StreamSubscription outputSubscription;

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
    });

    tearDown(() async {
      await outputSubscription.cancel();
      await outputController.close();
      await inputController.close();
      serverProcess.kill();
      await serverProcess.exitCode;
    });

    test('should initialize successfully', () async {
      // Send initialize request
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

      // Wait for response
      final response = await outputStream.first;
      final responseData = jsonDecode(response);

      expect(responseData['jsonrpc'], equals('2.0'));
      expect(responseData['id'], equals(1));
      expect(responseData['result'], isNotNull);
      expect(responseData['result']['serverInfo']['name'], equals('at_mcp'));
      expect(responseData['result']['serverInfo']['version'], equals('0.1.0'));
      expect(responseData['result']['capabilities']['tools'], isNotNull);
      expect(responseData['result']['capabilities']['resources'], isNotNull);
    });

    test('should list tools after initialization', () async {
      // Initialize first
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

      // Send tools/list request
      final toolsRequest = {
        'jsonrpc': '2.0',
        'id': 2,
        'method': 'tools/list'
      };

      inputController.add(jsonEncode(toolsRequest));

      // Wait for tools response
      final response = await outputStream.first;
      final responseData = jsonDecode(response);

      expect(responseData['jsonrpc'], equals('2.0'));
      expect(responseData['id'], equals(2));
      expect(responseData['result'], isNotNull);
      expect(responseData['result']['tools'], isList);

      final tools = responseData['result']['tools'] as List;
      final toolNames = tools.map((tool) => tool['name']).toList();

      expect(toolNames, contains('virtualenv_up'));
      expect(toolNames, contains('virtualenv_down'));
      expect(toolNames, contains('pkam_load'));
      expect(toolNames, contains('check_docker_readiness'));
    });

    test('should list resources after initialization', () async {
      // Initialize first
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

      // Send resources/list request
      final resourcesRequest = {
        'jsonrpc': '2.0',
        'id': 3,
        'method': 'resources/list',
        'params': {}
      };

      inputController.add(jsonEncode(resourcesRequest));

      // Wait for resources response
      final response = await outputStream.first;
      final responseData = jsonDecode(response);

      expect(responseData['jsonrpc'], equals('2.0'));
      expect(responseData['id'], equals(3));
      expect(responseData['result'], isNotNull);
      
      expect(responseData['result']['resources'], isList);

      final resources = responseData['result']['resources'] as List;
      final resourceUris = resources.map((resource) => resource['uri']).toList();

      expect(resourceUris, contains('at://demo-data'));
      expect(resourceUris, contains('at://virtualenv'));
    });

    test('should read demo data resource', () async {
      // Initialize first
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

      // Send resources/read request
      final readRequest = {
        'jsonrpc': '2.0',
        'id': 4,
        'method': 'resources/read',
        'params': {'uri': 'at://demo-data'}
      };

      inputController.add(jsonEncode(readRequest));

      // Wait for read response
      final response = await outputStream.first;
      final responseData = jsonDecode(response);

      expect(responseData['jsonrpc'], equals('2.0'));
      expect(responseData['id'], equals(4));
      expect(responseData['result'], isNotNull);
      expect(responseData['result']['contents'], isList);

      final contents = responseData['result']['contents'] as List;
      expect(contents.isNotEmpty, isTrue);
      expect(contents.first['text'], contains('AT Protocol Demo Data Resource'));
      expect(contents.first['text'], contains('https://github.com/atsign-foundation/at_demos'));
    });

    test('should read virtualenv resource', () async {
      // Initialize first
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

      // Send resources/read request
      final readRequest = {
        'jsonrpc': '2.0',
        'id': 5,
        'method': 'resources/read',
        'params': {'uri': 'at://virtualenv'}
      };

      inputController.add(jsonEncode(readRequest));

      // Wait for read response
      final response = await outputStream.first;
      final responseData = jsonDecode(response);

      expect(responseData['jsonrpc'], equals('2.0'));
      expect(responseData['id'], equals(5));
      expect(responseData['result'], isNotNull);
      expect(responseData['result']['contents'], isList);

      final contents = responseData['result']['contents'] as List;
      expect(contents.isNotEmpty, isTrue);
      expect(contents.first['text'], contains('AT Protocol Virtual Environment Resource'));
      expect(contents.first['text'], contains('vip.ve.atsign.zone:64'));
    });

    test('should validate tool schema for virtualenv_up', () async {
      // Initialize first
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

      // Send tools/list request
      final toolsRequest = {
        'jsonrpc': '2.0',
        'id': 6,
        'method': 'tools/list'
      };

      inputController.add(jsonEncode(toolsRequest));

      // Wait for tools response
      final response = await outputStream.first;
      final responseData = jsonDecode(response);

      final tools = responseData['result']['tools'] as List;
      final virtualenvUpTool = tools.firstWhere(
        (tool) => tool['name'] == 'virtualenv_up',
      );

      expect(virtualenvUpTool['description'], contains('virtual environment'));
      expect(virtualenvUpTool['inputSchema'], isNotNull);
      expect(virtualenvUpTool['inputSchema']['type'], equals('object'));
      expect(virtualenvUpTool['inputSchema']['properties'], isNotNull);
      expect(
        virtualenvUpTool['inputSchema']['properties']['compose_file'],
        isNotNull,
      );
    });
  });
}