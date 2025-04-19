import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:janus_sdk_flutter/janus_sdk_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _status = 'Ready';
  final _janusSdkPlugin = Janus();

  @override
  void initState() {
    super.initState();
    // We could initialize the SDK here with a valid configuration
  }

  Future<void> _initializeSDK() async {
    setState(() {
      _status = 'Initializing...';
    });
    
    try {
      final result = await _janusSdkPlugin.initialize(
        JanusConfiguration(
          apiHost: "https://privacy.ethyca.com",
          webHost: "https://ethyca.com",
          propertyId: '',
          ipLocation: true
        )
      );
      
      setState(() {
        _status = result ? 'Initialized successfully' : 'Initialization failed';
      });
    } on PlatformException catch (e) {
      setState(() {
        _status = 'Error: ${e.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Janus SDK Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Status: $_status'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _initializeSDK,
                child: const Text('Initialize SDK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
