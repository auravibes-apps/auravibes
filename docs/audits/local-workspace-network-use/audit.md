# Local workspace network use

Audit date: 2026-10-31

Local workspaces store and execute workspace data on this device. They can
still use configured model and tool services over HTTP or OAuth. The `offline`
capability flag was not used to control requests or UI and implied a guarantee
the app did not make. It has been removed; network use remains available.

## Network-capable actions

| User action | Destination | Data sent |
| --- | --- | --- |
| Send, retry, continue, or compact a conversation | The selected model service | The model request includes the message history and system instructions. Depending on the selected model and context, it can also include supported attachment content, transcript context, and enabled tool definitions. Requests use credentials configured for the model service. |
| Generate a new conversation title | The selected model service | The first user message is sent as title-generation input. This currently runs for local conversations after the first message. |
| Run an MCP tool | The configured MCP server | The tool name and arguments are sent over the configured transport. Requests may include the configured bearer token, OAuth token, or HTTP headers. A connection test also contacts the server and requests its tool list. |
| Run a connector tool | The configured connector service | Tool inputs are rendered into the configured URL, query, headers, and body. The request may include the connection's API key, bearer token, or OAuth token. |
| Run the native URL Fetcher tool | The URL supplied to the tool | The request sends the configured URL, method, headers, and optional body; its response can be returned to the model as tool output. |
| Add or refresh a model/service connection | The selected provider, OAuth authority, or configured MCP server | Connection setup, model discovery, OAuth, and connection tests send endpoint and authorization data required by that service. They do not send conversation history unless the user starts a conversation request. |

Whether a tool runs is governed by the conversation's tool-access mode and
approval flow. The local workspace disclosure appears in the composer before
the user sends a message that can start model and tool requests. It explains
that message text and context, supported attachments, and tool inputs can leave
the device for the configured destinations; it does not block those requests.

## Source paths reviewed

- `apps/auravibes_app/lib/features/chats/services/chatbot/chatbot_service.dart`
  builds model history, transcript context, tool definitions, and title input.
- `apps/auravibes_app/lib/features/chats/usecases/send_message_usecase.dart`
  routes local conversation sends into the local agent runtime.
- `apps/auravibes_app/lib/features/service_connections/usecases/run_connector_tool_usecase.dart`
  resolves connection credentials for connector calls.
- `packages/auravibes_engine/lib/src/connectors/execution/resolve_connector_request_template.dart`
  renders connector inputs into URL, query, headers, and body.
- `apps/auravibes_app/lib/services/mcp_service/mcp_manager_client.dart` and
  `apps/auravibes_app/lib/features/service_connections/usecases/test_mcp_connection_usecase.dart`
  connect to MCP servers, discover tools, and execute calls.
- `apps/auravibes_app/lib/services/tools/native_tools/url_tool.dart` and
  `apps/auravibes_app/lib/services/url/url_service.dart` execute URL requests.
