import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

const List<({String title, String body})> _welcomePages = [
  (title: 'intro_flow.welcome.title', body: 'intro_flow.welcome.body'),
  (
    title: 'intro_flow.workspace_context.title',
    body: 'intro_flow.workspace_context.body',
  ),
  (title: 'intro_flow.welcome.ai_title', body: 'intro_flow.welcome.ai_body'),
];
const _chooserPage = 3;
const _pageCount = 4;
const _bodyTextSize = 16.0;
const _largeTextThreshold = 20.0;
const _compactHeightThreshold = 500.0;
const _bodyMotionDistance = 12.0;
const _headingMotionDistance = 8.0;
const _progressDotSize = 8.0;
const _navigationBottomPadding = 12.0;

class const IntroWelcomePager({
  required final Widget setup,
  required final bool canNavigate,
  required final PageController controller,
  super.key,
}) extends StatefulWidget {
  @override
  State<IntroWelcomePager> createState() => _IntroWelcomePagerState();
}

class _IntroWelcomePagerState extends State<IntroWelcomePager> {
  int _page = 0;

  PageController get _controller => widget.controller;

  bool get _reducedMotion =>
      MediaQuery.disableAnimationsOf(context) ||
      MediaQuery.accessibleNavigationOf(context);

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: widget.canNavigate
        ? {
            const SingleActivator(.arrowLeft): () => _goToPage(_page - 1),
            const SingleActivator(.arrowRight): () => _goToPage(_page + 1),
          }
        : {},
    child: Focus(child: _IntroWelcomeViewport(state: this), autofocus: true),
  );

  bool _settled(ScrollEndNotification notification) {
    if (notification.depth != 0 || !_controller.hasClients) return false;
    final page = (_controller.page ?? 0).round();
    if (page != _page) setState(() => _page = page);

    return false;
  }

  void _goToPage(int page) {
    if (!widget.canNavigate || page < 0 || page >= _pageCount) return;
    if (!_controller.hasClients ||
        _controller.position.isScrollingNotifier.value) {
      return;
    }
    _moveToPage(page);
  }

  void _moveToPage(int page) {
    if (_reducedMotion) {
      _controller.jumpToPage(page);

      return;
    }
    final _ = _controller.animateToPage(
      page,
      duration: context.auraTheme.animation.slow,
      curve: Curves.easeOutCubic,
    );
  }
}

