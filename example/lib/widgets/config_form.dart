import 'package:flutter/material.dart';
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

  const ConfigForm({
    super.key,
    required this.formKey,
    required this.apiHostController,
    required this.privacyCenterHostController,
    required this.propertyIdController,
    required this.regionController,
    required this.websiteController,
  });

  @override
  State<ConfigForm> createState() => _ConfigFormState();
}

class _ConfigFormState extends State<ConfigForm> {
  String _selectedConfigSet = 'Custom';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
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
      final lastSelectedConfig = prefs.getString('last_selected_config') ?? 'Custom';
      
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
    widget.privacyCenterHostController.text = configSet.config.privacyCenterHost ?? '';
    widget.propertyIdController.text = configSet.config.propertyId ?? '';
    widget.regionController.text = configSet.config.region ?? '';
    widget.websiteController.text = configSet.config.website ?? 'https://ethyca.com';

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
        privacyCenterHost: widget.privacyCenterHostController.text.isEmpty 
            ? null 
            : widget.privacyCenterHostController.text,
        propertyId: widget.propertyIdController.text.isEmpty 
            ? null 
            : widget.propertyIdController.text,
        region: widget.regionController.text.isEmpty 
            ? null 
            : widget.regionController.text,
        website: widget.websiteController.text.isEmpty 
            ? 'https://ethyca.com' 
            : widget.websiteController.text,
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
              if (value != null && value.isNotEmpty && !value.startsWith('http')) {
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
              if (value != null && value.isNotEmpty && !value.startsWith('http')) {
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
              items: ConfigSets.names.map((name) {
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
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
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
