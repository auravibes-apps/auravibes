class const WorkspaceAgentHookConfigReview({
  required final String canonicalPath,
  required final String digest,
  required final List<WorkspaceAgentHookCommandReview> commands,
  required final List<String> sourceFiles,
});

enum WorkspaceAgentHookEvent { beforeTool, afterTool }

class const WorkspaceAgentHookCommandReview({
  required final WorkspaceAgentHookEvent event,
  required final String canonicalCommandPath,
  required final List<String> arguments,
});
