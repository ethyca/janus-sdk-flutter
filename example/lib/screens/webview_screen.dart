import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../janus_manager.dart';
import 'webview_detail_screen.dart';

class WebViewScreen extends StatelessWidget {
  const WebViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final janusManager = Provider.of<JanusManager>(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'WebView Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WebViews: ${janusManager.backgroundWebViews.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add WebView'),
                    onPressed: janusManager.isInitialized
                        ? () => janusManager.addBackgroundWebView()
                        : null,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: janusManager.backgroundWebViews.isNotEmpty
                        ? () => _showRemoveAllDialog(context, janusManager)
                        : null,
                    tooltip: 'Remove all WebViews',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          Expanded(
            child: janusManager.backgroundWebViews.isEmpty
                ? const Center(
                    child: Text(
                      'No WebViews added yet',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: janusManager.backgroundWebViews.length,
                    itemBuilder: (context, index) {
                      final webView = janusManager.backgroundWebViews[index];
                      return _buildWebViewItem(context, janusManager, webView);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebViewItem(
    BuildContext context,
    JanusManager janusManager,
    ({int id, dynamic controller, int eventCount}) webView,
  ) {
    final isExpanded = janusManager.isWebViewExpanded(id: webView.id);
    final hasEvents = webView.eventCount > 0;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          ListTile(
            title: Text('WebView #${webView.id}'),
            subtitle: Text('Events: ${webView.eventCount}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () => janusManager.toggleExpandWebView(id: webView.id),
                  tooltip: isExpanded ? 'Collapse' : 'Expand',
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => WebViewDetailScreen(webViewId: webView.id),
                      ),
                    );
                  },
                  tooltip: 'Open in fullscreen',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => janusManager.removeBackgroundWebView(id: webView.id),
                  tooltip: 'Remove WebView',
                ),
              ],
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Consent Values:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    janusManager.webViewConsent[webView.id]?.isEmpty ?? true
                        ? 'No consent values available'
                        : janusManager.webViewConsent[webView.id]!.entries
                            .map((e) => '${e.key}: ${e.value}')
                            .join('\n'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Fides String:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    janusManager.webViewFidesString[webView.id]?.isEmpty ?? true
                        ? 'No Fides string available'
                        : janusManager.webViewFidesString[webView.id]!,
                  ),
                  if (hasEvents) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Recent Events:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: janusManager.webViewEvents[webView.id]?.length ?? 0,
                        itemBuilder: (context, index) {
                          final events = janusManager.webViewEvents[webView.id]!;
                          // Show most recent events first
                          final event = events[events.length - 1 - index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Text(
                              event,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showRemoveAllDialog(BuildContext context, JanusManager janusManager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove All WebViews'),
        content: const Text(
          'Are you sure you want to remove all WebViews? This action cannot be undone.',
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
              janusManager.removeAllBackgroundWebViews();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove All'),
          ),
        ],
      ),
    );
  }
}
