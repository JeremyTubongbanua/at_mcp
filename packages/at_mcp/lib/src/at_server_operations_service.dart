import 'dart:async';
import 'dart:io' as io;

import 'package:at_client/at_client.dart';
import 'package:dart_mcp/server.dart';

/// Service for providing AT Protocol server operations via MCP tools
class AtServerOperationsService {
  static final Map<String, AtClient> _clients = {};
  
  /// Get or create an AtClient for the given atSign
  static Future<AtClient> _getClient(String atSign, {String? keysFilePath}) async {
    if (_clients.containsKey(atSign)) {
      return _clients[atSign]!;
    }
    
    final homeDir = io.Platform.environment['HOME'] ?? '';
    final atClientPreferences = AtClientPreference()
      ..isLocalStoreRequired = true
      ..commitLogPath = '$homeDir/.atsign/storage/$atSign/commitLog'
      ..hiveStoragePath = '$homeDir/.atsign/storage/$atSign/hive';
    
    // Use provided keys file path or default location
    if (keysFilePath != null) {
      // Use the provided path - for future implementation
    } else {
      // Use default path - for future implementation  
    }
    
    final atClientManager = AtClientManager.getInstance();
    await atClientManager.setCurrentAtSign(
      atSign,
      'com.example.at_mcp',
      atClientPreferences,
    );
    
    final atClient = atClientManager.atClient;
    _clients[atSign] = atClient;
    return atClient;
  }
  
