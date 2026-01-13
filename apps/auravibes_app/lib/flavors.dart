enum Flavor {
  prod,
  dev,
  beta,
}

class F {
  static late final Flavor appFlavor;

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
