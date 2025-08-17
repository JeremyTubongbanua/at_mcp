import 'dart:io';
import 'dart:async';
import 'package:args/args.dart';
import 'package:at_talk/at_talk.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('atsign', abbr: 'a', help: 'Your atSign (e.g., @xavier or @gary)')
    ..addOption('root-server', abbr: 'r', help: 'Root server domain (default: vip.ve.atsign.zone)')
    ..addOption('root-port', abbr: 'p', help: 'Root server port (default: 64)')
    ..addOption('keys', abbr: 'k', help: 'Path to atKeys file for authentication')
    ..addMultiOption('to', abbr: 't', help: 'Recipients for group chat (can be used multiple times)')
    ..addFlag('help', abbr: 'h', help: 'Show help', negatable: false);

  final results = parser.parse(arguments);

  if (results['help'] || !results.wasParsed('atsign')) {
    print('AT Talk - Enhanced messaging with AT Protocol');
    print('Usage: dart run at_talk --atsign <@your_atsign> [options]');
    print('');
    print(parser.usage);
    print('');
    print('Commands:');
    print('  send <@recipient> <message>     - Send a message to one person');
    print('  group <message>                 - Send message to group (use -t flags)');
    print('  listen                          - Listen for incoming messages');
    print('  listen-group                    - Listen for group messages');
    print('  messages                        - Show recent messages');
    print('  group-messages                  - Show group conversation');
    print('  ping <@recipient>               - Test if atSign is reachable');
    print('  participants                    - Show current group participants');
    print('  quit                            - Exit the application');
    print('');
    print('Examples:');
    print('  # Basic usage');
    print('  dart run at_talk -a @xavier');
    print('');
    print('  # Custom root server');
    print('  dart run at_talk -a @xavier -r localhost -p 64');
    print('');
    print('  # Group chat with multiple participants');
    print('  dart run at_talk -a @xavier -t @gary -t @alice -t @bob');
    print('');
    print('  # Custom keys file');
    print('  dart run at_talk -a @xavier -k /path/to/@xavier_keys.atKeys');
    exit(0);
  }

  final atSign = results['atsign'] as String;
  if (!atSign.startsWith('@')) {
    print('Error: atSign must start with @ (e.g., @xavier)');
    exit(1);
  }
  
  // Parse additional options
  final rootServer = results['root-server'] as String?;
  final rootPortStr = results['root-port'] as String?;
  final rootPort = rootPortStr != null ? int.tryParse(rootPortStr) ?? 64 : 64;
  final keysFilePath = results['keys'] as String?;
  final groupParticipants = (results['to'] as List<String>? ?? [])
      .map((p) => p.startsWith('@') ? p : '@$p')
      .toList();
  
  // Add current user to group if group participants are specified
  if (groupParticipants.isNotEmpty && !groupParticipants.contains(atSign)) {
    groupParticipants.add(atSign);
  }

  final client = AtTalkClient(
    atSign,
    rootServer: rootServer,
    rootPort: rootPort,
    keysFilePath: keysFilePath,
  );
  
  print('Initializing AT Talk for $atSign...');
  if (rootServer != null) {
    print('Using root server: $rootServer:$rootPort');
  }
  if (keysFilePath != null) {
    print('Using keys file: $keysFilePath');
  }
  if (groupParticipants.isNotEmpty) {
    print('Group chat participants: ${groupParticipants.join(', ')}');
  }
  
  try {
    await client.initialize();
    print('Connected successfully!');
  } catch (e) {
    print('Failed to initialize: $e');
    exit(1);
  }

  print('AT Talk ready! Type "help" for commands.');
  print('Connected as: $atSign');

  await _runInteractiveMode(client, atSign, groupParticipants);
}

