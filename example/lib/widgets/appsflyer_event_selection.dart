import 'package:flutter/material.dart';
import '../models/appsflyer_event.dart';

class AppsFlyerEventSelection extends StatelessWidget {
  final AppsFlyerEventDefinition? selectedEvent;
  final Function(AppsFlyerEventDefinition) onEventSelected;
  final bool isInitialized;

  const AppsFlyerEventSelection({
    super.key,
    required this.selectedEvent,
    required this.onEventSelected,
    required this.isInitialized,
  });

  @override
  Widget build(BuildContext context) {
    final eventsByCategory = AppsFlyerEvents.getEventsByCategory();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Event to Test',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...eventsByCategory.entries.map((category) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Text(
                  category.key,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              ...category.value.map((event) {
                final isSelected = selectedEvent?.eventName == event.eventName;
                return Card(
                  color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : null,
                  child: ListTile(
                    title: Text(
                      event.eventName,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                    subtitle: Text(event.description),
                    trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                    onTap: isInitialized ? () => onEventSelected(event) : null,
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }
}

