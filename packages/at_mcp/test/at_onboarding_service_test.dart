import 'package:test/test.dart';
import 'package:at_mcp/src/at_onboarding_service.dart';

void main() {
  group('AtOnboardingService Tests', () {
    
    group('onboardWithCram', () {
      test('should fail gracefully with invalid atSign', () async {
        expect(
          () => AtOnboardingService.onboardWithCram(
            atSign: 'invalid_atsign',
            cramKey: 'invalid_key',
          ),
          throwsA(isA<Exception>()),
        );
      });
      
      test('should fail gracefully with empty atSign', () async {
        expect(
          () => AtOnboardingService.onboardWithCram(
            atSign: '',
            cramKey: 'some_key',
          ),
          throwsA(isA<Exception>()),
        );
      });
      
      test('should fail gracefully with invalid CRAM key', () async {
        expect(
          () => AtOnboardingService.onboardWithCram(
            atSign: '@test',
            cramKey: 'invalid_short_key',
          ),
          throwsA(isA<Exception>()),
        );
      });
      
      test('should fail gracefully with null CRAM key', () async {
        expect(
          () => AtOnboardingService.onboardWithCram(
            atSign: '@test',
            cramKey: null,
          ),
          throwsA(isA<Exception>()),
        );
      });
      
      test('should handle custom keys file path', () async {
        expect(
          () => AtOnboardingService.onboardWithCram(
            atSign: '@test',
            cramKey: 'test_key',
            keysFilePath: '/custom/path/keys.atKeys',
          ),
          throwsA(isA<Exception>()),
        );
      });
      
      test('should validate atSign format', () async {
        // Test various invalid atSign formats
        final invalidAtSigns = [
          'test', // missing @
          '@@test', // double @
          '@', // empty after @
          '@test@', // multiple @
          '@test.', // trailing dot
          '@-test', // starting with dash
          '@test-', // ending with dash
        ];
        
        for (final invalidAtSign in invalidAtSigns) {
          expect(
            () => AtOnboardingService.onboardWithCram(
              atSign: invalidAtSign,
              cramKey: 'test_key',
            ),
            throwsA(isA<Exception>()),
            reason: 'Should reject invalid atSign: $invalidAtSign',
          );
        }
      });
    });
    
    group('setupDevelopmentAtSigns', () {
      test('should handle empty atSigns list', () async {
        final results = await AtOnboardingService.setupDevelopmentAtSigns(
          atSigns: [],
        );
        
        expect(results, isEmpty);
      });
      
      test('should handle invalid atSigns in list', () async {
        final results = await AtOnboardingService.setupDevelopmentAtSigns(
          atSigns: ['@invalid1', '@invalid2'],
        );
        
        expect(results, isNotEmpty);
        expect(results.length, equals(2));
        
        // All should fail
        for (final entry in results.entries) {
          expect(entry.value, isFalse, 
                 reason: 'Invalid atSign ${entry.key} should fail');
        }
      });
      
      test('should handle mixed valid and invalid atSigns', () async {
        final results = await AtOnboardingService.setupDevelopmentAtSigns(
          atSigns: ['@gary', '@invalid', '@xavier'],
        );
        
        expect(results, isNotEmpty);
        expect(results.length, equals(3));
        expect(results.keys, containsAll(['@gary', '@invalid', '@xavier']));
        
        // Should track results for all atSigns
        expect(results['@invalid'], isFalse);
        // Note: @gary and @xavier might also fail in test environment
      });
      
      test('should respect custom keys directory', () async {
        final results = await AtOnboardingService.setupDevelopmentAtSigns(
          atSigns: ['@test'],
          keysDirectory: '/tmp/test_keys',
        );
        
        expect(results, isNotEmpty);
        expect(results.containsKey('@test'), isTrue);
        // Should fail gracefully with custom directory
        expect(results['@test'], isFalse);
      });
      
      test('should handle null keys directory', () async {
        final results = await AtOnboardingService.setupDevelopmentAtSigns(
          atSigns: ['@test'],
          keysDirectory: null,
        );
        
        expect(results, isNotEmpty);
        expect(results.containsKey('@test'), isTrue);
      });
    });
    
    group('Edge Cases', () {
      test('should handle very long CRAM keys', () async {
        final longCramKey = 'a' * 1000; // Very long key
        
        expect(
          () => AtOnboardingService.onboardWithCram(
            atSign: '@test',
            cramKey: longCramKey,
          ),
          throwsA(isA<Exception>()),
        );
      });
      
      test('should handle special characters in keys file path', () async {
        expect(
          () => AtOnboardingService.onboardWithCram(
            atSign: '@test',
            cramKey: 'test_key',
            keysFilePath: '/path/with spaces/and@special#chars.atKeys',
          ),
          throwsA(isA<Exception>()),
        );
      });
      
      test('should handle concurrent onboarding requests', () async {
        final futures = List.generate(3, (index) {
          return AtOnboardingService.onboardWithCram(
            atSign: '@test$index',
            cramKey: 'test_key_$index',
          );
        });
        
        // All should fail, but shouldn't crash
        for (final future in futures) {
          expect(() => future, throwsA(isA<Exception>()));
        }
      });
      
      test('should validate CRAM key format', () async {
        final invalidCramKeys = [
          '', // empty
          'short', // too short
          'INVALID_NON_HEX_KEY_WITH_INVALID_CHARS!@#', // non-hex
          '123', // too short numbers
        ];
        
        for (final invalidKey in invalidCramKeys) {
          expect(
            () => AtOnboardingService.onboardWithCram(
              atSign: '@test',
              cramKey: invalidKey,
            ),
            throwsA(isA<Exception>()),
            reason: 'Should reject invalid CRAM key: $invalidKey',
          );
        }
      });
    });
  });
}