Future<void> _runInteractiveMode(AtTalkClient client, String currentAtSign, List<String> groupParticipants) async {
  
  bool isListening = false;
  Timer? messageTimer;

  while (true) {
    stdout.write('at_talk> ');
    final input = stdin.readLineSync()?.trim() ?? '';
    
    if (input.isEmpty) continue;

    final parts = input.split(' ');
    final command = parts[0].toLowerCase();

    switch (command) {
      case 'help':
        _showHelp(groupParticipants.isNotEmpty);
        break;
        
      case 'send':
        if (parts.length < 3) {
          print('Usage: send <@recipient> <message>');
          break;
        }
        
        final recipient = parts[1];
        final message = parts.sublist(2).join(' ');
        
        if (!recipient.startsWith('@')) {
          print('Error: Recipient must start with @ (e.g., @gary)');
          break;
        }
        
        try {
          await client.sendMessage(recipient, message);
        } catch (e) {
          print('Failed to send message: $e');
        }
        break;
        
      case 'group':
        if (groupParticipants.isEmpty) {
          print('No group participants specified. Use -t flags when starting at_talk.');
          break;
        }
        
        if (parts.length < 2) {
          print('Usage: group <message>');
          break;
        }
        
        final message = parts.sublist(1).join(' ');
        
        try {
          await client.sendGroupMessage(groupParticipants, message);
        } catch (e) {
          print('Failed to send group message: $e');
        }
        break;
        
      case 'ping':
        if (parts.length < 2) {
          print('Usage: ping <@recipient>');
          break;
        }
        
        final target = parts[1];
        if (!target.startsWith('@')) {
          print('Error: Target must start with @ (e.g., @gary)');
          break;
        }
        
        print('Pinging $target...');
        try {
          final reachable = await client.isAtSignReachable(target);
          print('$target is ${reachable ? 'reachable' : 'not reachable'}');
        } catch (e) {
          print('Failed to ping $target: $e');
        }
        break;
        
      case 'participants':
        if (groupParticipants.isEmpty) {
          print('No group participants configured.');
        } else {
          print('Group participants: ${groupParticipants.join(', ')}');
        }
        break;
        
      case 'listen':
        if (isListening) {
          print('Already listening for messages...');
          break;
        }
        
        isListening = true;
        print('Starting to listen for messages (press Enter to stop)...');
        
        messageTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
          try {
            final messages = await client.getMessages();
            final recentMessages = messages
                .where((m) => m.to == currentAtSign)
                .toList();
            
            if (recentMessages.isNotEmpty) {
              print('\n--- Recent Messages ---');
              for (final message in recentMessages.take(5)) {
                print(message.toString());
              }
              print('----------------------');
              stdout.write('at_talk> ');
            }
          } catch (e) {
            print('Error checking messages: $e');
          }
        });
        
        // Wait for user to press enter to stop listening
        await Future(() async {
          stdin.readLineSync();
          messageTimer?.cancel();
          isListening = false;
          print('Stopped listening.');
        });
        break;
        
      case 'listen-group':
        if (groupParticipants.isEmpty) {
          print('No group participants specified. Use -t flags when starting at_talk.');
          break;
        }
        
        if (isListening) {
          print('Already listening for messages...');
          break;
        }
        
        isListening = true;
        print('Starting to listen for group messages (press Enter to stop)...');
        print('Group: ${groupParticipants.join(', ')}');
        
        messageTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
          try {
            final messages = await client.getGroupMessages(groupParticipants);
            final recentMessages = messages
                .where((m) => m.to == currentAtSign)
                .toList();
            
            if (recentMessages.isNotEmpty) {
              print('\n--- Group Messages ---');
              for (final message in recentMessages.take(5)) {
                print('[GROUP] ${message.toString()}');
              }
              print('---------------------');
              stdout.write('at_talk> ');
            }
          } catch (e) {
            print('Error checking group messages: $e');
          }
        });
        
        // Wait for user to press enter to stop listening
        await Future(() async {
          stdin.readLineSync();
          messageTimer?.cancel();
          isListening = false;
          print('Stopped listening.');
        });
        break;
        
      case 'messages':
        try {
          final messages = await client.getMessages();
          final relevantMessages = messages
              .where((m) => m.to == currentAtSign || m.from == currentAtSign)
              .toList();
          
          if (relevantMessages.isEmpty) {
            print('No messages found.');
          } else {
            print('\n--- Message History ---');
            for (final message in relevantMessages.take(10)) {
              print(message.toString());
            }
            print('----------------------');
          }
        } catch (e) {
          print('Failed to retrieve messages: $e');
        }
        break;
        
      case 'group-messages':
        if (groupParticipants.isEmpty) {
          print('No group participants specified. Use -t flags when starting at_talk.');
          break;
        }
        
        try {
          final messages = await client.getGroupMessages(groupParticipants, limit: 15);
          final relevantMessages = messages
              .where((m) => m.to == currentAtSign || groupParticipants.contains(m.from))
              .toList();
          
          if (relevantMessages.isEmpty) {
            print('No group messages found.');
          } else {
            print('\n--- Group Message History ---');
            print('Participants: ${groupParticipants.join(', ')}');
            for (final message in relevantMessages.take(15)) {
              print('[GROUP] ${message.toString()}');
            }
            print('----------------------------');
          }
        } catch (e) {
          print('Failed to retrieve group messages: $e');
        }
        break;
        
      case 'quit':
      case 'exit':
        messageTimer?.cancel();
        print('Goodbye!');
        exit(0);
        
      default:
        print('Unknown command: $command');
        print('Type "help" for available commands.');
    }
  }
}

void _showHelp(bool hasGroupParticipants) {
  print('Available commands:');
  print('  send <@recipient> <message>     - Send a message to someone');
  if (hasGroupParticipants) {
    print('  group <message>                 - Send message to group participants');
    print('  listen-group                    - Listen for group messages');
    print('  group-messages                  - Show group conversation history');
    print('  participants                    - Show current group participants');
  }
  print('  listen                          - Listen for incoming messages');
  print('  messages                        - Show recent message history');
  print('  ping <@recipient>               - Test if atSign is reachable');
  print('  help                            - Show this help');
  print('  quit                            - Exit the application');
  print('');
  print('Examples:');
  print('  send @gary Hello there!');
  if (hasGroupParticipants) {
    print('  group Hey everyone, how are you?');
    print('  ping @alice');
  }
}