import 'tools_capability.dart';
import 'resources_capability.dart';
import 'prompts_capability.dart';
import 'logging_capability.dart';
import 'sampling_capability.dart';
import 'completions_capability.dart';

class ServerCapabilities {
  final ToolsCapability? tools;
  final ResourcesCapability? resources;
  final PromptsCapability? prompts;
  final LoggingCapability? logging;
  final SamplingCapability? sampling;
  final CompletionsCapability? completions;

  ServerCapabilities({
    this.tools,
    this.resources,
    this.prompts,
    this.logging,
    this.sampling,
    this.completions,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (tools != null) json['tools'] = tools!.toJson();
    if (resources != null) json['resources'] = resources!.toJson();
    if (prompts != null) json['prompts'] = prompts!.toJson();
    if (logging != null) json['logging'] = logging!.toJson();
    if (sampling != null) json['sampling'] = sampling!.toJson();
    if (completions != null) json['completions'] = completions!.toJson();
    return json;
  }

  factory ServerCapabilities.fromJson(Map<String, dynamic> json) {
    return ServerCapabilities(
      tools: json['tools'] != null ? ToolsCapability.fromJson(json['tools']) : null,
      resources: json['resources'] != null ? ResourcesCapability.fromJson(json['resources']) : null,
      prompts: json['prompts'] != null ? PromptsCapability.fromJson(json['prompts']) : null,
      logging: json['logging'] != null ? LoggingCapability.fromJson(json['logging']) : null,
      sampling: json['sampling'] != null ? SamplingCapability.fromJson(json['sampling']) : null,
      completions: json['completions'] != null ? CompletionsCapability.fromJson(json['completions']) : null,
    );
  }
}