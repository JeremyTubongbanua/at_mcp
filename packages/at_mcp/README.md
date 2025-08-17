# AT MCP Server

A comprehensive MCP (Model Context Protocol) server implementation for AT Protocol development. This server provides tools and resources for managing AT Protocol virtual environments, onboarding atSigns, and facilitating AT Protocol application development.

## Features

### Virtual Environment Management
- **virtualenv_up**: Start the AT Protocol virtual environment using Docker
- **virtualenv_down**: Stop the virtual environment
- **pkam_load**: Enable PKAM authentication in the virtual environment
- **check_docker_readiness**: Test if the virtual environment is ready
- **get_virtualenv_status**: Get comprehensive status of all services

### AT Protocol Development Tools
- **download_pkam_keys**: Download PKAM keys for demo atSigns
- **get_cram_key**: Retrieve CRAM keys for onboarding
- **onboard_atsign**: Onboard an atSign using CRAM authentication
- **setup_development_atsigns**: Setup multiple atSigns for development

### Resources
- **at://demo-data**: Information about demo data, PKAM keys, and CRAM keys
- **at://virtualenv**: Virtual environment setup and configuration details

## Usage

### As an MCP Server

This server is designed to be used with MCP-compatible clients like Claude Code or other AI development tools.

```bash
# Run the MCP server
dart run bin/at_mcp.dart
```

### Integration Example

The server can help with AT Protocol development workflows:

1. **Start Virtual Environment**: Use `virtualenv_up` to start the Docker environment
2. **Setup Development atSigns**: Use `setup_development_atsigns` to prepare @gary, @xavier, etc.
3. **Develop Applications**: Build AT Protocol apps like at_talk
4. **Test Applications**: Use the virtual environment for testing

## Virtual Environment

The virtual environment provides:
- Root Server at vip.ve.atsign.zone:64 (like DNS for atSigns)
- 40 atServers with demo atSigns at ports 25000-25039
- Demo data with PKAM keys and CRAM keys
- Supervisord process management

### Available Demo atSigns
- @gary, @xavier, @alice, @bob, @charlie, @david, @eve
- And many more for testing purposes

## Library Components

### AtKeyManager
Manages PKAM keys and CRAM keys for demo atSigns:
```dart
// Download PKAM keys
await AtKeyManager.downloadPkamKeys('@gary');

// Get CRAM key for onboarding
final cramKey = AtKeyManager.getCramKey('@gary');
```

### AtOnboardingService
Handles atSign onboarding and setup:
```dart
// Onboard a single atSign
await AtOnboardingService.onboardWithCram(atSign: '@gary');

// Setup multiple atSigns for development
final results = await AtOnboardingService.setupDevelopmentAtSigns();
```

### VirtualenvManager
Manages Docker virtual environment:
```dart
// Check if virtual environment is running
final isRunning = await VirtualenvManager.isVirtualenvRunning();

// Get comprehensive status
final status = await VirtualenvManager.getVirtualenvStatus();
```

## Dependencies

- **dart_mcp**: MCP server framework
- **at_client**: AT Protocol client library
- **at_demo_data**: Demo keys and data
- **http**: HTTP client for downloading resources

## Development

```bash
# Install dependencies
dart pub get

# Run tests
dart test

# Analyze code
dart analyze

# Run the server
dart run bin/at_mcp.dart
```

## Author

Jeremy Tubongbanua
