import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:janus_sdk_flutter/janus_sdk_flutter.dart';
import 'package:provider/provider.dart';

import '../janus_manager.dart';

class WebViewDetailScreen extends StatefulWidget {
  final int webViewId;

  const WebViewDetailScreen({super.key, required this.webViewId});

  @override
  State<WebViewDetailScreen> createState() => _WebViewDetailScreenState();
}

class _WebViewDetailScreenState extends State<WebViewDetailScreen> {
  String? _listenerId;
  int _refreshGeneration = 0;
  Map<String, dynamic>? _pageConsent;
  Map<String, dynamic> _appConsent = {};
  String? _lastEvent;
  String? _error;

  @override
  void initState() {
    super.initState();
    _listenerId = Janus().addConsentEventListener((event) {
      if (event.eventType == JanusEventType.webviewFidesInitialized ||
          event.eventType == JanusEventType.webviewFidesUpdated) {
        if (!mounted) return;
        setState(() => _lastEvent = event.eventType.value);
        unawaited(_refresh());
      }
    });
    unawaited(_refresh());
  }

  JanusWebViewController? _controllerFor(JanusManager manager) {
    for (final entry in manager.backgroundWebViews) {
      if (entry.id == widget.webViewId) return entry.controller;
    }
    return null;
  }

  Future<void> _refresh() async {
    final generation = ++_refreshGeneration;
    final controller = _controllerFor(context.read<JanusManager>());
    if (controller == null) return;
    try {
      final raw = await controller.evaluateJavaScript(
        'window.Fides ? window.Fides.consent : null',
      );
      final page = raw == null ? null : jsonDecode(raw);
      final app = await Janus().consent;
      if (mounted && generation == _refreshGeneration) {
        setState(() {
          _pageConsent = page is Map
              ? Map<String, dynamic>.from(page)
              : null;
          _appConsent = app;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted && generation == _refreshGeneration) {
        setState(() => _error = error.toString());
      }
    }
  }

  Future<void> _toggleConsent() async {
    final values = await Janus().internalConsent;
    if (values.isEmpty) return;
    final key = values.keys.first;
    await Janus().setConsent(values: {...values, key: !values[key]!});
    await _refresh();
  }

  @override
  void dispose() {
    if (_listenerId != null) Janus().removeConsentEventListener(_listenerId!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final janusManager = context.watch<JanusManager>();
    final controller = _controllerFor(janusManager);

    return Scaffold(
      appBar: AppBar(
        title: Text('Consent WebView #${widget.webViewId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Read page and app consent',
          ),
        ],
      ),
      body: controller == null
          ? const Center(child: Text('WebView has been released'))
          : Column(
              children: [
                Expanded(child: controller.buildWidget()),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Page: ${janusManager.websiteURL}'),
                      const SizedBox(height: 8),
                      Text('App consent: $_appConsent'),
                      Text('window.Fides.consent: ${_pageConsent ?? "Waiting for FidesJS"}'),
                      Text('Last WebView event: ${_lastEvent ?? "none"}'),
                      if (_error != null) Text('Read error: $_error'),
                      ElevatedButton(
                        onPressed: _appConsent.isEmpty ? null : _toggleConsent,
                        child: const Text('Toggle first app consent notice'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
