import 'package:auravibes_app/features/chats/services/chatbot/cancellable_provider_client.dart';
import 'package:genkit/plugin.dart';
import 'package:http/http.dart' as http;

/// Keeps the upstream OpenAI model implementation and gives each generation
/// a cancellation-aware transport. The upstream plugin does not pass Genkit's
/// cancellation token to its SDK's streaming or buffered request methods.
/// The upstream plugin must create its clients inside the model action. Supply
/// a shared client through this wrapper's `httpClient` constructor parameter.
class AppOpenAIPlugin extends GenkitPlugin {
  AppOpenAIPlugin({required GenkitPlugin upstream, http.Client? httpClient})
    : _upstream = upstream,
      _httpClient = httpClient;

  final GenkitPlugin _upstream;
  final http.Client? _httpClient;

  @override
  String get name => _upstream.name;

  @override
  Future<List<Action<dynamic, dynamic, dynamic, dynamic>>> init() async => [
    for (final action in await _upstream.init()) _wrap(action),
  ];

  @override
  Action<dynamic, dynamic, dynamic, dynamic>? resolve(
    ActionType actionType,
    String name,
  ) {
    final action = _upstream.resolve(actionType, name);
    return action == null ? null : _wrap(action);
  }

  @override
  Future<List<ActionMetadata>> list() => _upstream.list();

  @override
  List<GenerateMiddlewareDef> middleware() => _upstream.middleware();

  Action<dynamic, dynamic, dynamic, dynamic> _wrap(
    Action<dynamic, dynamic, dynamic, dynamic> action,
  ) => action is Model<dynamic>
      ? Model<dynamic>(
          name: action.name,
          metadata: Map.of(action.metadata),
          customOptions: action.customOptions,
          fn: (request, context) => _generate(action, request, context),
        )
      : action;

  Future<ModelResponse> _generate(
    Model<dynamic> model,
    ModelRequest request,
    ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
  ) async {
    // Create the underlying client before entering the zone. Calling
    // http.Client() inside its own factory would recursively create wrappers.
    final transport = CancellableProviderClient(
      client: _httpClient ?? http.Client(),
      cancellation: context.cancel,
      ownsClient: _httpClient == null,
    );
    try {
      final response = await http.runWithClient(
        () => model.run(
          request,
          onChunk: context.streamingRequested ? context.sendChunk : null,
          context: context.context,
          cancel: context.cancel,
        ),
        () => transport,
      );
      return response.result;
    } finally {
      transport.close();
    }
  }
}
