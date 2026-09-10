enum Flavor { prod, dev, beta }

class AppFlavorConfig {
  static final instance = AppFlavorConfig._();

  AppFlavorConfig._();

  Flavor? _appFlavor;

  Flavor get appFlavor =>
      _appFlavor ?? (throw StateError('appFlavor is not initialized'));

  String get title => switch (appFlavor) {
    .prod => 'AuraVibes',
    .dev => 'AuraVibes Dev',
    .beta => 'AuraVibes Beta',
  };

  void setAppFlavor(Flavor value) {
    _appFlavor = value;
  }
}
