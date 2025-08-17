import 'package:test/test.dart';
import 'package:at_mcp/src/at_server_operations_service.dart';
import 'package:dart_mcp/server.dart';

String getTextContent(CallToolResult result) {
  final textContent = result.content.first as TextContent;
  return textContent.text;
}

void main() {
  group('AtServerOperationsService Tests', () {
    
    group('getValue', () {
      test('should return error for invalid atSign', () async {
        final result = await AtServerOperationsService.getValue(
          atSign: 'invalid_atsign',
          atKey: 'test.key',
        );
        
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error getting value'));
      });
      
      test('should return error for empty atKey', () async {
        final result = await AtServerOperationsService.getValue(
          atSign: '@test',
          atKey: '',
        );
        
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error getting value'));
      });
      
      test('should handle keys file path parameter', () async {
        final result = await AtServerOperationsService.getValue(
          atSign: '@test',
          atKey: 'test.key',
          keysFilePath: '/path/to/keys',
        );
        
        // Should fail gracefully with error
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error getting value'));
      });
    });
    
    group('putValue', () {
      test('should return error for invalid atSign', () async {
        final result = await AtServerOperationsService.putValue(
          atSign: 'invalid_atsign',
          atKey: 'test.key',
          value: 'test_value',
        );
        
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error storing value'));
      });
      
      test('should handle TTL parameter parsing', () async {
        final result = await AtServerOperationsService.putValue(
          atSign: '@test',
          atKey: 'test.key',
          value: 'test_value',
          ttl: 3600000, // 1 hour in milliseconds
        );
        
        // Should fail gracefully with error
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error storing value'));
      });
      
      test('should handle boolean metadata parameters', () async {
        final result = await AtServerOperationsService.putValue(
          atSign: '@test',
          atKey: 'test.key',
          value: 'test_value',
          isPublic: true,
          isHidden: false,
        );
        
        // Should fail gracefully with error
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error storing value'));
      });
    });
    
    group('deleteKey', () {
      test('should return error for invalid atSign', () async {
        final result = await AtServerOperationsService.deleteKey(
          atSign: 'invalid_atsign',
          atKey: 'test.key',
        );
        
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error deleting'));
      });
      
      test('should handle empty atKey', () async {
        final result = await AtServerOperationsService.deleteKey(
          atSign: '@test',
          atKey: '',
        );
        
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error deleting'));
      });
    });
    
    group('scanKeys', () {
      test('should return error for invalid atSign', () async {
        final result = await AtServerOperationsService.scanKeys(
          atSign: 'invalid_atsign',
        );
        
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error scanning keys'));
      });
      
      test('should handle regex parameter', () async {
        final result = await AtServerOperationsService.scanKeys(
          atSign: '@test',
          regex: '.*\\.publickey',
        );
        
        // Should fail gracefully with error
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error scanning keys'));
      });
      
      test('should handle limit parameter', () async {
        final result = await AtServerOperationsService.scanKeys(
          atSign: '@test',
          limit: 10,
        );
        
        // Should fail gracefully with error
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error scanning keys'));
      });
    });
    
    group('inspectKey', () {
      test('should return error for invalid atSign', () async {
        final result = await AtServerOperationsService.inspectKey(
          atSign: 'invalid_atsign',
          atKey: 'test.key',
        );
        
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error inspecting key'));
      });
      
      test('should handle includeValue parameter', () async {
        final result = await AtServerOperationsService.inspectKey(
          atSign: '@test',
          atKey: 'test.key',
          includeValue: false,
        );
        
        // Should fail gracefully with error
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error inspecting key'));
      });
      
      test('should handle includeMetadata parameter', () async {
        final result = await AtServerOperationsService.inspectKey(
          atSign: '@test',
          atKey: 'test.key',
          includeMetadata: false,
        );
        
        // Should fail gracefully with error
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error inspecting key'));
      });
    });
    
    group('getNotifications', () {
      test('should return placeholder for notifications', () async {
        final result = await AtServerOperationsService.getNotifications(
          atSign: '@test',
        );
        
        // Should not be an error, but return placeholder message
        expect(result.isError, isFalse);
        expect(getTextContent(result), contains('Notification monitoring'));
        expect(getTextContent(result), contains('would be available'));
      });
      
      test('should handle regex parameter in placeholder', () async {
        final result = await AtServerOperationsService.getNotifications(
          atSign: '@test',
          regex: '.*\\.notification',
        );
        
        expect(result.isError, isFalse);
        expect(getTextContent(result), contains('.*\\.notification'));
      });
      
      test('should handle limit parameter in placeholder', () async {
        final result = await AtServerOperationsService.getNotifications(
          atSign: '@test',
          limit: 5,
        );
        
        expect(result.isError, isFalse);
        expect(getTextContent(result), contains('5'));
      });
    });
    
    group('executeRawCommand', () {
      test('should return error for invalid atSign', () async {
        final result = await AtServerOperationsService.executeRawCommand(
          atSign: 'invalid_atsign',
          command: 'scan',
        );
        
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error executing command'));
      });
      
      test('should handle scan command', () async {
        final result = await AtServerOperationsService.executeRawCommand(
          atSign: '@test',
          command: 'scan',
        );
        
        // Should fail gracefully with error
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error executing command'));
      });
      
      test('should handle lookup command', () async {
        final result = await AtServerOperationsService.executeRawCommand(
          atSign: '@test',
          command: 'lookup:test.key',
        );
        
        // Should fail gracefully with error
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error executing command'));
      });
      
      test('should handle unsupported command', () async {
        final result = await AtServerOperationsService.executeRawCommand(
          atSign: '@test',
          command: 'unsupported_command',
        );
        
        // Should fail gracefully with error
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error executing command'));
      });
    });
    
    group('getStats', () {
      test('should return error for invalid atSign', () async {
        final result = await AtServerOperationsService.getStats(
          atSign: 'invalid_atsign',
        );
        
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error getting stats'));
      });
      
      test('should handle keys file path parameter', () async {
        final result = await AtServerOperationsService.getStats(
          atSign: '@test',
          keysFilePath: '/path/to/keys',
        );
        
        // Should fail gracefully with error
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error getting stats'));
      });
    });
    
    group('Edge Cases', () {
      test('should handle null parameters gracefully', () async {
        final result = await AtServerOperationsService.getValue(
          atSign: '@test',
          atKey: 'test.key',
          keysFilePath: null,
        );
        
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error getting value'));
      });
      
      test('should handle special characters in atKey', () async {
        final result = await AtServerOperationsService.getValue(
          atSign: '@test',
          atKey: 'test.key.with.special@chars#',
        );
        
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error getting value'));
      });
      
      test('should handle very long values', () async {
        final longValue = 'x' * 10000; // 10KB string
        final result = await AtServerOperationsService.putValue(
          atSign: '@test',
          atKey: 'test.key',
          value: longValue,
        );
        
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error storing value'));
      });
    });
  });
}