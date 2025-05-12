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
  static final List<ConfigSet> _predefinedSets = [
    // Ethyca (default)
    ConfigSet(
      name: 'Ethyca',
      config: JanusConfig(
        apiHost: 'https://privacy.ethyca.com',
        privacyCenterHost: '',
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
        privacyCenterHost: '',
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
        privacyCenterHost: '',
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
        privacyCenterHost: '',
        propertyId: null,
        region: null,
        website: 'https://cookiehouse-plus-nightly.fides-staging.ethyca.com',
      ),
    ),
  ];

  // Used to store the custom config (loaded asynchronously)
  static ConfigSet? _customConfigSet;

  // Get all config sets (including custom if loaded)
  static List<ConfigSet> get sets {
    final result = List<ConfigSet>.from(_predefinedSets);
    if (_customConfigSet != null) {
      result.add(_customConfigSet!);
    } else {
      // Add a default custom config if not loaded yet
      result.add(
        ConfigSet(
          name: 'Custom',
          config: JanusConfig(
            apiHost: 'https://privacy.ethyca.com',
            privacyCenterHost: '',
            propertyId: '',
            region: null,
            website: 'https://ethyca.com',
          ),
        ),
      );
    }
    return result;
  }

  // Get just the names for dropdowns
  static List<String> get names => sets.map((set) => set.name).toList();

  // Load custom config from shared preferences
  static Future<void> loadCustomConfig() async {
    try {
      final config = await JanusConfig.loadFromPrefs();
      _customConfigSet = ConfigSet(
        name: 'Custom',
        config: config,
      );
    } catch (e) {
      // Use a default custom config on error
      _customConfigSet = ConfigSet(
        name: 'Custom',
        config: JanusConfig(
          apiHost: 'https://privacy.ethyca.com',
          privacyCenterHost: '',
          propertyId: '',
          region: null,
          website: 'https://ethyca.com',
        ),
      );
    }
  }

  // Get a specific config set by name
  static ConfigSet getByName(String name) {
    return sets.firstWhere(
      (set) => set.name == name,
      orElse: () => sets.last, // Default to Custom
    );
  }
}
