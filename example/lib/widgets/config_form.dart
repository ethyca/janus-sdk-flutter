import 'package:flutter/material.dart';
import '../models/config_set.dart';

class ConfigForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController apiHostController;
  final TextEditingController propertyIdController;
  final TextEditingController regionController;
  final TextEditingController websiteController;

  const ConfigForm({
    super.key,
    required this.formKey,
    required this.apiHostController,
    required this.propertyIdController,
    required this.regionController,
    required this.websiteController,
  });

  @override
  State<ConfigForm> createState() => _ConfigFormState();
}

class _ConfigFormState extends State<ConfigForm> {
  String _selectedConfigSet = 'Custom';

  void _applyConfigSet(String configSetName) {
    // Find the selected config set
    final configSet = ConfigSets.sets.firstWhere(
      (set) => set.name == configSetName,
      orElse: () => ConfigSets.sets.last, // Default to Custom
    );

    // Update the text controllers
    widget.apiHostController.text = configSet.config.apiHost;
    widget.propertyIdController.text = configSet.config.propertyId ?? '';
    widget.regionController.text = configSet.config.region ?? '';
    widget.websiteController.text = configSet.config.website ?? 'https://ethyca.com';

    setState(() {
      _selectedConfigSet = configSetName;
    });
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
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: widget.propertyIdController,
            label: 'Property ID (Optional)',
            hint: 'Your Janus property ID',
            validator: null, // Property ID is optional
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: widget.regionController,
            label: 'Region (Optional)',
            hint: 'e.g., US-CA',
            validator: null,
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
              items: ConfigSets.sets.map((configSet) {
                return DropdownMenuItem<String>(
                  value: configSet.name,
                  child: Text(configSet.name),
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
        ),
      ],
    );
  }
}
