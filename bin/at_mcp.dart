import 'dart:async';
import 'dart:io' as io;

import 'package:dart_mcp/server.dart';
import 'package:dart_mcp/stdio.dart';

void main() {
  // Create the server and connect it to stdio.
  AtMCPServer(stdioChannel(input: io.stdin, output: io.stdout));
}

/// An AT Protocol MCP server with tools and resources support.
base class AtMCPServer extends MCPServer with ToolsSupport, ResourcesSupport {
  AtMCPServer(super.channel)
      : super.fromStreamChannel(
          implementation: Implementation(
            name: 'at_mcp',
            version: '0.1.0',
          ),
          instructions: 'An AT Protocol MCP server providing tools and resources for AT Protocol operations.',
        ) {
    // Register echo tool
    registerTool(echoTool, _echo);
    
    // Add info resource
    addResource(
      Resource(uri: 'at://info', name: 'AT Protocol Info'),
      (request) => ReadResourceResult(
        contents: [
          TextResourceContents(
            text: 'AT Protocol MCP Server - providing AT Protocol functionality',
            uri: request.uri,
          )
        ],
      ),
    );
  }

  /// A tool that echoes the input message.
  final echoTool = Tool(
    name: 'echo',
    description: 'Echoes the input message back to the caller',
    inputSchema: Schema.object(
      properties: {
        'message': Schema.string(description: 'The message to echo'),
      },
      required: ['message'],
    ),
  );

  /// The implementation of the `echo` tool.
  FutureOr<CallToolResult> _echo(CallToolRequest request) => CallToolResult(
        content: [
          TextContent(
            text: 'Echo: ${request.arguments!['message']}',
          ),
        ],
      );
}
