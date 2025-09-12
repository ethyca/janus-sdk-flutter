import 'package:flutter/material.dart';
import 'package:janus_sdk_flutter/janus_sdk_flutter.dart';
import '../models/config_set.dart';
import '../janus_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController apiHostController;
  final TextEditingController privacyCenterHostController;
  final TextEditingController propertyIdController;
  final TextEditingController regionController;
  final TextEditingController websiteController;
  final Function(bool)? onAutoShowExperienceChanged;
  final Function(ConsentFlagType)? onConsentFlagTypeChanged;
  final Function(ConsentNonApplicableFlagMode)?
  onConsentNonApplicableFlagModeChanged;
  final bool initialAutoShowExperience;
  final ConsentFlagType initialConsentFlagType;
  final ConsentNonApplicableFlagMode initialConsentNonApplicableFlagMode;

  const ConfigForm({
    super.key,
    required this.formKey,
    required this.apiHostController,
    required this.privacyCenterHostController,
    required this.propertyIdController,
    required this.regionController,
    required this.websiteController,
    this.onAutoShowExperienceChanged,
    this.onConsentFlagTypeChanged,
    this.onConsentNonApplicableFlagModeChanged,
    this.initialAutoShowExperience = true,
    this.initialConsentFlagType = ConsentFlagType.boolean,
    this.initialConsentNonApplicableFlagMode =
        ConsentNonApplicableFlagMode.omit,
  });

  @override
  State<ConfigForm> createState() => _ConfigFormState();
}

class _ConfigFormState extends State<ConfigForm> {
  String _selectedConfigSet = 'Custom';
  bool _isInitialized = false;
  bool _autoShowExperience = true;
  ConsentFlagType _consentFlagType = ConsentFlagType.boolean;
  ConsentNonApplicableFlagMode _consentNonApplicableFlagMode =
      ConsentNonApplicableFlagMode.omit;

  @override
  void initState() {
    super.initState();
    // Initialize with the prop values
    _autoShowExperience = widget.initialAutoShowExperience;
    _consentFlagType = widget.initialConsentFlagType;
    _consentNonApplicableFlagMode = widget.initialConsentNonApplicableFlagMode;
    // Load custom config on initialization
    _loadCustomConfig();
  }

  Future<void> _loadCustomConfig() async {
    // Load the custom config from SharedPreferences
    await ConfigSets.loadCustomConfig();

    // If this is the first initialization, apply the last used config
    if (!_isInitialized) {
      // Try to get the last selected config type from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final lastSelectedConfig =
          prefs.getString('last_selected_config') ?? 'Custom';

      setState(() {
        _selectedConfigSet = lastSelectedConfig;
        _isInitialized = true;
      });

      // Apply the configuration
      _applyConfigSet(lastSelectedConfig);
    }
  }

  Future<void> _saveLastSelectedConfig(String configName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_selected_config', configName);
  }

  void _applyConfigSet(String configSetName) {
    // Find the selected config set
    final configSet = ConfigSets.getByName(configSetName);

    // Update the text controllers
    widget.apiHostController.text = configSet.config.apiHost;
    widget.privacyCenterHostController.text =
        configSet.config.privacyCenterHost ?? '';
    widget.propertyIdController.text = configSet.config.propertyId ?? '';
    widget.regionController.text = configSet.config.region ?? '';
    widget.websiteController.text =
        configSet.config.website ?? 'https://ethyca.com';

    // Update the autoShowExperience, consentFlagType, and consentNonApplicableFlagMode values
    setState(() {
      _autoShowExperience = configSet.config.autoShowExperience;
      _consentFlagType = configSet.config.consentFlagType;
      _consentNonApplicableFlagMode =
          configSet.config.consentNonApplicableFlagMode;
    });

    // Save the selected config name
    _saveLastSelectedConfig(configSetName);

    setState(() {
      _selectedConfigSet = configSetName;
    });
  }

