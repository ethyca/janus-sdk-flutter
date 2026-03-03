import 'package:flutter/material.dart';
import '../models/appsflyer_event.dart';
import '../appsflyer_service.dart';
import 'appsflyer_snackbar_helper.dart';

class AppsFlyerEventParametersForm extends StatefulWidget {
  final AppsFlyerEventDefinition event;
  final bool isInitialized;
  final Function()? onEventSent;

  const AppsFlyerEventParametersForm({
    super.key,
    required this.event,
    required this.isInitialized,
    this.onEventSent,
  });

  @override
  State<AppsFlyerEventParametersForm> createState() => _AppsFlyerEventParametersFormState();
}

class _AppsFlyerEventParametersFormState extends State<AppsFlyerEventParametersForm> {
  final Map<String, TextEditingController> _paramControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (var param in widget.event.parameters) {
      final defaultValue = widget.event.defaultValues[param.key] ?? '';
      final value = defaultValue.replaceAll(
        '\${DateTime.now().millisecondsSinceEpoch}',
        DateTime.now().millisecondsSinceEpoch.toString(),
      );
      _paramControllers[param.key] = TextEditingController(text: value);
    }
  }

  @override
  void dispose() {
    for (var controller in _paramControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _triggerEvent() async {
    // Validate required fields
    for (var param in widget.event.parameters) {
      if (param.required && (_paramControllers[param.key]?.text.trim().isEmpty ?? true)) {
        AppsFlyerSnackbarHelper.show(context, '${param.label} is required', Colors.red);
        return;
      }
    }

    try {
      final Map<String, dynamic> eventParams = {};
      for (var entry in _paramControllers.entries) {
        final value = entry.value.text.trim();
        if (value.isNotEmpty) {
          eventParams[entry.key] = value;
        }
      }

      debugPrint("Triggering ${widget.event.eventName} with params: $eventParams");
      
      final result = await AppsflyerService().sdk.logEvent(
        widget.event.eventName,
        eventParams,
      );
      
      debugPrint("Event result: $result");

      if (!mounted) return;
      AppsFlyerSnackbarHelper.show(
        context,
        'Event "${widget.event.eventName}" logged successfully',
        Colors.green,
      );

      widget.onEventSent?.call();
    } catch (e) {
      debugPrint("Event error: $e");
      if (!mounted) return;
      AppsFlyerSnackbarHelper.show(context, 'Error: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Event Parameters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...widget.event.parameters.map((param) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          param.label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (param.required)
                          const Text(
                            ' *',
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        if (param.isPII)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'PII',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      param.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _paramControllers[param.key],
                      decoration: InputDecoration(
                        hintText: param.key,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                      ),
                      keyboardType: param.type == ParameterType.number || 
                                    param.type == ParameterType.currency
                          ? TextInputType.number
                          : param.type == ParameterType.email
                              ? TextInputType.emailAddress
                              : param.type == ParameterType.phone
                                  ? TextInputType.phone
                                  : TextInputType.text,
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.isInitialized ? _triggerEvent : null,
              icon: const Icon(Icons.send),
              label: Text('Send "${widget.event.eventName}" Event'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

