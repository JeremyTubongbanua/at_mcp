# AT Talk

An enhanced messaging application using AT Protocol with support for individual and group chat via stdin/stdout interface.

## Features

- ✉️ Send messages between atSigns using AT Protocol
- 🏗️ Custom root server configuration 
- 🔑 Custom atKeys file support
- 👥 **Group chat functionality** - chat with multiple participants simultaneously
- 🎯 **Multi-recipient messaging** - send to multiple atSigns at once
- 📱 Interactive stdin/stdout interface
- 📜 Message history viewing
- 👂 Real-time message listening (individual and group)
- 🏓 Connectivity testing with ping command
- 🌐 Local virtual environment support

## Installation

```bash
dart pub get
```

## Usage

### Command Line Options

```bash
dart run bin/at_talk.dart [options]

Options:
  -a, --atsign         Your atSign (e.g., @xavier or @gary) [REQUIRED]
  -r, --root-server    Root server domain (default: vip.ve.atsign.zone)
  -p, --root-port      Root server port (default: 64)
  -k, --keys           Path to atKeys file for authentication
  -t, --to             Recipients for group chat (can be used multiple times)
  -h, --help           Show help
```

### Basic Usage

Start the application for @gary:
```bash
dart run bin/at_talk.dart --atsign @gary
```

Start with custom root server:
```bash
dart run bin/at_talk.dart -a @xavier -r localhost -p 64
```

### Group Chat Setup

Start a group chat with multiple participants:
```bash
dart run bin/at_talk.dart -a @xavier -t @gary -t @alice -t @bob
```

Each participant should start their own instance with the same group:
```bash
# @gary's terminal
dart run bin/at_talk.dart -a @gary -t @xavier -t @alice -t @bob

# @alice's terminal  
dart run bin/at_talk.dart -a @alice -t @xavier -t @gary -t @bob
```

### Custom Keys File

Use a specific atKeys file:
```bash
dart run bin/at_talk.dart -a @xavier -k ~/.atsign/keys/@xavier_keys.atKeys
```

### Interactive Commands

Once connected, available commands depend on your setup:

#### Basic Commands (always available)
- `send <@recipient> <message>` - Send a message to someone
- `listen` - Listen for incoming messages  
- `messages` - Show recent message history
- `ping <@recipient>` - Test if atSign is reachable
- `help` - Show available commands
- `quit` - Exit the application

#### Group Chat Commands (when -t flags used)
- `group <message>` - Send message to all group participants
- `listen-group` - Listen for group messages only
- `group-messages` - Show group conversation history
- `participants` - Show current group participants

### Examples

#### Individual Messaging
```
at_talk> send @xavier Hello there!
at_talk> ping @gary
at_talk> messages
```

#### Group Chat
```
at_talk> group Hey everyone! Meeting at 3pm today.
at_talk> participants
at_talk> group-messages
at_talk> listen-group
```

#### Testing Connectivity
```
at_talk> ping @alice
at_talk> ping @bob
```

## Testing

Run the test suite:
```bash
dart test
```

Test connection (requires virtual environment):
```bash
dart run example/test_connection.dart
```

## Virtual Environment Setup

Make sure you have the AT Protocol virtual environment running:
```bash
# Start virtual environment
docker-compose up -d

# Check if @gary and @xavier are available
# The application will automatically use localhost:64 for the root server
```

## Package Structure

- `lib/` - Core library files
  - `src/at_talk_client.dart` - AT Protocol client implementation
  - `src/message.dart` - Message data structure
- `bin/at_talk.dart` - Main executable with stdin/stdout interface
- `test/` - Test files
- `example/` - Example usage scripts