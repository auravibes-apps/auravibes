part of 'workspace_route.dart';

@TypedGoRoute<IntroRoute>(path: introPath)
class const IntroRoute() extends GoRouteData with $IntroRoute {
  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const IntroScreen();
  }
}
