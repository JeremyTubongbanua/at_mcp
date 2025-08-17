import 'package:test/test.dart';
import 'package:at_mcp/src/at_key_manager.dart';

void main() {
  group('AtKeyManager Tests', () {
    
    group('getCramKey', () {
      test('should return valid CRAM key for known atSigns', () {
        final keys = [
          '@gary',
          '@xavier', 
          '@alice',
          '@bob',
          '@charlie',
          '@david',
          '@eve',
          '@faulkner',
          '@grace',
          '@heidi',
          '@ivan',
          '@judy',
          '@mallory',
          '@nancy',
          '@oscar',
          '@peggy',
          '@romeo',
          '@sybil',
          '@trent',
          '@walter'
        ];
        
        for (final atSign in keys) {
          final cramKey = AtKeyManager.getCramKey(atSign);
          expect(cramKey, isNotNull, reason: 'CRAM key should exist for $atSign');
          expect(cramKey!.length, greaterThan(50), reason: 'CRAM key should be sufficiently long for $atSign');
          expect(cramKey, matches(RegExp(r'^[a-z0-9]+$')), reason: 'CRAM key should be alphanumeric for $atSign');
        }
      });
      
      test('should return null for unknown atSign', () {
        final cramKey = AtKeyManager.getCramKey('@unknown');
        expect(cramKey, isNull);
      });
      
      test('should handle atSign with @ prefix', () {
        final cramKey1 = AtKeyManager.getCramKey('@gary');
        final cramKey2 = AtKeyManager.getCramKey('gary');
        
        expect(cramKey1, isNotNull);
        expect(cramKey2, isNotNull);
        expect(cramKey1, equals(cramKey2));
      });
      
      test('should handle empty and null atSign', () {
        expect(AtKeyManager.getCramKey(''), isNull);
        expect(AtKeyManager.getCramKey('@'), isNull);
      });
    });
    
    group('getAvailableAtSigns', () {
      test('should return list of available atSigns', () {
        final atSigns = AtKeyManager.getAvailableAtSigns();
        
        expect(atSigns, isNotEmpty);
        expect(atSigns, contains('@gary'));
        expect(atSigns, contains('@xavier'));
        expect(atSigns, contains('@alice'));
        expect(atSigns, contains('@bob'));
        
        // Should contain @ prefix (based on actual implementation)
        for (final atSign in atSigns) {
          expect(atSign.startsWith('@'), isTrue, reason: 'atSign should have @ prefix: $atSign');
        }
      });
      
      test('should return consistent list', () {
        final atSigns1 = AtKeyManager.getAvailableAtSigns();
        final atSigns2 = AtKeyManager.getAvailableAtSigns();
        
        expect(atSigns1.length, equals(atSigns2.length));
        expect(atSigns1.toSet(), equals(atSigns2.toSet()));
      });
    });
    
    group('downloadPkamKeys', () {
      test('should fail gracefully for unknown atSign', () async {
        expect(
          () => AtKeyManager.downloadPkamKeys('@unknown'),
          throwsA(isA<Exception>()),
        );
      });
      
      test('should fail gracefully for invalid target path', () async {
        expect(
          () => AtKeyManager.downloadPkamKeys('@gary', targetPath: '/invalid/path/that/does/not/exist'),
          throwsA(isA<Exception>()),
        );
      });
      
      test('should validate atSign parameter', () async {
        expect(
          () => AtKeyManager.downloadPkamKeys(''),
          throwsA(isA<Exception>()),
        );
      });
    });
    
    group('Edge Cases', () {
      test('should handle case sensitivity correctly', () {
        final cramKey1 = AtKeyManager.getCramKey('@Gary'); // Mixed case
        final cramKey2 = AtKeyManager.getCramKey('@gary'); // Lower case
        
        // Should be consistent (either both null or both equal)
        if (cramKey1 != null || cramKey2 != null) {
          expect(cramKey1, equals(cramKey2));
        }
      });
      
      test('should handle whitespace in atSign', () {
        expect(AtKeyManager.getCramKey(' @gary '), isNull);
        expect(AtKeyManager.getCramKey('@gary '), isNull);
        expect(AtKeyManager.getCramKey(' @gary'), isNull);
      });
      
      test('should validate all CRAM keys are unique', () {
        final atSigns = AtKeyManager.getAvailableAtSigns();
        final cramKeys = <String>{};
        
        for (final atSign in atSigns) {
          final cramKey = AtKeyManager.getCramKey(atSign);
          if (cramKey != null) {
            expect(cramKeys.contains(cramKey), isFalse, 
                   reason: 'CRAM key for $atSign should be unique');
            cramKeys.add(cramKey);
          }
        }
        
        expect(cramKeys.length, greaterThan(5), 
               reason: 'Should have multiple unique CRAM keys');
      });
    });
  });
}