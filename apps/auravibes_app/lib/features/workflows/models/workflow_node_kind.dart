enum WorkflowNodeKind {
  systemTool,
  agent,
  connectorTool,
  workflow,
  // Retained only to load workflow definitions saved before Connector tools.
  skill,
}
