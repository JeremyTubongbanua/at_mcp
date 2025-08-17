import 'package:test/test.dart';
import 'package:at_talk/at_talk.dart';

void main() {
  group('Message Tests', () {
    test('should create a message with valid data', () {
      final message = Message(
        from: '@xavier',
        to: '@gary',
        content: 'Hello there!',
      );

      expect(message.from, equals('@xavier'));
      expect(message.to, equals('@gary'));
      expect(message.content, equals('Hello there!'));
      expect(message.timestamp, isNotNull);
    });

    test('should serialize and deserialize message correctly', () {
      final originalMessage = Message(
        from: '@gary',
        to: '@xavier',
        content: 'How are you?',
        timestamp: DateTime.parse('2024-01-01T10:00:00Z'),
      );

      final json = originalMessage.toJson();
      final deserializedMessage = Message.fromJson(json);

      expect(deserializedMessage.from, equals(originalMessage.from));
      expect(deserializedMessage.to, equals(originalMessage.to));
      expect(deserializedMessage.content, equals(originalMessage.content));
      expect(deserializedMessage.timestamp, equals(originalMessage.timestamp));
    });

    test('should format message string correctly', () {
      final message = Message(
        from: '@xavier',
        to: '@gary',
        content: 'Test message',
        timestamp: DateTime.parse('2024-01-01T10:00:00Z'),
      );

      final messageString = message.toString();
      expect(messageString, contains('[@xavier -> @gary]'));
      expect(messageString, contains('Test message'));
    });
  });
}