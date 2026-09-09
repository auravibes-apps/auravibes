enum Flavor { prod, dev, beta }

class AppFlavorConfig {
  static Flavor? _appFlavor;

  static Flavor get appFlavor =>
      _appFlavor ?? (throw StateError('appFlavor is not initialized'));

  static String get title {
    switch (appFlavor) {
      case .prod:
        return 'AuraVibes';
      case .dev:
        return 'AuraVibes Dev';
      case .beta:
        return 'AuraVibes Beta';
    }
  }

  static String get name => appFlavor.name;

  static set appFlavor(Flavor value) => _appFlavor = value;
}
