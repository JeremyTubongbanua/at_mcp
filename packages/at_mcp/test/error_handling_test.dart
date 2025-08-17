import 'package:test/test.dart';
import 'package:at_mcp/src/at_server_operations_service.dart';
import 'package:at_mcp/src/at_key_manager.dart';
import 'package:at_mcp/src/at_onboarding_service.dart';
import 'package:at_mcp/src/virtualenv_manager.dart';
import 'package:dart_mcp/server.dart';

String getTextContent(CallToolResult result) {
  final textContent = result.content.first as TextContent;
  return textContent.text;
}

void main() {
  group('Error Handling and Edge Cases', () {
    
    group('Input Validation', () {
      test('should handle null and empty strings consistently', () async {
        // Test getValue with various invalid inputs
        final testCases = [
          {'atSign': '', 'atKey': 'test.key'},
          {'atSign': '@test', 'atKey': ''},
          {'atSign': '   ', 'atKey': 'test.key'},
          {'atSign': '@test', 'atKey': '   '},
        ];
        
        for (final testCase in testCases) {
          final result = await AtServerOperationsService.getValue(
            atSign: testCase['atSign']!,
            atKey: testCase['atKey']!,
          );
          
          expect(result.isError, isTrue,
                 reason: 'Should fail for invalid input: $testCase');
          expect(getTextContent(result), contains('Error'),
                 reason: 'Error message should contain "Error" for $testCase');
        }
      });
      
      test('should handle special characters in atSign', () async {
        final invalidAtSigns = [
          '@test!',
          '@test@test',
          '@test.com',
          '@test space',
          '@test\n',
          '@test\t',
          '@-test',
          '@test-',
          '@123',
          '@',
        ];
        
        for (final atSign in invalidAtSigns) {
          final result = await AtServerOperationsService.getValue(
            atSign: atSign,
            atKey: 'test.key',
          );
          
          expect(result.isError, isTrue,
                 reason: 'Should fail for invalid atSign: $atSign');
        }
      });
      
      test('should handle special characters in atKey', () async {
        final specialKeys = [
          'test.key with spaces',
          'test.key\n',
          'test.key\t',
          'test.key@special',
          'test.key#hash',
          'test.key%percent',
          'test.key&ampersand',
          'test.key=equals',
          'test.key+plus',
          'тест.ключ', // Cyrillic characters
          '测试.键', // Chinese characters
        ];
        
        for (final atKey in specialKeys) {
          final result = await AtServerOperationsService.getValue(
            atSign: '@test',
            atKey: atKey,
          );
          
          expect(result.isError, isTrue,
                 reason: 'Should handle special key gracefully: $atKey');
        }
      });
    });
    
    group('Large Input Handling', () {
      test('should handle very long atKey names', () async {
        final longKey = 'test.${'a' * 1000}.key'; // Very long key name
        
        final result = await AtServerOperationsService.getValue(
          atSign: '@test',
          atKey: longKey,
        );
        
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error getting value'));
      });
      
      test('should handle very long values in putValue', () async {
        final hugeLongValue = 'x' * 100000; // 100KB string
        
        final result = await AtServerOperationsService.putValue(
          atSign: '@test',
          atKey: 'test.key',
          value: hugeLongValue,
        );
        
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error storing value'));
      });
      
      test('should handle very long regex patterns', () async {
        final longRegex = '.*' + ('a' * 10000) + '.*'; // Very long regex
        
        final result = await AtServerOperationsService.scanKeys(
          atSign: '@test',
          regex: longRegex,
        );
        
        expect(result.isError, isTrue);
        expect(getTextContent(result), contains('Error scanning keys'));
      });
    });
    
    group('Boundary Values', () {
      test('should handle extreme TTL values', () async {
        // Test very large TTL
        final result1 = await AtServerOperationsService.putValue(
          atSign: '@test',
          atKey: 'test.key',
          value: 'test_value',
          ttl: 2147483647, // Max 32-bit integer
        );
        
        expect(result1.isError, isTrue);
        
        // Test negative TTL
        final result2 = await AtServerOperationsService.putValue(
          atSign: '@test',
          atKey: 'test.key',
          value: 'test_value',
          ttl: -1,
        );
        
        expect(result2.isError, isTrue);
        
        // Test zero TTL
        final result3 = await AtServerOperationsService.putValue(
          atSign: '@test',
          atKey: 'test.key',
          value: 'test_value',
          ttl: 0,
        );
        
        expect(result3.isError, isTrue);
      });
      
      test('should handle extreme limit values in scan', () async {
        // Test very large limit
        final result1 = await AtServerOperationsService.scanKeys(
          atSign: '@test',
          limit: 1000000,
        );
        
        expect(result1.isError, isTrue);
        
        // Test negative limit
        final result2 = await AtServerOperationsService.scanKeys(
          atSign: '@test',
          limit: -1,
        );
        
        expect(result2.isError, isTrue);
        
        // Test zero limit
        final result3 = await AtServerOperationsService.scanKeys(
          atSign: '@test',
          limit: 0,
        );
        
        expect(result3.isError, isTrue);
      });
    });
    
    group('Concurrent Access', () {
      test('should handle concurrent getValue calls', () async {
        final futures = List.generate(10, (index) {
          return AtServerOperationsService.getValue(
            atSign: '@test$index',
            atKey: 'test.key$index',
          );
        });
        
        final results = await Future.wait(futures);
        
        // All should complete (either successfully or with error)
        expect(results.length, equals(10));
        
        // All should have proper error handling
        for (final result in results) {
          expect(result.isError, isTrue);
          expect(getTextContent(result), contains('Error'));
        }
      });
      
      test('should handle concurrent putValue calls', () async {
        final futures = List.generate(5, (index) {
          return AtServerOperationsService.putValue(
            atSign: '@test$index',
            atKey: 'test.key$index',
            value: 'value$index',
          );
        });
        
        final results = await Future.wait(futures);
        
        expect(results.length, equals(5));
        
        for (final result in results) {
          expect(result.isError, isTrue);
          expect(getTextContent(result), contains('Error storing value'));
        }
      });
    });
    
    group('Resource Exhaustion', () {
      test('should handle many rapid sequential calls', () async {
        for (int i = 0; i < 20; i++) {
          final result = await AtServerOperationsService.getValue(
            atSign: '@test$i',
            atKey: 'test.key$i',
          );
          
          expect(result.isError, isTrue);
          expect(getTextContent(result), contains('Error getting value'));
        }
      });
      
      test('should handle large batch operations', () async {
        final batchSize = 50;
        final futures = <Future<CallToolResult>>[];
        
        for (int i = 0; i < batchSize; i++) {
          futures.add(AtServerOperationsService.scanKeys(atSign: '@batch$i'));
        }
        
        final results = await Future.wait(futures);
        
        expect(results.length, equals(batchSize));
        
        for (final result in results) {
          expect(result.isError, isTrue);
          expect(getTextContent(result), contains('Error scanning keys'));
        }
      });
    });
    
    group('AtKeyManager Edge Cases', () {
      test('should handle malformed atSign formats', () {
        final malformedAtSigns = [
          'test', // No @
          '@@test', // Double @
          '@', // Just @
          '@test@more', // Multiple @
          '@test.', // Trailing dot
          '@.test', // Leading dot
          '@-test', // Leading dash
          '@test-', // Trailing dash
          '@123test', // Starting with number
          '@TEST', // All caps
        ];
        
        for (final atSign in malformedAtSigns) {
          final cramKey = AtKeyManager.getCramKey(atSign);
          // Should handle gracefully (return null or valid key)
          if (cramKey != null) {
            expect(cramKey, isA<String>());
            expect(cramKey.length, greaterThan(0));
          }
        }
      });
      
      test('should handle unicode atSigns', () {
        final unicodeAtSigns = [
          '@тест', // Cyrillic
          '@测试', // Chinese
          '@テスト', // Japanese
          '@🙂', // Emoji
          '@café', // Accented characters
        ];
        
        for (final atSign in unicodeAtSigns) {
          final cramKey = AtKeyManager.getCramKey(atSign);
          // Should handle gracefully
          if (cramKey != null) {
            expect(cramKey, isA<String>());
          }
        }
      });
    });
    
    group('VirtualenvManager Resilience', () {
      test('should handle rapid status checks', () async {
        final futures = List.generate(10, (_) => VirtualenvManager.getVirtualenvStatus());
        final results = await Future.wait(futures);
        
        expect(results.length, equals(10));
        
        for (final status in results) {
          expect(status, isA<Map<String, dynamic>>());
          expect(status.containsKey('dockerRunning'), isTrue);
          expect(status.containsKey('containerRunning'), isTrue);
        }
      });
      
      test('should handle status check timeouts gracefully', () async {
        // This test ensures the status check doesn't hang indefinitely
        final statusFuture = VirtualenvManager.getVirtualenvStatus();
        final timeoutFuture = Future.delayed(Duration(seconds: 30));
        
        final result = await Future.any([statusFuture, timeoutFuture]);
        
        expect(result, isA<Map<String, dynamic>>(),
               reason: 'Status check should complete within reasonable time');
      });
    });
    
    group('AtOnboardingService Edge Cases', () {
      test('should handle malformed CRAM keys', () async {
        final malformedKeys = [
          'short', // Too short
          '123', // Numbers only
          'CAPS', // All caps
          'key with spaces', // Spaces
          'key\nwith\nnewlines', // Newlines
          'key\twith\ttabs', // Tabs
          '!@#\$%^&*()', // Special characters
          '', // Empty
          'unicode_key_with_special_chars', // Unicode replacement
        ];
        
        for (final key in malformedKeys) {
          expect(
            () => AtOnboardingService.onboardWithCram(
              atSign: '@test',
              cramKey: key,
            ),
            throwsA(isA<Exception>()),
            reason: 'Should reject malformed CRAM key: $key',
          );
        }
      });
      
      test('should handle invalid file paths', () async {
        final invalidPaths = [
          '', // Empty path
          '/', // Root directory
          '/nonexistent/path/that/does/not/exist', // Non-existent path
          'relative/path', // Relative path
          '/path with spaces/file.atKeys', // Spaces in path
          '/path/with/ünicode/file.atKeys', // Unicode in path
          '/path/ending/in/slash/', // Directory instead of file
        ];
        
        for (final path in invalidPaths) {
          expect(
            () => AtOnboardingService.onboardWithCram(
              atSign: '@test',
              cramKey: 'valid_cram_key_12345678901234567890',
              keysFilePath: path,
            ),
            throwsA(isA<Exception>()),
            reason: 'Should reject invalid path: $path',
          );
        }
      });
    });
  });
}