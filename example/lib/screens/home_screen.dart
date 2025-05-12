import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../janus_manager.dart';
import '../widgets/config_form.dart';
import '../models/config_set.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiHostController = TextEditingController(text: 'https://privacy.ethyca.com');
  final _privacyCenterHostController = TextEditingController();
  final _propertyIdController = TextEditingController();
  final _regionController = TextEditingController();
  final _websiteController = TextEditingController(text: 'https://ethyca.com');
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  Future<void> _initControllers() async {
    // Load custom config settings
    await ConfigSets.loadCustomConfig();
    
    // Try to get the last selected config type
    final prefs = await SharedPreferences.getInstance();
    final lastSelectedConfig = prefs.getString('last_selected_config') ?? 'Custom';
    
    // Apply the config values to controllers if it was 'Custom'
    if (lastSelectedConfig == 'Custom') {
      final customConfig = await JanusConfig.loadFromPrefs();
      _apiHostController.text = customConfig.apiHost;
      _privacyCenterHostController.text = customConfig.privacyCenterHost ?? '';
      _propertyIdController.text = customConfig.propertyId ?? '';
      _regionController.text = customConfig.region ?? '';
      _websiteController.text = customConfig.website ?? 'https://ethyca.com';
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _apiHostController.dispose();
    _privacyCenterHostController.dispose();
    _propertyIdController.dispose();
    _regionController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _initializeJanus() async {
    if (_formKey.currentState!.validate()) {
      final janusManager = Provider.of<JanusManager>(context, listen: false);
      // Store navigator reference before await operations
      final navigator = Navigator.of(context);

      // Create the configuration from form values
      final config = JanusConfig(
        apiHost: _apiHostController.text.trim(),
        privacyCenterHost: _privacyCenterHostController.text.isEmpty 
            ? null 
            : _privacyCenterHostController.text.trim(),
        propertyId: _propertyIdController.text.isEmpty 
            ? null 
            : _propertyIdController.text.trim(),
        region: _regionController.text.isEmpty 
            ? null 
            : _regionController.text.trim(),
        website: _websiteController.text.isEmpty 
            ? null 
            : _websiteController.text.trim(),
      );

      // Save custom configuration before initialization
      // Get the last selected config type
      final prefs = await SharedPreferences.getInstance();
      final lastSelectedConfig = prefs.getString('last_selected_config') ?? 'Custom';
      
      if (lastSelectedConfig == 'Custom') {
        // Save to preferences before initializing
        await config.saveToPrefs();
      }

      // Initialize Janus
      janusManager.setConfig(config);

      // Use stored navigator reference instead of context after await
      if (mounted) {
        navigator.pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Janus SDK Flutter Example'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Janus SDK Configuration',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Select a predefined configuration or customize your own',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: ConfigForm(
                    formKey: _formKey,
                    apiHostController: _apiHostController,
                    privacyCenterHostController: _privacyCenterHostController,
                    propertyIdController: _propertyIdController,
                    regionController: _regionController,
                    websiteController: _websiteController,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeJanus,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Initialize Janus SDK'),
              ),
            ],
          ),
        ),
    );
  }
}
