import 'package:auravibes_app/features/chats/services/chatbot/cancellable_provider_client.dart';
import 'package:genkit/plugin.dart';
import 'package:http/http.dart' as http;

/// Keeps the upstream OpenAI model implementation and gives each generation
/// a cancellation-aware transport. The upstream plugin does not pass Genkit's
/// cancellation token to its SDK's streaming or buffered request methods.
/// The upstream plugin must create its clients inside the model action. Supply
/// a shared client through this wrapper's `httpClient` constructor parameter.
class AppOpenAIPlugin extends GenkitPlugin {
  new({required this.upstream, this.httpClient});

  final GenkitPlugin upstream;
  final http.Client? httpClient;

  @override
  String get name => upstream.name;

  @override
  Future<List<Action<dynamic, dynamic, dynamic, dynamic>>> init() async => [
    for (final action in await upstream.init()) _wrap(action),
  ];

  @override
  Action<dynamic, dynamic, dynamic, dynamic>? resolve(
    ActionType actionType,
    String name,
  ) {
    final action = upstream.resolve(actionType, name);

    return action == null ? null : _wrap(action);
  }

  @override
  Future<List<ActionMetadata<dynamic, dynamic, dynamic, dynamic>>> list() =>
      upstream.list();

  @override
  List<GenerateMiddlewareDef<dynamic>> middleware() => upstream.middleware();

  Action<dynamic, dynamic, dynamic, dynamic> _wrap(
    Action<dynamic, dynamic, dynamic, dynamic> action,
  ) => action is Model<dynamic>
      ? Model<dynamic>(
          name: action.name,
          fn: (request, context) => _generate(action, request, context),
          metadata: .of(action.metadata),
          customOptions: action.customOptions,
        )
      : action;

  Future<ModelResponse> _generate(
    Model<dynamic> model,
    ModelRequest request,
    ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
  ) async {
    final transport = _createTransport(context);
    try {
      final response = await _runModelWithTransport(
        model,
        request,
        context,
        transport,
      );

      return response.result;
    } finally {
      transport.close();
    }
  }

  CancellableProviderClient _createTransport(
    ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
  ) => CancellableProviderClient(
    // Create the underlying client before entering the zone. Calling
    // http.Client() inside its own factory would recursively create wrappers.
    client: httpClient ?? http.Client(),
    cancellation: context.cancel,
    ownsClient: httpClient == null,
  );

  Future<ModelResponse> _runModelWithTransport(
    Model<dynamic> model,
    ModelRequest request,
    ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
    CancellableProviderClient transport,
  ) => http.runWithClient(
    () => _runModel(model, request, context),
    () => transport,
  );

  Future<ModelResponse> _runModel(
    Model<dynamic> model,
    ModelRequest request,
    ActionFnArg<ModelResponseChunk, ModelRequest, void> context,
  ) => model.run(
    request,
    onChunk: context.streamingRequested ? context.sendChunk : null,
    context: context.context,
    cancel: context.cancel,
  );
}
