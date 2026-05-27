enum Flavor {
  prod,
  dev,
  beta,
}

class F {
  static Flavor? _appFlavor;

  static Flavor get appFlavor =>
      _appFlavor ?? (throw StateError('appFlavor is not initialized'));

  static set appFlavor(Flavor value) => _appFlavor = value;

  static String get name => appFlavor.name;

  static String get title {
    switch (appFlavor) {
      case Flavor.prod:
        return 'AuraVibes';
      case Flavor.dev:
        return 'AuraVibes Dev';
      case Flavor.beta:
        return 'AuraVibes Beta';
    }
  }
}
