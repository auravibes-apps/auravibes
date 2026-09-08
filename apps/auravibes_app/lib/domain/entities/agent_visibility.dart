/// Locations where an agent can be shown.
enum AgentVisibility { chatSelector, subAgentList, both }

/// Derived visibility checks for [AgentVisibility].
extension AgentVisibilityX on AgentVisibility {
  bool get appearsInChatSelector {
    return this == AgentVisibility.chatSelector || this == AgentVisibility.both;
  }

  bool get appearsInSubAgentList {
    return this == AgentVisibility.subAgentList || this == AgentVisibility.both;
  }
}
