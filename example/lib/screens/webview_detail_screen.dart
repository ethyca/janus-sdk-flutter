import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../janus_manager.dart';

class WebViewDetailScreen extends StatelessWidget {
  final int webViewId;

  const WebViewDetailScreen({
    super.key,
    required this.webViewId,
  });

  @override
  Widget build(BuildContext context) {
    final janusManager = Provider.of<JanusManager>(context);

    // Find the WebView entry
    final webViewEntry = janusManager.backgroundWebViews.firstWhere(
      (entry) => entry.id == webViewId,
      orElse: () => throw Exception('WebView not found'),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('WebView #$webViewId'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              janusManager.webViewEventTrackers[webViewId]?.fetchCurrentConsentValues();
            },
            tooltip: 'Refresh consent values',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: webViewEntry.controller.buildWidget(),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Consent Values:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('Events: ${webViewEntry.eventCount}'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  janusManager.webViewConsent[webViewId]?.isEmpty ?? true
                      ? 'No consent values available'
                      : janusManager.webViewConsent[webViewId]!.entries
                          .map((e) => '${e.key}: ${e.value}')
                          .join(', '),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fides String:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  janusManager.webViewFidesString[webViewId]?.isEmpty ?? true
                      ? 'No Fides string available'
                      : janusManager.webViewFidesString[webViewId]!,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
