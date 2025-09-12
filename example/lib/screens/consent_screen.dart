import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:janus_sdk_flutter/janus_sdk_flutter.dart';
import '../janus_manager.dart';

class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final janusManager = Provider.of<JanusManager>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Consent Values',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: 'Consent Values',
                    content:
                        janusManager.consentValues.isEmpty
                            ? 'No consent values available'
                            : _formatConsentValues(janusManager),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Consent Metadata',
                    content:
                        janusManager.consentMetadata.isEmpty
                            ? 'No consent metadata available'
                            : janusManager.consentMetadata.entries
                                .map((e) => '${e.key}: ${e.value}')
                                .join('\n'),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Fides String',
                    content:
                        janusManager.fidesString.isEmpty
                            ? 'No Fides string available'
                            : janusManager.fidesString,
                    canCopy: janusManager.fidesString.isNotEmpty,
                    onCopy:
                        () =>
                            _copyToClipboard(context, janusManager.fidesString),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Consent Method',
                    content:
                        janusManager.consentMethod.isEmpty
                            ? 'No consent method available'
                            : janusManager.consentMethod,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed:
                            janusManager.isInitialized
                                ? () => janusManager.refreshConsentValues()
                                : null,
                        child: const Text('Refresh Values'),
                      ),
                      ElevatedButton(
                        onPressed:
                            janusManager.isInitialized
                                ? () => _showClearConsentDialog(
                                  context,
                                  janusManager,
                                )
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade100,
                          foregroundColor: Colors.red.shade900,
                        ),
                        child: const Text('Clear Consent'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatConsentValues(JanusManager janusManager) {
    if (janusManager.consentValues.isEmpty) {
      return 'No consent values available';
    }

    // Check the consent flag type from the current config
    final consentFlagType =
        janusManager.config?.consentFlagType ?? ConsentFlagType.boolean;

    return janusManager.consentValues.entries
        .map((e) {
          final value = e.value;
          String displayValue;

          if (consentFlagType == ConsentFlagType.boolean) {
            // For boolean mode, show the value as-is (should be boolean)
            displayValue = value.toString();
          } else {
            // For consentMechanism mode, show the string value (e.g., "opt_in", "opt_out")
            displayValue = value.toString();
          }

          return '${e.key}: $displayValue';
        })
        .join('\n');
  }

  Widget _buildSection({
    required String title,
    required String content,
    bool canCopy = false,
    VoidCallback? onCopy,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (canCopy && onCopy != null)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: onCopy,
                    tooltip: 'Copy to clipboard',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showClearConsentDialog(
    BuildContext context,
    JanusManager janusManager,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Consent'),
            content: const Text(
              'Do you want to clear consent values only, or also clear consent metadata?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  janusManager.clearConsent();
                  Navigator.of(context).pop();
                },
                child: const Text('Clear Values Only'),
              ),
              TextButton(
                onPressed: () {
                  janusManager.clearLocalStorage();
                  Navigator.of(context).pop();
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
    );
  }
}
