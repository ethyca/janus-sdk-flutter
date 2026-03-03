import 'package:flutter/material.dart';
import '../appsflyer_service.dart';
import 'appsflyer_snackbar_helper.dart';

class AppsFlyerUserIdSection extends StatefulWidget {
  final bool isInitialized;

  const AppsFlyerUserIdSection({
    super.key,
    required this.isInitialized,
  });

  @override
  State<AppsFlyerUserIdSection> createState() => _AppsFlyerUserIdSectionState();
}

class _AppsFlyerUserIdSectionState extends State<AppsFlyerUserIdSection> {
  final _userIdController = TextEditingController();

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _setUserId() async {
    final userId = _userIdController.text.trim();
    if (userId.isEmpty) {
      AppsFlyerSnackbarHelper.show(context, 'Please enter a User ID', Colors.orange);
      return;
    }
    
    try {
      AppsflyerService().setCustomerUserId(userId);
      debugPrint("Customer User ID set to: $userId");
      
      final result = await AppsflyerService().sdk.logEvent("af_login", {
        "af_customer_user_id": userId
      });
      debugPrint("Login event result: $result");
      
      final appsFlyerId = await AppsflyerService().sdk.getAppsFlyerUID();
      debugPrint("AppsFlyer ID: $appsFlyerId");

      if (!mounted) return;
      AppsFlyerSnackbarHelper.show(
        context,
        'User ID set: $userId\nAppsFlyer ID: $appsFlyerId',
        Colors.green,
      );
    } catch (e) {
      debugPrint("Error setting user ID: $e");
      if (!mounted) return;
      AppsFlyerSnackbarHelper.show(context, 'Error: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Identification',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _userIdController,
          decoration: const InputDecoration(
            labelText: 'Customer User ID',
            hintText: 'Enter user identifier (e.g., user_123)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: widget.isInitialized ? _setUserId : null,
          icon: const Icon(Icons.login),
          label: const Text('Set User ID & Log Login'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }
}

