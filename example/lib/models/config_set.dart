import '../janus_manager.dart';

class ConfigSet {
  final String name;
  final JanusConfig config;

  const ConfigSet({
    required this.name,
    required this.config,
  });
}

// Predefined configuration sets based on iOS example
class ConfigSets {
  static final List<ConfigSet> sets = [
    // Ethyca (default)
    ConfigSet(
      name: 'Ethyca',
      config: JanusConfig(
        apiHost: 'https://privacy.ethyca.com',
        propertyId: 'FDS-KSB4MF',
        region: null,
        website: 'https://ethyca.com',
      ),
    ),
    // Ethyca Empty
    ConfigSet(
      name: 'Ethyca (Empty)',
      config: JanusConfig(
        apiHost: 'https://privacy.ethyca.com',
        propertyId: null,
        region: null,
        website: 'https://ethyca.com',
      ),
    ),
    // Cookie House (RC)
    ConfigSet(
      name: 'Cookie House (RC)',
      config: JanusConfig(
        apiHost: 'https://privacy-plus-rc.fides-staging.ethyca.com/',
        propertyId: null,
        region: null,
        website: 'https://cookiehouse-plus-rc.fides-staging.ethyca.com',
      ),
    ),
    // Cookie House (Nightly)
    ConfigSet(
      name: 'Cookie House (Nightly)',
      config: JanusConfig(
        apiHost: 'https://privacy-plus-nightly.fides-staging.ethyca.com/',
        propertyId: null,
        region: null,
        website: 'https://cookiehouse-plus-nightly.fides-staging.ethyca.com',
      ),
    ),
    // Custom
    ConfigSet(
      name: 'Custom',
      config: JanusConfig(
        apiHost: 'https://privacy.ethyca.com',
        propertyId: '',
        region: null,
        website: 'https://ethyca.com',
      ),
    ),
  ];
}
