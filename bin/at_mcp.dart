import 'package:at_mcp/mcp.dart';
import 'package:at_mcp/tools/echo_tool.dart';
import 'package:at_mcp/resources/info_resource.dart';

void main(List<String> arguments) async {
  final server = McpServer(
    serverInfo: ServerInfo(
      name: 'at_mcp',
      version: '0.1.0',
    ),
  );

  server.addTool(EchoTool());
  server.addResource(InfoResource());

  await server.start();
}
