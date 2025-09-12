import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../janus_manager.dart';
import 'home_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _regionController;
  late TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();
    final janusManager = Provider.of<JanusManager>(context, listen: false);
    _regionController = TextEditingController(text: janusManager.currentRegion);
    _websiteController = TextEditingController(
      text: janusManager.config?.website ?? 'https://ethyca.com',
    );
  }

  @override
  void dispose() {
    _regionController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final janusManager = Provider.of<JanusManager>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Region',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _regionController,
                                  decoration: const InputDecoration(
                                    hintText: 'e.g., US-CA',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  final newRegion =
                                      _regionController.text.trim();
                                  janusManager.updateRegion(
                                    newRegion: newRegion,
                                  );
                                },
                                child: const Text('Update'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Leave empty to use IP-based geolocation',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Website URL',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _websiteController,
                                  decoration: const InputDecoration(
                                    hintText: 'https://ethyca.com',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  if (janusManager.config != null) {
                                    final newConfig = JanusConfig(
                                      apiHost: janusManager.config!.apiHost,
                                      privacyCenterHost:
                                          janusManager
                                              .config!
                                              .privacyCenterHost,
                                      propertyId:
                                          janusManager.config!.propertyId,
                                      region: janusManager.config!.region,
                                      website: _websiteController.text.trim(),
                                      autoShowExperience:
                                          janusManager
                                              .config!
                                              .autoShowExperience,
                                      consentFlagType:
                                          janusManager.config!.consentFlagType,
                                    );
                                    janusManager.config = newConfig;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Website URL updated'),
                                      ),
                                    );
                                  }
                                },
                                child: const Text('Update'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'URL for WebView testing',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Storage Management',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () => janusManager.clearEventLog(),
                                child: const Text('Clear Event Log'),
                              ),
                              ElevatedButton(
                                onPressed:
                                    () => _showClearStorageDialog(
                                      context,
                                      janusManager,
                                    ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade100,
                                  foregroundColor: Colors.red.shade900,
                                ),
                                child: const Text('Clear All Storage'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Configuration',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (context) => const HomeScreen(),
                                ),
                              );
                            },
                            child: const Text('Change Configuration'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearStorageDialog(
    BuildContext context,
    JanusManager janusManager,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear All Storage'),
            content: const Text(
              'This will clear all consent values, metadata, and local storage. This action cannot be undone.',
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
                  janusManager.clearLocalStorage();
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Clear All'),
              ),
            ],
          ),
    );
  }
}