  /// Get a value from the atServer
  static Future<CallToolResult> getValue({
    required String atSign,
    required String atKey,
    String? keysFilePath,
  }) async {
    try {
      final client = await _getClient(atSign, keysFilePath: keysFilePath);
      final key = AtKey.fromString(atKey);
      final atValue = await client.get(key);
      
      if (atValue.value != null) {
        return CallToolResult(
          content: [
            TextContent(text: 'Value for $atKey: ${atValue.value}'),
          ],
        );
      } else {
        return CallToolResult(
          content: [
            TextContent(text: 'Key $atKey not found'),
          ],
          isError: true,
        );
      }
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error getting value for $atKey: $e'),
        ],
        isError: true,
      );
    }
  }
  
  /// Put a value to the atServer
  static Future<CallToolResult> putValue({
    required String atSign,
    required String atKey,
    required String value,
    String? keysFilePath,
    int? ttl,
    bool? isPublic,
    bool? isHidden,
  }) async {
    try {
      final client = await _getClient(atSign, keysFilePath: keysFilePath);
      final key = AtKey.fromString(atKey);
      
      // Apply optional metadata
      if (ttl != null) key.metadata.ttl = ttl;
      if (isPublic != null) key.metadata.isPublic = isPublic;
      if (isHidden != null) key.metadata.isHidden = isHidden;
      
      final success = await client.put(key, value);
      
      if (success) {
        return CallToolResult(
          content: [
            TextContent(text: 'Successfully stored $atKey = $value'),
          ],
        );
      } else {
        return CallToolResult(
          content: [
            TextContent(text: 'Failed to store value for $atKey'),
          ],
          isError: true,
        );
      }
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error storing value for $atKey: $e'),
        ],
        isError: true,
      );
    }
  }
  
  /// Delete a key from the atServer
  static Future<CallToolResult> deleteKey({
    required String atSign,
    required String atKey,
    String? keysFilePath,
  }) async {
    try {
      final client = await _getClient(atSign, keysFilePath: keysFilePath);
      final key = AtKey.fromString(atKey);
      final success = await client.delete(key);
      
      if (success) {
        return CallToolResult(
          content: [
            TextContent(text: 'Successfully deleted $atKey'),
          ],
        );
      } else {
        return CallToolResult(
          content: [
            TextContent(text: 'Failed to delete $atKey'),
          ],
          isError: true,
        );
      }
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error deleting $atKey: $e'),
        ],
        isError: true,
      );
    }
  }
  
  /// Scan/list keys on the atServer
  static Future<CallToolResult> scanKeys({
    required String atSign,
    String? regex,
    String? keysFilePath,
    int? limit,
  }) async {
    try {
      final client = await _getClient(atSign, keysFilePath: keysFilePath);
      List<AtKey> keys;
      
      if (regex != null && regex.isNotEmpty) {
        keys = await client.getAtKeys(regex: regex);
      } else {
        keys = await client.getAtKeys();
      }
      
      // Apply limit if specified
      if (limit != null && limit > 0) {
        keys = keys.take(limit).toList();
      }
      
      if (keys.isEmpty) {
        return CallToolResult(
          content: [
            TextContent(text: 'No keys found${regex != null ? ' matching regex: $regex' : ''}'),
          ],
        );
      }
      
      String result = 'Found ${keys.length} key(s)${regex != null ? ' matching regex: $regex' : ''}:\n';
      
      for (int i = 0; i < keys.length; i++) {
        result += '${i + 1}. ${keys[i].toString()}\n';
      }
      
      return CallToolResult(
        content: [
          TextContent(text: result),
        ],
      );
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error scanning keys: $e'),
        ],
        isError: true,
      );
    }
  }
  
  /// Get detailed information about a specific key
  static Future<CallToolResult> inspectKey({
    required String atSign,
    required String atKey,
    String? keysFilePath,
    bool includeValue = true,
    bool includeMetadata = true,
  }) async {
    try {
      final client = await _getClient(atSign, keysFilePath: keysFilePath);
      final key = AtKey.fromString(atKey);
      
      String result = 'Key Information for: $atKey\n';
      result += '----------------------------------------\n';
      
      if (includeValue) {
        try {
          final atValue = await client.get(key);
          if (atValue.value != null) {
            result += 'Value: ${atValue.value}\n';
          } else {
            result += 'Value: <not found>\n';
          }
        } catch (e) {
          result += 'Value: <error retrieving: $e>\n';
        }
      }
      
      if (includeMetadata) {
        result += '\nMetadata:\n';
        result += '  Key: ${key.key}\n';
        result += '  SharedBy: ${key.sharedBy ?? '<none>'}\n';
        result += '  SharedWith: ${key.sharedWith ?? '<none>'}\n';
        result += '  Namespace: ${key.namespace ?? '<none>'}\n';
        
        final metadata = key.metadata;
        result += '  TTL: ${metadata.ttl ?? '<none>'}\n';
        result += '  TTB: ${metadata.ttb ?? '<none>'}\n';
        result += '  TTR: ${metadata.ttr ?? '<none>'}\n';
        result += '  CCD: ${metadata.ccd ?? '<none>'}\n';
        result += '  IsPublic: ${metadata.isPublic}\n';
        result += '  IsHidden: ${metadata.isHidden}\n';
        result += '  IsEncrypted: ${metadata.isEncrypted}\n';
        result += '  IsBinary: ${metadata.isBinary}\n';
      }
      
      return CallToolResult(
        content: [
          TextContent(text: result),
        ],
      );
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error inspecting key $atKey: $e'),
        ],
        isError: true,
      );
    }
  }
  
  /// Get notifications for the atSign
  static Future<CallToolResult> getNotifications({
    required String atSign,
    String? regex,
    String? keysFilePath,
    int? limit,
  }) async {
    try {
      await _getClient(atSign, keysFilePath: keysFilePath);
      
      // For now, return a placeholder response as the notification API
      // can be complex and varies by version
      return CallToolResult(
        content: [
          TextContent(text: 'Notification monitoring for $atSign would be available.\nRegex filter: ${regex ?? 'none'}\nLimit: ${limit ?? 'none'}\n\nNote: Actual notification fetching requires proper notification service setup.'),
        ],
      );
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error accessing notifications for $atSign: $e'),
        ],
        isError: true,
      );
    }
  }
  
  /// Execute a raw AT Protocol command
  static Future<CallToolResult> executeRawCommand({
    required String atSign,
    required String command,
    String? keysFilePath,
  }) async {
    try {
      final client = await _getClient(atSign, keysFilePath: keysFilePath);
      
      // For raw commands, we'll use the AtClient's local secondary for now
      // This is a simplified approach - in production you might want direct connection access
      String response;
      
      if (command.startsWith('scan')) {
        // Handle scan command
        final keys = await client.getAtKeys();
        response = keys.map((k) => k.toString()).join('\n');
      } else if (command.startsWith('lookup:')) {
        // Handle lookup command
        final keyStr = command.substring(7);
        final key = AtKey.fromString(keyStr);
        final value = await client.get(key);
        response = value.value?.toString() ?? 'null';
      } else {
        response = 'Raw command execution not fully supported: $command';
      }
      
      return CallToolResult(
        content: [
          TextContent(text: 'Command: $command\nResponse: $response'),
        ],
      );
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error executing command "$command": $e'),
        ],
        isError: true,
      );
    }
  }
  
  /// Get stats about the atSign's data
  static Future<CallToolResult> getStats({
    required String atSign,
    String? keysFilePath,
  }) async {
    try {
      final client = await _getClient(atSign, keysFilePath: keysFilePath);
      
      // Get all keys to compute stats
      final allKeys = await client.getAtKeys();
      final publicKeys = allKeys.where((k) => k.metadata.isPublic).length;
      final privateKeys = allKeys.where((k) => !k.metadata.isPublic).length;
      final hiddenKeys = allKeys.where((k) => k.metadata.isHidden).length;
      
      // Get notifications count (placeholder)
      const notificationCount = 0; // Simplified for now
      
      String result = 'Statistics for $atSign:\n';
      result += '------------------------\n';
      result += 'Total Keys: ${allKeys.length}\n';
      result += 'Public Keys: $publicKeys\n';
      result += 'Private Keys: $privateKeys\n';
      result += 'Hidden Keys: $hiddenKeys\n';
      result += 'Notifications: $notificationCount\n';
      
      // Group keys by namespace
      final namespaces = <String, int>{};
      for (final key in allKeys) {
        final namespace = key.namespace ?? '<no-namespace>';
        namespaces[namespace] = (namespaces[namespace] ?? 0) + 1;
      }
      
      if (namespaces.isNotEmpty) {
        result += '\nKeys by Namespace:\n';
        for (final entry in namespaces.entries) {
          result += '  ${entry.key}: ${entry.value}\n';
        }
      }
      
      return CallToolResult(
        content: [
          TextContent(text: result),
        ],
      );
    } catch (e) {
      return CallToolResult(
        content: [
          TextContent(text: 'Error getting stats for $atSign: $e'),
        ],
        isError: true,
      );
    }
  }
}