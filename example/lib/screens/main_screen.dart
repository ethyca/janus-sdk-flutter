import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:janus_sdk_flutter/janus_sdk_flutter.dart';
import '../janus_manager.dart';
import '../widgets/status_card.dart';
import 'consent_screen.dart';
import 'events_screen.dart';
import 'webview_screen.dart';
import 'settings_screen.dart';
import 'appsflyer_screen.dart';
import 'iabtcf_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Widget> _screens = [
    const StatusScreen(),
    const ConsentScreen(),
    const EventsScreen(),
    const WebViewScreen(),
    const SettingsScreen(),
    const IABTCFScreen(),
    const AppsFlyerScreen(),
  ];

  static const List<Tab> _tabs = [
    Tab(icon: Icon(Icons.dashboard), text: 'Status'),
    Tab(icon: Icon(Icons.check_circle), text: 'Consent'),
    Tab(icon: Icon(Icons.event), text: 'Events'),
    Tab(icon: Icon(Icons.web), text: 'WebViews'),
    Tab(icon: Icon(Icons.settings), text: 'Settings'),
    Tab(icon: Icon(Icons.policy), text: 'IAB TCF'),
    Tab(icon: Icon(Icons.analytics), text: 'AppsFlyer'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _screens.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
      body: TabBarView(
        controller: _tabController,
        children: _screens,
      ),
      bottomNavigationBar: Material(
        color: Theme.of(context).colorScheme.surface,
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: _tabs,
        ),
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
