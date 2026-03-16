import 'package:flutter/material.dart';
import 'package:janus_sdk_flutter/janus_sdk_flutter.dart';

/// Screen to display IAB TCF values stored in native SharedPreferences/UserDefaults
class IABTCFScreen extends StatefulWidget {
  const IABTCFScreen({super.key});

  @override
  State<IABTCFScreen> createState() => _IABTCFScreenState();
}

class _IABTCFScreenState extends State<IABTCFScreen> {
  Map<String, String> _iabTCFValues = {};
  bool _isLoading = true;

  // IAB TCF keys to display (per IAB TCF v2.2 Mobile Specification)
  static const List<String> _iabTCFKeys = [
    'IABTCF_CmpSdkID',
    'IABTCF_CmpSdkVersion',
    'IABTCF_PolicyVersion',
    'IABTCF_gdprApplies',
    'IABTCF_PublisherCC',
    'IABTCF_PurposeOneTreatment',
    'IABTCF_UseNonStandardTexts',
    'IABTCF_TCString',
    'IABTCF_VendorConsents',
    'IABTCF_VendorLegitimateInterests',
    'IABTCF_PurposeConsents',
    'IABTCF_PurposeLegitimateInterests',
    'IABTCF_SpecialFeaturesOptIns',
    'IABTCF_DisclosedVendors',
    'IABTCF_PublisherConsent',
    'IABTCF_PublisherLegitimateInterests',
    'IABTCF_PublisherCustomPurposesConsents',
    'IABTCF_PublisherCustomPurposesLegitimateInterests',
    'IABTCF_AddtlConsent',
  ];

  @override
  void initState() {
    super.initState();
    _loadIABTCFValues();
  }

  Future<void> _loadIABTCFValues() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the Janus SDK method channel to read from native SharedPreferences
      // (Flutter's shared_preferences uses a different file)
      final nativeValues = await Janus().getIABTCFValues();
      final values = <String, String>{};

      for (final entry in nativeValues.entries) {
        values[entry.key] = entry.value.toString();
      }

      setState(() {
        _iabTCFValues = values;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading IAB TCF values: $e')),
        );
      }
    }
  }

  String _formatValue(String value) {
    if (value.length > 50) {
      return '${value.substring(0, 47)}...';
    }
    return value;
  }

  String _formatKey(String key) {
    return key.replaceAll('IABTCF_', '');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'IAB TCF Values',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadIABTCFValues,
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Values from SharedPreferences (default)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _iabTCFValues.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No IAB TCF values found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Values will appear here after interacting\nwith a TCF consent experience',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _iabTCFKeys.length,
                        itemBuilder: (context, index) {
                          final key = _iabTCFKeys[index];
                          final value = _iabTCFValues[key];

                          if (value == null) {
                            return const SizedBox.shrink();
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      _formatKey(key),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 3,
                                    child: SelectableText(
                                      _formatValue(value),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
