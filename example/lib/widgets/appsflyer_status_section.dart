import 'package:flutter/material.dart';
import '../appsflyer_service.dart';
import 'status_card.dart';

class AppsFlyerStatusSection extends StatefulWidget {
  const AppsFlyerStatusSection({super.key});

  @override
  State<AppsFlyerStatusSection> createState() => _AppsFlyerStatusSectionState();
}

class _AppsFlyerStatusSectionState extends State<AppsFlyerStatusSection> {
  String _appsFlyerId = 'Loading...';
  bool _isInitialized = false;

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

    if (_isInitialized) {
      final id = await service.getAppsFlyerId();
      setState(() {
        _appsFlyerId = id ?? 'Not available';
      });
    } else {
      setState(() {
        _appsFlyerId = 'SDK not initialized';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SDK Status',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        StatusCard(
          title: 'Initialization',
          content: _isInitialized ? 'Initialized ✅' : 'Not Initialized ❌',
          isError: !_isInitialized,
        ),
        const SizedBox(height: 12),
        StatusCard(
          title: 'AppsFlyer Device ID',
          content: _appsFlyerId,
        ),
        const SizedBox(height: 12),
        StatusCard(
          title: 'Configuration',
          content: 'Dev Key: ${AppsflyerService().devKey.isNotEmpty ? "${AppsflyerService().devKey.substring(0, 4)}***" : "Not set"}\n'
                   'App ID: ${AppsflyerService().appId.isNotEmpty ? AppsflyerService().appId : "Not set"}',
          isMultiline: true,
        ),
      ],
    );
  }
}