  // Save the custom configuration
  Future<void> _saveCustomConfig() async {
    if (_selectedConfigSet == 'Custom') {
      final config = JanusConfig(
        apiHost: widget.apiHostController.text,
        privacyCenterHost:
            widget.privacyCenterHostController.text.isEmpty
                ? null
                : widget.privacyCenterHostController.text,
        propertyId:
            widget.propertyIdController.text.isEmpty
                ? null
                : widget.propertyIdController.text,
        region:
            widget.regionController.text.isEmpty
                ? null
                : widget.regionController.text,
        website:
            widget.websiteController.text.isEmpty
                ? 'https://ethyca.com'
                : widget.websiteController.text,
        autoShowExperience: _autoShowExperience,
        consentFlagType: _consentFlagType,
        consentNonApplicableFlagMode: _consentNonApplicableFlagMode,
      );

      // Save to SharedPreferences
      await config.saveToPrefs();

      // Reload the custom config in ConfigSets
      await ConfigSets.loadCustomConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConfigSetDropdown(),
          const SizedBox(height: 24),
          _buildTextField(
            controller: widget.apiHostController,
            label: 'API Host',
            hint: 'https://privacy.ethyca.com',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an API host';
              }
              if (!value.startsWith('http')) {
                return 'API host must start with http:// or https://';
              }
              return null;
            },
            onChanged: (value) {
              if (_selectedConfigSet == 'Custom') {
                _saveCustomConfig();
              }
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: widget.privacyCenterHostController,
            label: 'Privacy Center Host',
            hint: 'https://privacy.ethyca.com',
            validator: (value) {
              if (value != null &&
                  value.isNotEmpty &&
                  !value.startsWith('http')) {
                return 'Privacy Center Host must start with http:// or https://';
              }
              return null;
            },
            onChanged: (value) {
              if (_selectedConfigSet == 'Custom') {
                _saveCustomConfig();
              }
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: widget.propertyIdController,
            label: 'Property ID (Optional)',
            hint: 'Your Janus property ID',
            validator: null, // Property ID is optional
            onChanged: (value) {
              if (_selectedConfigSet == 'Custom') {
                _saveCustomConfig();
              }
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: widget.regionController,
            label: 'Region (Optional)',
            hint: 'e.g., US-CA',
            validator: null,
            onChanged: (value) {
              if (_selectedConfigSet == 'Custom') {
                _saveCustomConfig();
              }
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Leave region empty to use IP-based geolocation',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: widget.websiteController,
            label: 'Website URL (Optional)',
            hint: 'https://ethyca.com',
            validator: (value) {
              if (value != null &&
                  value.isNotEmpty &&
                  !value.startsWith('http')) {
                return 'Website URL must start with http:// or https://';
              }
              return null;
            },
            onChanged: (value) {
              if (_selectedConfigSet == 'Custom') {
                _saveCustomConfig();
              }
            },
          ),
          const SizedBox(height: 8),
          const Text(
            'Website URL for WebView testing',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          // Direct SwitchListTile without header
          SwitchListTile(
            title: const Text('Auto-Show Experience'),
            value: _autoShowExperience,
            onChanged: (value) {
              setState(() {
                _autoShowExperience = value;
              });
              if (_selectedConfigSet == 'Custom') {
                _saveCustomConfig();
              }
              if (widget.onAutoShowExperienceChanged != null) {
                widget.onAutoShowExperienceChanged!(value);
              }
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const SizedBox(height: 24),
          _buildConsentFlagTypeDropdown(),
          const SizedBox(height: 24),
          _buildConsentNonApplicableFlagModeDropdown(),
        ],
      ),
    );
  }

  Widget _buildConfigSetDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Configuration Set',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedConfigSet,
              isExpanded: true,
              hint: const Text('Select a configuration'),
              items:
                  ConfigSets.names.map((name) {
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(name),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _applyConfigSet(value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsentFlagTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Consent Flag Type',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ConsentFlagType>(
              value: _consentFlagType,
              isExpanded: true,
              hint: const Text('Select consent flag type'),
              items:
                  ConsentFlagType.values.map((type) {
                    return DropdownMenuItem<ConsentFlagType>(
                      value: type,
                      child: Text(type.value),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _consentFlagType = value;
                  });
                  if (_selectedConfigSet == 'Custom') {
                    _saveCustomConfig();
                  }
                  if (widget.onConsentFlagTypeChanged != null) {
                    widget.onConsentFlagTypeChanged!(value);
                  }
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _consentFlagType == ConsentFlagType.boolean
              ? 'Returns consent values as boolean (true/false)'
              : 'Returns consent values as consent mechanism strings',
          style: const TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildConsentNonApplicableFlagModeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Non-Applicable Flag Mode',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ConsentNonApplicableFlagMode>(
              value: _consentNonApplicableFlagMode,
              isExpanded: true,
              hint: const Text('Select non-applicable flag mode'),
              items:
                  ConsentNonApplicableFlagMode.values.map((mode) {
                    return DropdownMenuItem<ConsentNonApplicableFlagMode>(
                      value: mode,
                      child: Text(mode.value),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _consentNonApplicableFlagMode = value;
                  });
                  if (_selectedConfigSet == 'Custom') {
                    _saveCustomConfig();
                  }
                  if (widget.onConsentNonApplicableFlagModeChanged != null) {
                    widget.onConsentNonApplicableFlagModeChanged!(value);
                  }
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _consentNonApplicableFlagMode == ConsentNonApplicableFlagMode.omit
              ? 'Non-applicable notices are omitted from consent object'
              : 'Non-applicable notices are included in consent object with appropriate values',
          style: const TextStyle(
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
