part of 'workspace_route.dart';

@TypedGoRoute<IntroRoute>(path: introPath)
class IntroRoute extends GoRouteData with $IntroRoute {
  const IntroRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const IntroScreen();
  }
}
