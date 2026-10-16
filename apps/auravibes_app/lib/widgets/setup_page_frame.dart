import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

class const SetupPageFrame({
  required final SetupPagePresentation page,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: LayoutBuilder(
      builder: (context, constraints) =>
          _SetupPageLayout(page: page, maxHeight: constraints.maxHeight),
    ),
  );
}

class const _SetupPageLayout({
  required final SetupPagePresentation page,
  required final double maxHeight,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      Expanded(
        child: page.scrollBody
            ? SingleChildScrollView(
                child: _SetupPageContent(page: page),
                keyboardDismissBehavior: .onDrag,
              )
            : _SetupPageContent(page: page),
      ),
      if (page.onBack != null || page.actions != null) ...[
        const SizedBox(height: 16),
        _SetupPageFooter(page: page, maxHeight: maxHeight),
      ],
    ],
  );
}

/// Presentation slots for task-owned forms embedded in the setup journey.
class const SetupPagePresentation({
  required final Key key,
  required final Widget heading,
  required final Widget body,
  final Widget? description,
  final Widget? actions,
  final VoidCallback? onBack,
  final Key? backKey,
  final bool pending = false,
  final bool scrollBody = true,
});

typedef SetupPageBuilder = Widget Function(SetupPagePresentation page);

typedef SetupFormBuilder = Widget Function(Widget fields, Widget actions);

class const _SetupPageFooter({
  required final SetupPagePresentation page,
  required final double maxHeight,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: .new(maxHeight: maxHeight * 0.45),
    child: SingleChildScrollView(child: _SetupPageFooterActions(page: page)),
  );
}

class _SetupPageFooterActions extends StatelessWidget {
  new({required SetupPagePresentation page})
    : _child = Row(
        crossAxisAlignment: .start,
        children: [
          if (page.onBack case final onBack?) ...[
            AuraIconButton(
              icon: Icons.arrow_back,
              onPressed: page.pending ? null : onBack,
              key: page.backKey,
              size: .large,
              semanticLabel: 'intro_flow.back'.tr(),
              tooltip: 'intro_flow.back'.tr(),
            ),
            const SizedBox(width: 12),
          ],
          if (page.actions case final actions?) Expanded(child: actions),
        ],
      );

  final Widget _child;

  @override
  Widget build(BuildContext context) => _child;
}

class const _SetupPageContent({required final SetupPagePresentation page})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .stretch,
    children: [
      Semantics(child: page.heading, header: true),
      if (page.description case final description?) ...[
        const SizedBox(height: 12),
        description,
      ],
      const SizedBox(height: 24),
      if (page.scrollBody) page.body else Expanded(child: page.body),
    ],
  );
}
