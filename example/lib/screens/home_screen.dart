import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../janus_manager.dart';
import '../widgets/config_form.dart';
import 'main_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiHostController = TextEditingController(text: 'https://privacy.ethyca.com');
  final _propertyIdController = TextEditingController();
  final _regionController = TextEditingController();
  final _websiteController = TextEditingController(text: 'https://ethyca.com');

  @override
  void dispose() {
    _apiHostController.dispose();
    _propertyIdController.dispose();
    _regionController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _initializeJanus() {
    if (_formKey.currentState!.validate()) {
      final janusManager = Provider.of<JanusManager>(context, listen: false);

      final config = JanusConfig(
        apiHost: _apiHostController.text.trim(),
        propertyId: _propertyIdController.text.isEmpty ? null : _propertyIdController.text.trim(),
        region: _regionController.text.isEmpty ? null : _regionController.text.trim(),
        website: _websiteController.text.isEmpty ? null : _websiteController.text.trim(),
      );

      janusManager.setConfig(config);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Janus SDK Flutter Example'),
      ),
      body: Padding(
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
