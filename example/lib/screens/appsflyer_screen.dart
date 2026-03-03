import 'package:flutter/material.dart';
import '../appsflyer_service.dart';
import '../models/appsflyer_event.dart';
import '../widgets/appsflyer_status_section.dart';
import '../widgets/appsflyer_user_id_section.dart';
import '../widgets/appsflyer_privacy_controls.dart';
import '../widgets/appsflyer_event_selection.dart';
import '../widgets/appsflyer_event_parameters_form.dart';

class AppsFlyerScreen extends StatefulWidget {
  const AppsFlyerScreen({super.key});

  @override
  State<AppsFlyerScreen> createState() => _AppsFlyerScreenState();
}

class _AppsFlyerScreenState extends State<AppsFlyerScreen> {
  bool _isInitialized = false;
  AppsFlyerEventDefinition? _selectedEvent;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final service = AppsflyerService();
    setState(() {
      _isInitialized = service.isInitialized;
    });
  }

  void _selectEvent(AppsFlyerEventDefinition event) {
    setState(() {
      _selectedEvent = event;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'AppsFlyer Event Testing',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure and test AppsFlyer events with custom parameters',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Section
                  const AppsFlyerStatusSection(),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Privacy Controls Section
                  AppsFlyerPrivacyControls(isInitialized: _isInitialized),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // User ID Section
                  AppsFlyerUserIdSection(isInitialized: _isInitialized),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  // Event Selection
                  AppsFlyerEventSelection(
                    selectedEvent: _selectedEvent,
                    onEventSelected: _selectEvent,
                    isInitialized: _isInitialized,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Event Parameters
                  if (_selectedEvent != null)
                    AppsFlyerEventParametersForm(
                      event: _selectedEvent!,
                      isInitialized: _isInitialized,
                    ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