class _IntroWelcomeViewport extends StatelessWidget {
  new({required _IntroWelcomePagerState state})
    : _child = Column(
        children: [
          Expanded(
            child: NotificationListener<ScrollEndNotification>(
              child: PageView(
                key: const Key('intro_welcome_pages'),
                controller: state._controller,
                physics: state.widget.canNavigate
                    ? null
                    : const NeverScrollableScrollPhysics(),
                children: [
                  for (var index = 0; index < _welcomePages.length; index++)
                    _IntroWelcomePage(
                      page: _welcomePages[index],
                      index: index,
                      controller: state._controller,
                      reducedMotion: state._reducedMotion,
                    ),
                  state.widget.setup,
                ],
                allowImplicitScrolling: true,
                scrollBehavior: const ScrollBehavior().copyWith(
                  dragDevices: {
                    ...const ScrollBehavior().dragDevices,
                    PointerDeviceKind.mouse,
                  },
                ),
              ),
              onNotification: state._settled,
            ),
          ),
          if (state.widget.canNavigate)
            _IntroWelcomeNavigation(
              page: state._page,
              onNavigate: state._goToPage,
            ),
        ],
      );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _IntroWelcomePage extends StatelessWidget {
  new({
    required ({String title, String body}) page,
    required int index,
    required PageController controller,
    required bool reducedMotion,
  }) : _child = LayoutBuilder(
         builder: (context, constraints) {
           final compact =
               constraints.maxHeight < _compactHeightThreshold ||
               MediaQuery.textScalerOf(context).scale(_bodyTextSize) >
                   _largeTextThreshold;

           return _IntroWelcomePageContent(
             page: page,
             index: index,
             controller: controller,
             reducedMotion: reducedMotion,
             compact: compact,
           );
         },
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class _IntroWelcomePageContent extends StatelessWidget {
  new({
    required ({String title, String body}) page,
    required int index,
    required PageController controller,
    required bool reducedMotion,
    required bool compact,
  }) : _child = SingleChildScrollView(
         padding: const EdgeInsets.all(24),
         child: Column(
           crossAxisAlignment: .stretch,
           children: [
             Semantics(
               child: _WelcomeMotion(
                 controller: controller,
                 index: index,
                 reducedMotion: reducedMotion,
                 distance: _headingMotionDistance,
                 child: AuraText(
                   child: TextLocale(page.title),
                   style: .heading4,
                 ),
               ),
               header: true,
             ),
             const SizedBox(height: 24),
             _WelcomeMotion(
               controller: controller,
               index: index,
               reducedMotion: reducedMotion,
               distance: 28,
               child: _WelcomePreview(index: index, compact: compact),
             ),
             const SizedBox(height: 24),
             _WelcomeMotion(
               controller: controller,
               index: index,
               reducedMotion: reducedMotion,
               distance: _bodyMotionDistance,
               child: AuraText(child: TextLocale(page.body)),
             ),
           ],
         ),
       );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _WelcomePreview({
  required final int index,
  required final bool compact,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: SizedBox(
        height: compact ? 104 : 156,
        child: FittedBox(
          fit: .scaleDown,
          child: SizedBox(
            width: 360,
            child: _IntroProductPreview(index: index),
          ),
        ),
      ),
    ),
  );
}

class const _WelcomeMotion({
  required final PageController controller,
  required final int index,
  required final bool reducedMotion,
  required final double distance,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => reducedMotion
      ? child
      : AnimatedBuilder(
          animation: controller,
          builder: _translate,
          child: child,
        );

  Widget _translate(BuildContext _, Widget? child) {
    final page = controller.hasClients ? controller.page ?? 0 : 0.0;
    final progress = (index - page).clamp(-1.0, 1.0);

    return Transform.translate(
      offset: .new(progress * distance, 0),
      child: Opacity(opacity: 1 - progress.abs() * 0.15, child: child),
    );
  }
}

class const _IntroProductPreview({required final int index})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraCard(
    child: Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: switch (index) {
        0 => _chatPreview,
        1 => _workspacePreview,
        _ => _providerPreview,
      },
    ),
    style: .border,
  );
}

const _chatPreview = <Widget>[
  _PreviewRow(icon: Icons.chat_bubble_outline, label: 'chat'),
  SizedBox(height: 12),
  AuraCard(child: TextLocale('intro_flow.preview.request'), style: .border),
  SizedBox(height: 12),
  _PreviewRow(icon: Icons.build_outlined, label: 'tools'),
];
const _workspacePreview = <Widget>[
  _PreviewRow(icon: Icons.workspaces_outline, label: 'project_a'),
  SizedBox(height: 12),
  Divider(),
  SizedBox(height: 12),
  _PreviewRow(icon: Icons.workspaces_outline, label: 'project_b'),
];
const _providerPreview = <Widget>[
  _PreviewRow(icon: Icons.memory_outlined, label: 'provider'),
  SizedBox(height: 12),
  _PreviewRow(icon: Icons.check_circle_outline, label: 'model'),
];

class const _PreviewRow({
  required final IconData icon,
  required final String label,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      AuraIcon(icon, tint: .primary),
      const SizedBox(width: 12),
      Expanded(child: TextLocale('intro_flow.preview.$label')),
    ],
  );
}

class _IntroWelcomeNavigation extends StatelessWidget {
  new({required int page, required ValueChanged<int> onNavigate})
    : _child = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24)
            .copyWith(bottom: _navigationBottomPadding),
        child: Column(
          children: [
            if (page < _chooserPage)
              _IntroWelcomeActions(page: page, onNavigate: onNavigate),
            Row(
              mainAxisAlignment: .center,
              children: [
                for (var index = 0; index < _pageCount; index++)
                  _IntroWelcomeDot(
                    index: index,
                    page: page,
                    onNavigate: onNavigate,
                  ),
              ],
            ),
            Semantics(
              child: AuraText(
                child: TextLocale(
                  'intro_flow.welcome.page',
                  args: ['${page + 1}', '$_pageCount'],
                ),
                style: .caption,
              ),
              liveRegion: true,
            ),
          ],
        ),
      );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _IntroWelcomeActions({
  required final int page,
  required final ValueChanged<int> onNavigate,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height:
        MediaQuery.textScalerOf(context).scale(_bodyTextSize) >
            _largeTextThreshold
        ? 176
        : 120,
    child: _IntroWelcomeButtons(page: page, onNavigate: onNavigate),
  );
}

class const _IntroWelcomeDot({
  required final int index,
  required final int page,
  required final ValueChanged<int> onNavigate,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    child: AuraIconButton.custom(
      child: _IntroProgressMarker(selected: index == page),
      onPressed: () => onNavigate(index),
      key: .new('intro_progress_$index'),
      size: .large,
      semanticLabel: 'intro_flow.welcome.page'.tr(
        args: ['${index + 1}', '$_pageCount'],
      ),
    ),
    selected: index == page,
  );
}

class _IntroWelcomeButtons extends StatelessWidget {
  new({required int page, required ValueChanged<int> onNavigate})
    : _child = Column(
        children: [
          AuraButton(
            onPressed: () => onNavigate(page + 1),
            child: TextLocale(
              page == _chooserPage - 1
                  ? 'intro_flow.welcome.start'
                  : 'intro_flow.continue',
            ),
            key: const Key('intro_welcome_next_button'),
            isFullWidth: true,
          ),
          AuraButton(
            onPressed: () => onNavigate(_chooserPage),
            child: const TextLocale('intro_flow.welcome.skip'),
            key: const Key('intro_welcome_skip_button'),
            variant: .ghost,
          ),
        ],
      );
  final Widget _child;
  @override
  Widget build(BuildContext context) => _child;
}

class const _IntroProgressMarker({required final bool selected})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: selected
          ? context.auraColors.primary
          : context.auraColors.outlineVariant,
      shape: .circle,
    ),
    child: const SizedBox.square(dimension: _progressDotSize),
  );
}
