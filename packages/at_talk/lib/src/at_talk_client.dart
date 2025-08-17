import 'dart:convert';
import 'package:at_client/at_client.dart';
import 'message.dart';

class AtTalkClient {
  late AtClient _atClient;
  final String _currentAtSign;
  final String _nameSpace = 'attalk';
  final String? _rootServer;
  final int _rootPort;
  final String? _keysFilePath;
  
  AtTalkClient(
    this._currentAtSign, {
    String? rootServer,
    int rootPort = 64,
    String? keysFilePath,
  }) : _rootServer = rootServer,
       _rootPort = rootPort,
       _keysFilePath = keysFilePath;

  Future<void> initialize() async {
    var atClientManager = AtClientManager.getInstance();
    
    final prefs = AtClientPreference()
      ..rootDomain = _rootServer ?? 'vip.ve.atsign.zone'
      ..rootPort = _rootPort
      ..namespace = _nameSpace
      ..hiveStoragePath = './.atsign/storage/${_currentAtSign}'
      ..commitLogPath = './.atsign/commit/${_currentAtSign}'
      ..isLocalStoreRequired = true;
    
    // Set custom keys file path if provided
    if (_keysFilePath != null) {
      prefs.privateKey = _keysFilePath;
    }
    
    await atClientManager.setCurrentAtSign(
      _currentAtSign,
      _nameSpace,
      prefs,
    );
    _atClient = atClientManager.atClient;
  }

  Future<void> sendMessage(String toAtSign, String content) async {
    final message = Message(
      from: _currentAtSign,
      to: toAtSign,
      content: content,
    );

    final atKey = AtKey()
      ..key = 'message_${DateTime.now().millisecondsSinceEpoch}'
      ..sharedWith = toAtSign
      ..namespace = _nameSpace
      ..metadata = (Metadata()
        ..isPublic = false
        ..isEncrypted = true
        ..ttl = 86400000); // 24 hours

    await _atClient.put(atKey, jsonEncode(message.toJson()));
    print('Message sent to $toAtSign: $content');
  }
  
  /// Send message to multiple recipients (group chat)
  Future<void> sendGroupMessage(List<String> recipients, String content) async {
    final futures = <Future>[];
    
    for (final recipient in recipients) {
      if (recipient != _currentAtSign) {
        futures.add(sendMessage(recipient, content));
      }
    }
    
    await Future.wait(futures);
    print('Group message sent to ${recipients.where((r) => r != _currentAtSign).join(', ')}: $content');
  }

  Future<List<Message>> getMessages({List<String>? fromAtSigns}) async {
    final messages = <Message>[];
    
    try {
      final scanResult = await _atClient.getAtKeys(
        regex: 'message_.*@$_currentAtSign',
        sharedBy: null,
      );

      for (final atKey in scanResult) {
        try {
          final value = await _atClient.get(atKey);
          if (value.value != null) {
            final messageData = jsonDecode(value.value!);
            final message = Message.fromJson(messageData);
            
            // Filter by specific senders if provided
            if (fromAtSigns == null || fromAtSigns.contains(message.from)) {
              messages.add(message);
            }
          }
        } catch (e) {
          print('Error retrieving message: $e');
        }
      }
    } catch (e) {
      print('Error scanning for messages: $e');
    }

    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }
  
  /// Get recent messages from group chat participants
  Future<List<Message>> getGroupMessages(List<String> participants, {int limit = 20}) async {
    final messages = await getMessages(fromAtSigns: participants);
    return messages.take(limit).toList();
  }

  Future<void> startListening({List<String>? groupParticipants}) async {
    print('Listening for messages...');
    
    while (true) {
      try {
        final messages = groupParticipants != null 
            ? await getGroupMessages(groupParticipants, limit: 10)
            : await getMessages();
            
        for (final message in messages) {
          if (message.to == _currentAtSign) {
            if (groupParticipants != null) {
              print('[GROUP] ${message.toString()}');
            } else {
              print('New message: ${message.toString()}');
            }
          }
        }
        await Future.delayed(Duration(seconds: 2));
      } catch (e) {
        print('Error while listening: $e');
        await Future.delayed(Duration(seconds: 5));
      }
    }
  }
  
  /// Check if an atSign is reachable
  Future<bool> isAtSignReachable(String atSign) async {
    try {
      final testKey = AtKey()
        ..key = 'ping_${DateTime.now().millisecondsSinceEpoch}'
        ..sharedWith = atSign
        ..namespace = _nameSpace
        ..metadata = (Metadata()
          ..isPublic = false
          ..ttl = 10000); // 10 seconds
      
      await _atClient.put(testKey, 'ping');
      await _atClient.delete(testKey); // Clean up
      return true;
    } catch (e) {
      return false;
    }
  }
}