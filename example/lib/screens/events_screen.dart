import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../janus_manager.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final janusManager = Provider.of<JanusManager>(context);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Event Log',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Events: ${janusManager.events.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      janusManager.isListening ? Icons.pause : Icons.play_arrow,
                      color: janusManager.isListening ? Colors.green : Colors.red,
                    ),
                    onPressed: () {
                      if (janusManager.isListening) {
                        janusManager.removeEventListeners();
                      } else {
                        janusManager.addEventListeners();
                      }
                    },
                    tooltip: janusManager.isListening
                        ? 'Pause event listening'
                        : 'Resume event listening',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: janusManager.events.isNotEmpty
                        ? () => janusManager.clearEventLog()
                        : null,
                    tooltip: 'Clear event log',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          Expanded(
            child: janusManager.events.isEmpty
                ? const Center(
                    child: Text(
                      'No events recorded yet',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: janusManager.events.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      // Display events in reverse order (newest first)
                      final event = janusManager.events[janusManager.events.length - 1 - index];
                      return _buildEventItem(event);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(String event) {
    final lines = event.split('\n');
    final title = lines.first;
    final details = lines.length > 1 ? lines.sublist(1).join('\n') : null;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (details != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 8.0),
              child: Text(
                details,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
