import 'package:test/test.dart';
import 'package:at_mcp/src/virtualenv_manager.dart';

void main() {
  group('VirtualenvManager Tests', () {
    
    group('getVirtualenvStatus', () {
      test('should return status map with required keys', () async {
        final status = await VirtualenvManager.getVirtualenvStatus();
        
        expect(status, isA<Map<String, dynamic>>());
        expect(status.containsKey('dockerRunning'), isTrue);
        expect(status.containsKey('containerRunning'), isTrue);
        
        // Values should be boolean
        expect(status['dockerRunning'], isA<bool>());
        expect(status['containerRunning'], isA<bool>());
      });
      
      test('should include additional status when container is running', () async {
        final status = await VirtualenvManager.getVirtualenvStatus();
        
        if (status['containerRunning'] == true) {
          expect(status.containsKey('rootServerReady'), isTrue);
          expect(status['rootServerReady'], isA<bool>());
        }
      });
      
      test('should handle Docker not available gracefully', () async {
        // This test should pass even if Docker is not installed
        final status = await VirtualenvManager.getVirtualenvStatus();
        
        expect(status, isNotNull);
        expect(status['dockerRunning'], isA<bool>());
        
        // If Docker is not available, should be false
        if (status['dockerRunning'] == false) {
          expect(status['containerRunning'], isFalse);
        }
      });
      
      test('should handle container not running gracefully', () async {
        final status = await VirtualenvManager.getVirtualenvStatus();
        
        // If container is not running, some fields might be absent
        if (status['containerRunning'] == false) {
          // Should still have basic status
          expect(status.containsKey('dockerRunning'), isTrue);
        }
      });
      
      test('should include atSign resolution test when available', () async {
        final status = await VirtualenvManager.getVirtualenvStatus();
        
        // atSignResolution might be present if container is running and responsive
        if (status.containsKey('atSignResolution')) {
          expect(status['atSignResolution'], isA<String>());
        }
      });
    });
    
    group('Error Handling', () {
      test('should not throw exceptions on status check', () async {
        // This should never throw, even in adverse conditions
        expect(
          () async => await VirtualenvManager.getVirtualenvStatus(),
          returnsNormally,
        );
      });
      
      test('should return consistent status structure', () async {
        // Run multiple times to ensure consistency
        final status1 = await VirtualenvManager.getVirtualenvStatus();
        final status2 = await VirtualenvManager.getVirtualenvStatus();
        
        // Same keys should be present
        expect(status1.keys.toSet(), equals(status2.keys.toSet()));
        
        // Docker status should be consistent (assuming no changes between calls)
        expect(status1['dockerRunning'], equals(status2['dockerRunning']));
      });
      
      test('should handle concurrent status requests', () async {
        // Multiple concurrent requests should not interfere
        final futures = List.generate(3, (_) => VirtualenvManager.getVirtualenvStatus());
        final results = await Future.wait(futures);
        
        // All should succeed
        for (final result in results) {
          expect(result, isA<Map<String, dynamic>>());
          expect(result.containsKey('dockerRunning'), isTrue);
          expect(result.containsKey('containerRunning'), isTrue);
        }
        
        // Results should be consistent
        final dockerStatuses = results.map((r) => r['dockerRunning']).toSet();
        expect(dockerStatuses.length, equals(1), 
               reason: 'Docker status should be consistent across concurrent calls');
      });
    });
    
    group('Status Validation', () {
      test('should have valid boolean values for core status', () async {
        final status = await VirtualenvManager.getVirtualenvStatus();
        
        final booleanFields = ['dockerRunning', 'containerRunning'];
        
        for (final field in booleanFields) {
          if (status.containsKey(field)) {
            expect(status[field], isA<bool>(), 
                   reason: '$field should be boolean');
          }
        }
      });
      
      test('should have valid optional status fields', () async {
        final status = await VirtualenvManager.getVirtualenvStatus();
        
        // Optional boolean fields
        final optionalBoolFields = ['rootServerReady'];
        for (final field in optionalBoolFields) {
          if (status.containsKey(field)) {
            expect(status[field], isA<bool>(), 
                   reason: '$field should be boolean when present');
          }
        }
        
        // Optional string fields
        final optionalStringFields = ['atSignResolution'];
        for (final field in optionalStringFields) {
          if (status.containsKey(field)) {
            expect(status[field], isA<String>(), 
                   reason: '$field should be string when present');
          }
        }
      });
      
      test('should maintain logical consistency', () async {
        final status = await VirtualenvManager.getVirtualenvStatus();
        
        // If Docker is not running, container cannot be running
        if (status['dockerRunning'] == false) {
          expect(status['containerRunning'], isFalse,
                 reason: 'Container cannot run if Docker is not running');
        }
        
        // If container is not running, root server cannot be ready
        if (status['containerRunning'] == false) {
          if (status.containsKey('rootServerReady')) {
            expect(status['rootServerReady'], isFalse,
                   reason: 'Root server cannot be ready if container is not running');
          }
        }
      });
    });
  });
}