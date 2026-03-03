import 'package:flutter/material.dart';
import '../appsflyer_service.dart';
import 'appsflyer_snackbar_helper.dart';

class AppsFlyerPrivacyControls extends StatefulWidget {
  final bool isInitialized;

  const AppsFlyerPrivacyControls({
    super.key,
    required this.isInitialized,
  });

  @override
  State<AppsFlyerPrivacyControls> createState() => _AppsFlyerPrivacyControlsState();
}

class _AppsFlyerPrivacyControlsState extends State<AppsFlyerPrivacyControls> {
  bool _isAnonymized = false;
  bool _isStopped = false;
  bool _disableAdIds = false;

  void _toggleAnonymize() {
    final newState = !_isAnonymized;
    try {
      AppsflyerService().anonymizeUser(newState);
      setState(() {
        _isAnonymized = newState;
      });
      AppsFlyerSnackbarHelper.show(
        context,
        'User anonymization ${newState ? "enabled" : "disabled"}',
        Colors.blue,
      );
    } catch (e) {
      AppsFlyerSnackbarHelper.show(context, 'Error: $e', Colors.red);
    }
  }

  void _toggleStop() {
    final newState = !_isStopped;
    try {
      AppsflyerService().stop(newState);
      setState(() {
        _isStopped = newState;
      });
      AppsFlyerSnackbarHelper.show(
        context,
        'SDK ${newState ? "stopped" : "started"}',
        Colors.blue,
      );
    } catch (e) {
      AppsFlyerSnackbarHelper.show(context, 'Error: $e', Colors.red);
    }
  }

  void _toggleDisableAdIds() {
    final newState = !_disableAdIds;
    try {
      AppsflyerService().disableAdvertisingIdentifiers(newState);
      setState(() {
        _disableAdIds = newState;
      });
      AppsFlyerSnackbarHelper.show(
        context,
        'Advertising IDs ${newState ? "disabled" : "enabled"}',
        Colors.blue,
      );
    } catch (e) {
      AppsFlyerSnackbarHelper.show(context, 'Error: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Privacy Controls',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Anonymize User'),
                  subtitle: const Text('Stop collecting device IDs'),
                  value: _isAnonymized,
                  onChanged: widget.isInitialized ? (_) => _toggleAnonymize() : null,
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Stop SDK'),
                  subtitle: const Text('Pause data collection'),
                  value: _isStopped,
                  onChanged: widget.isInitialized ? (_) => _toggleStop() : null,
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('Disable Ad IDs'),
                  subtitle: const Text('Don\'t collect GAID/IDFA/AAID'),
                  value: _disableAdIds,
                  onChanged: widget.isInitialized ? (_) => _toggleDisableAdIds() : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

