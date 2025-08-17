import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:dart_mcp/server.dart';
import 'package:dart_mcp/stdio.dart';
import 'package:at_mcp/at_mcp.dart';

void main() {
  // Create the server and connect it to stdio.
  AtMCPServer(stdioChannel(input: io.stdin, output: io.stdout));
}

/// An AT Protocol MCP server with tools and resources support.
base class AtMCPServer extends MCPServer with ToolsSupport, ResourcesSupport {
  AtMCPServer(super.channel)
      : super.fromStreamChannel(
          implementation: Implementation(
            name: 'at_mcp',
            version: '0.1.0',
          ),
          instructions: 'An AT Protocol MCP server providing tools and resources for AT Protocol operations including virtual environment management and atSign authentication.',
        ) {
    // Register virtualenv tools
    registerTool(virtualenvUpTool, _virtualenvUp);
    registerTool(virtualenvDownTool, _virtualenvDown);
    registerTool(virtualenvRemoveTool, _virtualenvRemove);
    registerTool(pkamLoadTool, _pkamLoad);
    registerTool(checkDockerReadinessTool, _checkDockerReadiness);
    
    // Register AT Protocol tools
    registerTool(downloadPkamKeysTool, _downloadPkamKeys);
    registerTool(getCramKeyTool, _getCramKey);
    registerTool(onboardAtSignTool, _onboardAtSign);
    registerTool(setupDevelopmentAtSignsTool, _setupDevelopmentAtSigns);
    registerTool(getVirtualenvStatusTool, _getVirtualenvStatus);
    
    // Register REPL tools
    registerTool(atReplGetTool, _atReplGet);
    registerTool(atReplPutTool, _atReplPut);
    registerTool(atReplDeleteTool, _atReplDelete);
    registerTool(atReplScanTool, _atReplScan);
    registerTool(atReplInspectTool, _atReplInspect);
    registerTool(atReplNotificationsTool, _atReplNotifications);
    registerTool(atReplRawCommandTool, _atReplRawCommand);
    registerTool(atReplStatsTool, _atReplStats);
    
    // Add demo data resource
    addResource(
      Resource(uri: 'at://demo-data', name: 'AT Protocol Demo Data'),
      _readDemoDataResource,
    );
    
    // Add virtualenv resource
    addResource(
      Resource(uri: 'at://virtualenv', name: 'AT Protocol Virtual Environment'),
      _readVirtualenvResource,
    );
  }

  /// Tool to start the virtual environment using docker-compose
  final virtualenvUpTool = Tool(
    name: 'virtualenv_up',
    description: 'Start the AT Protocol virtual environment using Docker with direct commands',
    inputSchema: Schema.object(properties: {}),
  );

  /// Tool to stop the virtual environment
  final virtualenvDownTool = Tool(
    name: 'virtualenv_down',
    description: 'Stop the AT Protocol virtual environment',
    inputSchema: Schema.object(properties: {}),
  );

  /// Tool to remove the virtual environment container completely
  final virtualenvRemoveTool = Tool(
    name: 'virtualenv_remove',
    description: 'Remove the AT Protocol virtual environment container completely',
    inputSchema: Schema.object(properties: {}),
  );

  /// Tool to run pkamLoad in the virtual environment
  final pkamLoadTool = Tool(
    name: 'pkam_load',
    description: 'Run pkamLoad in the virtual environment to enable PKAM authentication',
    inputSchema: Schema.object(properties: {}),
  );

  /// Tool to check if the virtual environment is ready
  final checkDockerReadinessTool = Tool(
    name: 'check_docker_readiness',
    description: 'Check if the virtual environment is ready by testing atSign resolution',
    inputSchema: Schema.object(
      properties: {
        'atsign': Schema.string(
          description: 'The atSign to test (default: gary)',
        ),
      },
    ),
  );

  /// Tool to download PKAM keys for an atSign
  final downloadPkamKeysTool = Tool(
    name: 'download_pkam_keys',
    description: 'Download PKAM keys for a specific atSign from the demo data repository',
    inputSchema: Schema.object(
      properties: {
        'atsign': Schema.string(
          description: 'The atSign to download keys for (e.g., @gary, @xavier)',
        ),
        'target_path': Schema.string(
          description: 'Optional target path for the keys file',
        ),
      },
      required: ['atsign'],
    ),
  );

  /// Tool to get CRAM key for an atSign
  final getCramKeyTool = Tool(
    name: 'get_cram_key',
    description: 'Get the CRAM key for a specific atSign from demo data',
    inputSchema: Schema.object(
      properties: {
        'atsign': Schema.string(
          description: 'The atSign to get CRAM key for (e.g., @gary, @xavier)',
        ),
      },
      required: ['atsign'],
    ),
  );

  /// Tool to onboard an atSign using CRAM authentication
  final onboardAtSignTool = Tool(
    name: 'onboard_atsign',
    description: 'Onboard an atSign using CRAM authentication in the virtual environment',
    inputSchema: Schema.object(
      properties: {
        'atsign': Schema.string(
          description: 'The atSign to onboard (e.g., @gary, @xavier)',
        ),
        'cram_key': Schema.string(
          description: 'Optional CRAM key (will be auto-retrieved if not provided)',
        ),
        'keys_file_path': Schema.string(
          description: 'Optional path for the generated keys file',
        ),
      },
      required: ['atsign'],
    ),
  );

  /// Tool to setup multiple atSigns for development
  final setupDevelopmentAtSignsTool = Tool(
    name: 'setup_development_atsigns',
    description: 'Setup multiple atSigns for development by downloading keys and onboarding',
    inputSchema: Schema.object(
      properties: {
        'atsigns': Schema.string(
          description: 'Comma-separated list of atSigns to setup (defaults to @gary,@xavier,@alice,@bob)',
        ),
        'keys_directory': Schema.string(
          description: 'Directory to store keys files',
        ),
      },
    ),
  );

  /// Tool to get comprehensive virtual environment status
  final getVirtualenvStatusTool = Tool(
    name: 'get_virtualenv_status',
    description: 'Get comprehensive status of the virtual environment including Docker, container, and AT Protocol services',
    inputSchema: Schema.object(properties: {}),
  );

  // AT Server Operations Tools
  /// Tool to get a value from an atSign
  final atReplGetTool = Tool(
    name: 'at_repl_get',
    description: 'Get a value from the atServer (equivalent to at_repl /get command)',
    inputSchema: Schema.object(
      properties: {
        'atsign': Schema.string(description: 'The atSign to connect to (e.g., @gary)'),
        'atkey': Schema.string(description: 'The AtKey to retrieve'),
        'keys_file_path': Schema.string(description: 'Optional path to the atKeys file'),
      },
      required: ['atsign', 'atkey'],
    ),
  );

  /// Tool to put a value to an atSign
  final atReplPutTool = Tool(
    name: 'at_repl_put',
    description: 'Store a value to the atServer (equivalent to at_repl /put command)',
    inputSchema: Schema.object(
      properties: {
        'atsign': Schema.string(description: 'The atSign to connect to (e.g., @gary)'),
        'atkey': Schema.string(description: 'The AtKey to store'),
        'value': Schema.string(description: 'The value to store'),
        'keys_file_path': Schema.string(description: 'Optional path to the atKeys file'),
        'ttl': Schema.string(description: 'Optional time-to-live in milliseconds'),
        'is_public': Schema.string(description: 'Optional: is this a public key (true/false)'),
        'is_hidden': Schema.string(description: 'Optional: is this a hidden key (true/false)'),
      },
      required: ['atsign', 'atkey', 'value'],
    ),
  );

  /// Tool to delete a key from an atSign
  final atReplDeleteTool = Tool(
    name: 'at_repl_delete',
    description: 'Delete a key from the atServer (equivalent to at_repl /delete command)',
    inputSchema: Schema.object(
      properties: {
        'atsign': Schema.string(description: 'The atSign to connect to (e.g., @gary)'),
        'atkey': Schema.string(description: 'The AtKey to delete'),
        'keys_file_path': Schema.string(description: 'Optional path to the atKeys file'),
      },
      required: ['atsign', 'atkey'],
    ),
  );

  /// Tool to scan/list keys on an atSign
  final atReplScanTool = Tool(
    name: 'at_repl_scan',
    description: 'Scan and list keys on the atServer (equivalent to at_repl /scan command)',
    inputSchema: Schema.object(
      properties: {
        'atsign': Schema.string(description: 'The atSign to connect to (e.g., @gary)'),
        'regex': Schema.string(description: 'Optional regex pattern to filter keys'),
        'keys_file_path': Schema.string(description: 'Optional path to the atKeys file'),
        'limit': Schema.string(description: 'Optional limit on number of keys returned'),
      },
      required: ['atsign'],
    ),
  );

  /// Tool to inspect a key with detailed information
  final atReplInspectTool = Tool(
    name: 'at_repl_inspect',
    description: 'Inspect a key with detailed metadata and value (equivalent to at_repl /inspect_keys)',
    inputSchema: Schema.object(
      properties: {
        'atsign': Schema.string(description: 'The atSign to connect to (e.g., @gary)'),
        'atkey': Schema.string(description: 'The AtKey to inspect'),
        'keys_file_path': Schema.string(description: 'Optional path to the atKeys file'),
        'include_value': Schema.string(description: 'Include the key value (true/false, default: true)'),
        'include_metadata': Schema.string(description: 'Include key metadata (true/false, default: true)'),
      },
      required: ['atsign', 'atkey'],
    ),
  );

  /// Tool to get notifications for an atSign
  final atReplNotificationsTool = Tool(
    name: 'at_repl_notifications',
    description: 'Get notifications for an atSign (equivalent to at_repl /monitor command)',
    inputSchema: Schema.object(
      properties: {
        'atsign': Schema.string(description: 'The atSign to connect to (e.g., @gary)'),
        'regex': Schema.string(description: 'Optional regex pattern to filter notifications'),
        'keys_file_path': Schema.string(description: 'Optional path to the atKeys file'),
        'limit': Schema.string(description: 'Optional limit on number of notifications returned'),
      },
      required: ['atsign'],
    ),
  );

  /// Tool to execute raw AT Protocol commands
  final atReplRawCommandTool = Tool(
    name: 'at_repl_raw_command',
    description: 'Execute raw AT Protocol commands (equivalent to at_repl raw commands)',
    inputSchema: Schema.object(
      properties: {
        'atsign': Schema.string(description: 'The atSign to connect to (e.g., @gary)'),
        'command': Schema.string(description: 'The raw AT Protocol command to execute'),
        'keys_file_path': Schema.string(description: 'Optional path to the atKeys file'),
      },
      required: ['atsign', 'command'],
    ),
  );

  /// Tool to get statistics about an atSign's data
  final atReplStatsTool = Tool(
    name: 'at_repl_stats',
    description: 'Get statistics about an atSign\'s data for debugging and analysis',
    inputSchema: Schema.object(
      properties: {
        'atsign': Schema.string(description: 'The atSign to connect to (e.g., @gary)'),
        'keys_file_path': Schema.string(description: 'Optional path to the atKeys file'),
      },
      required: ['atsign'],
    ),
  );

  /// Start the virtual environment
  FutureOr<CallToolResult> _virtualenvUp(CallToolRequest request) async {
    try {
      final result = await VirtualenvManager.startVirtualenv();
      
      if (result.exitCode == 0) {
        return CallToolResult(
          content: [
            TextContent(text: 'Virtual environment started successfully using Docker.\n\nContainer: atsign_virtualenv\nImage: atsigncompany/virtualenv:vip\nPorts: 64:64, 9001:9001\nExtra hosts: vip.ve.atsign.zone -> 127.0.0.1\n\nStdout: ${result.stdout}\nStderr: ${result.stderr}'),
          ],
        );
      } else {
        return CallToolResult(
          content: [
            TextContent(text: 'Failed to start virtual environment.\nStdout: ${result.stdout}\nStderr: ${result.stderr}'),
          ],
          isError: true,
        );
      }
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error starting virtual environment: $e'),
        ],
        isError: true,
      );
    }
  }

  /// Stop the virtual environment
  FutureOr<CallToolResult> _virtualenvDown(CallToolRequest request) async {
    try {
      final result = await VirtualenvManager.stopVirtualenv();
      
      if (result.exitCode == 0) {
        return CallToolResult(
          content: [
            TextContent(text: 'Virtual environment stopped successfully.\nStdout: ${result.stdout}\nStderr: ${result.stderr}'),
          ],
        );
      } else {
        return CallToolResult(
          content: [
            TextContent(text: 'Failed to stop virtual environment.\nStdout: ${result.stdout}\nStderr: ${result.stderr}'),
          ],
          isError: true,
        );
      }
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error stopping virtual environment: $e'),
        ],
        isError: true,
      );
    }
  }

  /// Remove the virtual environment container completely
  FutureOr<CallToolResult> _virtualenvRemove(CallToolRequest request) async {
    try {
      final result = await VirtualenvManager.removeVirtualenv();
      
      if (result.exitCode == 0) {
        return CallToolResult(
          content: [
            TextContent(text: 'Virtual environment container removed successfully.\nStdout: ${result.stdout}\nStderr: ${result.stderr}'),
          ],
        );
      } else {
        return CallToolResult(
          content: [
            TextContent(text: 'Failed to remove virtual environment container.\nStdout: ${result.stdout}\nStderr: ${result.stderr}'),
          ],
          isError: true,
        );
      }
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error removing virtual environment: $e'),
        ],
        isError: true,
      );
    }
  }

  /// Run pkamLoad in the virtual environment
  FutureOr<CallToolResult> _pkamLoad(CallToolRequest request) async {
    try {
      final result = await io.Process.run('docker', [
        'exec', 'atsign_virtualenv', 'supervisorctl', 'start', 'pkamLoad'
      ]);
      
      if (result.exitCode == 0) {
        return CallToolResult(
          content: [
            TextContent(text: 'pkamLoad started successfully.\nStdout: ${result.stdout}\nStderr: ${result.stderr}'),
          ],
        );
      } else {
        return CallToolResult(
          content: [
            TextContent(text: 'Failed to start pkamLoad.\nStdout: ${result.stdout}\nStderr: ${result.stderr}'),
          ],
          isError: true,
        );
      }
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error running pkamLoad: $e'),
        ],
        isError: true,
      );
    }
  }

  /// Check if the virtual environment is ready
  FutureOr<CallToolResult> _checkDockerReadiness(CallToolRequest request) async {
    try {
      final atsign = request.arguments?['atsign'] as String? ?? 'gary';
      
      // Create a socket connection to test the root server
      final socket = await io.Socket.connect('vip.ve.atsign.zone', 64);
      
      // Send the atSign query
      socket.write('$atsign\n');
      
      // Read the response
      final completer = Completer<String>();
      final buffer = StringBuffer();
      
      socket.listen(
        (data) {
          buffer.write(utf8.decode(data));
          final response = buffer.toString();
          if (response.contains('\n') || response.contains('vip.ve.atsign.zone:')) {
            completer.complete(response);
          }
        },
        onError: (error) => completer.completeError(error),
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(buffer.toString());
          }
        },
      );
      
      final response = await completer.future.timeout(Duration(seconds: 5));
      socket.destroy();
      
      if (response.contains('vip.ve.atsign.zone:')) {
        return CallToolResult(
          content: [
            TextContent(text: 'Virtual environment is ready. Response: ${response.trim()}'),
          ],
        );
      } else {
        return CallToolResult(
          content: [
            TextContent(text: 'Virtual environment may not be ready. Unexpected response: ${response.trim()}'),
          ],
          isError: true,
        );
      }
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(text: 'Virtual environment not ready: $e'),
        ],
        isError: true,
      );
    }
  }

  /// Read demo data resource
  FutureOr<ReadResourceResult> _readDemoDataResource(ReadResourceRequest request) async {
    final demoDataInfo = '''
AT Protocol Demo Data Resource

This resource provides access to demo data, PKAM keys, and CRAM keys from the at_demos repository.

Repository: https://github.com/atsign-foundation/at_demos
Demo Data Package: packages/at_demo_data

PKAM Keys Location:
- packages/at_demo_data/lib/assets/atkeys/@{atsign}_key.atKeys

CRAM Keys Location:
- packages/at_demo_data/lib/src/at_demo_keys.dart

Example CRAM Keys:
- Gary: e0d06915c3f81561fb5f8929caae64a7231db34fdeaff939aacac3cb736be8328c2843b518a2fc7a58fcec8c0aa98c735c0ce5f8ce880e97cd61cf1f2751efc5
- Xavier: Similar pattern, check the at_demo_keys.dart file

Usage:
1. Clone the at_demos repository
2. Navigate to packages/at_demo_data
3. Use CRAM keys for initial onboarding
4. Use PKAM keys for subsequent authentication
''';

    return ReadResourceResult(
      contents: [
        TextResourceContents(
          text: demoDataInfo,
          uri: request.uri,
        )
      ],
    );
  }

  /// Read virtualenv resource
  FutureOr<ReadResourceResult> _readVirtualenvResource(ReadResourceRequest request) async {
    final virtualenvInfo = '''
AT Protocol Virtual Environment Resource

The virtual environment is a Docker container that provides:
- Root Server (like DNS for atSigns) at vip.ve.atsign.zone:64
- 40 atServers with their own atSigns at ports 25000-25039
- Supervisord process for managing services including pkamLoad

Docker Configuration (Direct Commands):
- Container: atsign_virtualenv
- Image: atsigncompany/virtualenv:vip
- Port Mappings: 64:64 (root server), 9001:9001 (supervisor web)
- Extra Hosts: vip.ve.atsign.zone -> 127.0.0.1
- Full Command: docker run -d --name atsign_virtualenv --add-host vip.ve.atsign.zone:127.0.0.1 -p 64:64 -p 9001:9001 atsigncompany/virtualenv:vip

Setup Steps:
1. Add "127.0.0.1 vip.ve.atsign.zone" to /etc/hosts (done automatically)
2. Run virtualenv_up tool (uses direct Docker commands)
3. Run pkamLoad to enable PKAM authentication
4. Onboard atSigns using CRAM keys from demo data
5. Use PKAM keys for subsequent authentication

Available atSigns in Virtual Environment:
@alice, @bob, @charlie, @david, @eve, @gary, @xavier, and many more...
''';

    return ReadResourceResult(
      contents: [
        TextResourceContents(
          text: virtualenvInfo,
          uri: request.uri,
        )
      ],
    );
  }

  /// Download PKAM keys for an atSign
  FutureOr<CallToolResult> _downloadPkamKeys(CallToolRequest request) async {
    try {
      final atSign = request.arguments?['atsign'] as String;
      final targetPath = request.arguments?['target_path'] as String?;
      
      await AtKeyManager.downloadPkamKeys(atSign, targetPath: targetPath);
      
      return CallToolResult(
        content: [
          TextContent(text: 'Successfully downloaded PKAM keys for $atSign'),
        ],
      );
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error downloading PKAM keys: $e'),
        ],
        isError: true,
      );
    }
  }

  /// Get CRAM key for an atSign
  FutureOr<CallToolResult> _getCramKey(CallToolRequest request) async {
    try {
      final atSign = request.arguments?['atsign'] as String;
      final cramKey = AtKeyManager.getCramKey(atSign);
      
      if (cramKey != null) {
        return CallToolResult(
          content: [
            TextContent(text: 'CRAM key for $atSign: $cramKey'),
          ],
        );
      } else {
        return CallToolResult(
          content: [
            TextContent(text: 'No CRAM key available for $atSign. Available atSigns: ${AtKeyManager.getAvailableAtSigns().join(', ')}'),
          ],
          isError: true,
        );
      }
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error getting CRAM key: $e'),
        ],
        isError: true,
      );
    }
  }

  /// Onboard an atSign using CRAM authentication
  FutureOr<CallToolResult> _onboardAtSign(CallToolRequest request) async {
    try {
      final atSign = request.arguments?['atsign'] as String;
      final cramKey = request.arguments?['cram_key'] as String?;
      final keysFilePath = request.arguments?['keys_file_path'] as String?;
      
      await AtOnboardingService.onboardWithCram(
        atSign: atSign,
        cramKey: cramKey,
        keysFilePath: keysFilePath,
      );
      
      return CallToolResult(
        content: [
          TextContent(text: 'Successfully onboarded $atSign using CRAM authentication'),
        ],
      );
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error onboarding atSign: $e'),
        ],
        isError: true,
      );
    }
  }

  /// Setup multiple atSigns for development
  FutureOr<CallToolResult> _setupDevelopmentAtSigns(CallToolRequest request) async {
    try {
      final atSignsStr = request.arguments?['atsigns'] as String?;
      final keysDirectory = request.arguments?['keys_directory'] as String?;
      
      List<String> atSigns;
      if (atSignsStr != null) {
        atSigns = atSignsStr.split(',').map((s) => s.trim()).toList();
      } else {
        atSigns = ['@gary', '@xavier', '@alice', '@bob'];
      }
      
      final results = await AtOnboardingService.setupDevelopmentAtSigns(
        atSigns: atSigns,
        keysDirectory: keysDirectory,
      );
      
      final summary = StringBuffer();
      summary.writeln('Development atSigns setup results:');
      for (final entry in results.entries) {
        final status = entry.value ? '✓' : '✗';
        summary.writeln('$status ${entry.key}: ${entry.value ? 'Success' : 'Failed'}');
      }
      
      final hasFailures = results.values.any((success) => !success);
      
      return CallToolResult(
        content: [
          TextContent(text: summary.toString()),
        ],
        isError: hasFailures,
      );
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error setting up development atSigns: $e'),
        ],
        isError: true,
      );
    }
  }

  /// Get comprehensive virtual environment status
  FutureOr<CallToolResult> _getVirtualenvStatus(CallToolRequest request) async {
    try {
      final status = await VirtualenvManager.getVirtualenvStatus();
      
      final summary = StringBuffer();
      summary.writeln('Virtual Environment Status:');
      summary.writeln('Docker Running: ${status['dockerRunning']}');
      summary.writeln('Container Running: ${status['containerRunning']}');
      
      if (status['containerRunning']) {
        summary.writeln('Root Server Ready: ${status['rootServerReady']}');
        if (status['atSignResolution'] != null) {
          summary.writeln('AtSign Resolution Test: ${status['atSignResolution']}');
        }
      }
      
      return CallToolResult(
        content: [
          TextContent(text: summary.toString()),
        ],
      );
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error getting virtual environment status: $e'),
        ],
        isError: true,
      );
    }
  }

  // AT Server Operations Tool Handlers
  
  /// Handle REPL get command
  FutureOr<CallToolResult> _atReplGet(CallToolRequest request) async {
    final atSign = request.arguments?['atsign'] as String;
    final atKey = request.arguments?['atkey'] as String;
    final keysFilePath = request.arguments?['keys_file_path'] as String?;
    
    return AtServerOperationsService.getValue(
      atSign: atSign,
      atKey: atKey,
      keysFilePath: keysFilePath,
    );
  }

  /// Handle REPL put command
  FutureOr<CallToolResult> _atReplPut(CallToolRequest request) async {
    final atSign = request.arguments?['atsign'] as String;
    final atKey = request.arguments?['atkey'] as String;
    final value = request.arguments?['value'] as String;
    final keysFilePath = request.arguments?['keys_file_path'] as String?;
    final ttlStr = request.arguments?['ttl'] as String?;
    final isPublicStr = request.arguments?['is_public'] as String?;
    final isHiddenStr = request.arguments?['is_hidden'] as String?;
    
    // Parse optional parameters
    int? ttl;
    if (ttlStr != null) {
      ttl = int.tryParse(ttlStr);
    }
    
    bool? isPublic;
    if (isPublicStr != null) {
      isPublic = isPublicStr.toLowerCase() == 'true';
    }
    
    bool? isHidden;
    if (isHiddenStr != null) {
      isHidden = isHiddenStr.toLowerCase() == 'true';
    }
    
    return AtServerOperationsService.putValue(
      atSign: atSign,
      atKey: atKey,
      value: value,
      keysFilePath: keysFilePath,
      ttl: ttl,
      isPublic: isPublic,
      isHidden: isHidden,
    );
  }

  /// Handle REPL delete command
  FutureOr<CallToolResult> _atReplDelete(CallToolRequest request) async {
    final atSign = request.arguments?['atsign'] as String;
    final atKey = request.arguments?['atkey'] as String;
    final keysFilePath = request.arguments?['keys_file_path'] as String?;
    
    return AtServerOperationsService.deleteKey(
      atSign: atSign,
      atKey: atKey,
      keysFilePath: keysFilePath,
    );
  }

  /// Handle REPL scan command
  FutureOr<CallToolResult> _atReplScan(CallToolRequest request) async {
    final atSign = request.arguments?['atsign'] as String;
    final regex = request.arguments?['regex'] as String?;
    final keysFilePath = request.arguments?['keys_file_path'] as String?;
    final limitStr = request.arguments?['limit'] as String?;
    
    int? limit;
    if (limitStr != null) {
      limit = int.tryParse(limitStr);
    }
    
    return AtServerOperationsService.scanKeys(
      atSign: atSign,
      regex: regex,
      keysFilePath: keysFilePath,
      limit: limit,
    );
  }

  /// Handle REPL inspect command
  FutureOr<CallToolResult> _atReplInspect(CallToolRequest request) async {
    final atSign = request.arguments?['atsign'] as String;
    final atKey = request.arguments?['atkey'] as String;
    final keysFilePath = request.arguments?['keys_file_path'] as String?;
    final includeValueStr = request.arguments?['include_value'] as String?;
    final includeMetadataStr = request.arguments?['include_metadata'] as String?;
    
    bool includeValue = true;
    if (includeValueStr != null) {
      includeValue = includeValueStr.toLowerCase() == 'true';
    }
    
    bool includeMetadata = true;
    if (includeMetadataStr != null) {
      includeMetadata = includeMetadataStr.toLowerCase() == 'true';
    }
    
    return AtServerOperationsService.inspectKey(
      atSign: atSign,
      atKey: atKey,
      keysFilePath: keysFilePath,
      includeValue: includeValue,
      includeMetadata: includeMetadata,
    );
  }

  /// Handle REPL notifications command
  FutureOr<CallToolResult> _atReplNotifications(CallToolRequest request) async {
    final atSign = request.arguments?['atsign'] as String;
    final regex = request.arguments?['regex'] as String?;
    final keysFilePath = request.arguments?['keys_file_path'] as String?;
    final limitStr = request.arguments?['limit'] as String?;
    
    int? limit;
    if (limitStr != null) {
      limit = int.tryParse(limitStr);
    }
    
    return AtServerOperationsService.getNotifications(
      atSign: atSign,
      regex: regex,
      keysFilePath: keysFilePath,
      limit: limit,
    );
  }

  /// Handle REPL raw command
  FutureOr<CallToolResult> _atReplRawCommand(CallToolRequest request) async {
    final atSign = request.arguments?['atsign'] as String;
    final command = request.arguments?['command'] as String;
    final keysFilePath = request.arguments?['keys_file_path'] as String?;
    
    return AtServerOperationsService.executeRawCommand(
      atSign: atSign,
      command: command,
      keysFilePath: keysFilePath,
    );
  }

  /// Handle REPL stats command
  FutureOr<CallToolResult> _atReplStats(CallToolRequest request) async {
    final atSign = request.arguments?['atsign'] as String;
    final keysFilePath = request.arguments?['keys_file_path'] as String?;
    
    return AtServerOperationsService.getStats(
      atSign: atSign,
      keysFilePath: keysFilePath,
    );
  }
}
