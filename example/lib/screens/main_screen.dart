import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:janus_sdk_flutter/janus_sdk_flutter.dart';
import '../janus_manager.dart';
import '../widgets/status_card.dart';
import 'consent_screen.dart';
import 'events_screen.dart';
import 'webview_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const StatusScreen(),
    const ConsentScreen(),
    const EventsScreen(),
    const WebViewScreen(),
    const SettingsScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Janus SDK Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final janusManager = Provider.of<JanusManager>(context, listen: false);
              janusManager.setupJanus();
            },
            tooltip: 'Reinitialize SDK',
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Status',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle),
            label: 'Consent',
          ),
          NavigationDestination(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.web),
            label: 'WebViews',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final janusManager = Provider.of<JanusManager>(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Janus SDK Status',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  StatusCard(
                    title: 'Initialization Status',
                    content: janusManager.isInitializing
                        ? 'Initializing...'
                        : janusManager.isInitialized
                            ? 'Initialized'
                            : 'Not Initialized',
                    isLoading: janusManager.isInitializing,
                    isError: !janusManager.isInitialized && !janusManager.isInitializing,
                    errorMessage: janusManager.initializationError,
                  ),
                  const SizedBox(height: 16),
                  StatusCard(
                    title: 'Region',
                    content: janusManager.currentRegion.isEmpty
                        ? 'Unknown'
                        : janusManager.currentRegion,
                  ),
                  const SizedBox(height: 16),
                  StatusCard(
                    title: 'IP Location Details',
                    content: janusManager.ipLocationDetails.isEmpty
                        ? 'No IP location data available'
                        : janusManager.ipLocationDetails.entries
                            .map((e) => '${e.key}: ${e.value}')
                            .join('\n'),
                    isMultiline: true,
                  ),
                  const SizedBox(height: 16),
                  StatusCard(
                    title: 'Has Experience',
                    content: janusManager.isInitializing
                        ? 'Loading...'
                        : janusManager.hasExperience ? 'Yes ✅' : 'No ❌',
                    isLoading: janusManager.isInitializing,
                  ),
                  const SizedBox(height: 16),
                  StatusCard(
                    title: 'Should Show Experience',
                    content: janusManager.isInitializing
                        ? 'Loading...'
                        : janusManager.shouldShowExperience ? 'Yes ✅' : 'No ❌',
                    isLoading: janusManager.isInitializing,
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<bool>(
                    future: Janus().isTCFExperience,
                    builder: (context, snapshot) {
                      return StatusCard(
                        title: 'Is TCF Experience',
                        content: janusManager.isInitializing
                            ? 'Loading...'
                            : snapshot.hasData
                                ? (snapshot.data! ? 'Yes ✅' : 'No ❌')
                                : 'Unknown',
                        isLoading: janusManager.isInitializing,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  StatusCard(
                    title: 'Event Listener',
                    content: janusManager.isListening ? 'Active' : 'Inactive',
                    isError: !janusManager.isListening,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: janusManager.isInitialized
                        ? () => janusManager.showPrivacyExperience()
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Show Privacy Experience'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => janusManager.testIPLocationDetection(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Test IP Location Detection'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
