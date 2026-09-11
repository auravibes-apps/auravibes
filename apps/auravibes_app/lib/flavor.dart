enum Flavor { prod, dev, beta }

class AppFlavorConfig {
  static final instance = AppFlavorConfig._();

  new _();

  Flavor? _appFlavor;

  Flavor get appFlavor =>
      _appFlavor ?? (throw StateError('appFlavor is not initialized'));

  String get title => titleFor(appFlavor);

  void setAppFlavor(Flavor value) => _setAppFlavor(this, value);

  static String titleFor(Flavor flavor) => switch (flavor) {
    .prod => 'AuraVibes',
    .dev => 'AuraVibes Dev',
    .beta => 'AuraVibes Beta',
  };
}

void _setAppFlavor(AppFlavorConfig config, Flavor value) =>
    config._appFlavor = value;
