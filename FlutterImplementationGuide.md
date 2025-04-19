# Janus SDK 
## Flutter Implementation Guide

### Installation

Add the Janus SDK Flutter package to your `pubspec.yaml` file:

```yaml
dependencies:
  janus_sdk_flutter:
    git:
      url: https://github.com/ethyca/janus-sdk-flutter.git
```

### Android Configuration

For Android, you need to add the Janus SDK Maven repository to your project's Gradle configuration. In your root `build.gradle` or `build.gradle.kts` file, add:

**For build.gradle:**
```groovy
allprojects {
    repositories {
        // Existing repositories (google(), mavenCentral(), etc.)
        maven {
            url 'https://ethyca.github.io/janus-sdk-android'
        }
    }
}
```

**For build.gradle.kts:**
```kotlin
allprojects {
    repositories {
        // Existing repositories (google(), mavenCentral(), etc.)
        maven {
            url = uri("https://ethyca.github.io/janus-sdk-android")
        }
    }
}
```

### Initialization

📌 Initialize the SDK in your app's startup code

Before using Janus, initialize it early in your app's lifecycle. Janus must be fully initialized before any of its functions are available for use. All code that interacts with Janus should wait for the callback from `initialize()` to complete.

### Error Handling

The SDK provides specific error handling through the Future API. It's important to handle initialization failures gracefully. For example:

- If geolocation fails, you may want to prompt the user for their region
- For network errors, provide a retry option
- With invalid configuration, check your configuration values for correctness

Here's a complete example of initialization with proper error handling:

```dart
import 'package:flutter/material.dart';
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
  final _janusSdk = Janus();
  bool _sdkInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeJanus();
  }

  Future<void> _initializeJanus() async {
    try {
      // Configure Janus
      final config = JanusConfiguration(
        apiHost: 'https://privacy-center.yourhost.com',
        propertyId: 'FDS-A0B1C2',
        ipLocation: true,
        region: 'US-CA',
        fidesEvents: true,
        webHost: 'https://yourhost.com',
      );
      
      // Initialize the SDK
      final success = await _janusSdk.initialize(config);
      
      if (success) {
        setState(() {
          _sdkInitialized = true;
          _error = null;
        });
      } else {
        setState(() {
          _sdkInitialized = false;
          _error = 'Failed to initialize Janus SDK';
        });
      }
    } catch (e) {
      setState(() {
        _sdkInitialized = false;
        _error = e.toString();
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
          child: _error != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $_error'),
                    ElevatedButton(
                      onPressed: _initializeJanus,
                      child: const Text('Retry'),
                    ),
                  ],
                )
              : _sdkInitialized
                  ? const Text('Janus SDK initialized successfully!')
                  : const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
```

📌 Sample Configuration

```dart
// Configure Janus with required credentials and settings
final config = JanusConfiguration(
  apiHost: 'https://privacy-center.yourhost.com',  // 🌎 Fides base URL
  propertyId: 'FDS-A0B1C2',                        // 🏢 Property identifier for this app
  ipLocation: true,                                // 📍 Use IP-based geolocation
  region: 'US-CA',                                 // 🌎 Provide if geolocation is false or fails
  fidesEvents: true,                               // 🔄 Map JanusEvents to FidesJS events in WebViews
  webHost: 'https://yourhost.com',                 // 🇪🇺 Required for TCF (optional for non-TCF)
);

// Initialize the SDK
final success = await janusSdk.initialize(config);
```

### Display Privacy Notice

📌 Subscribe to Consent Events

```dart
// Add a listener for consent events
String listenerId = _janusSdk.addConsentEventListener((event) {
  // Handle the event based on event.eventType
  // Additional properties may be available in event.detail
});

// Remove the listener when no longer needed
_janusSdk.removeConsentEventListener(listenerId);
```

📌 Show the Privacy Notice

```dart
// Example of conditionally showing a button based on hasExperience
FutureBuilder<bool>(
  future: _janusSdk.hasExperience,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }
    
    final hasExperience = snapshot.data ?? false;
    
    return hasExperience
        ? ElevatedButton(
            onPressed: () {
              // Show the privacy experience
              _janusSdk.showExperience();
            },
            child: const Text('Privacy Settings'),
          )
        : const SizedBox.shrink();
  },
);

// The showExperience method already checks hasExperience internally,
// so you can also call it directly:
ElevatedButton(
  onPressed: () => _janusSdk.showExperience(),
  child: const Text('Privacy Settings'),
)
```

### Check Consent Status

```dart
// Get a single consent value
final consent = await _janusSdk.consent;
final analyticsConsent = consent['analytics'] ?? false;

// Get all the user's consent choices
final allConsent = await _janusSdk.consent;

// Get metadata about the consent (creation and update timestamps)
final metadata = await _janusSdk.consentMetadata;
final createdAt = metadata['createdAt']; // ISO 8601 formatted date string
final updatedAt = metadata['updatedAt']; // ISO 8601 formatted date string
final consentMethod = metadata['consentMethod']; // How consent was provided (e.g., "explicit", "implied")

// Get the Fides string 
// (List of IAB strings like CPzHq4APzHq4AAMABBENAUEAALAAAEOAAAAAAEAEACACAAAA,1~61.70)
final fidesString = await _janusSdk.fidesString;
```

### WebView Integration

```dart
// Create a WebView with consent integration
// Note: The Flutter SDK does not provide a direct WebView widget
// Instead, it configures a native WebView underneath
await _janusSdk.createConsentWebView(autoSyncOnStart: true);

// Load a URL in the WebView (implementation may vary by platform)
// Example of handling a platform-specific WebView via platform channels

// IMPORTANT: Release the WebView when you're done with it to prevent memory leaks
// This is typically done in dispose() or when the widget is being destroyed
@override
void dispose() {
  _janusSdk.releaseConsentWebView();
  super.dispose();
}
```

⚠️ **Important:** Always call `releaseConsentWebView()` when you're done with a WebView to prevent memory leaks. WebView JavaScript interfaces require explicit cleanup, and failing to release the WebView properly can lead to resource issues.

### Complete Example

Here's a more complete example showing how to integrate Janus SDK in a Flutter app:

```dart
import 'package:flutter/material.dart';
import 'package:janus_sdk_flutter/janus_sdk_flutter.dart';

void main() {
  runApp(const PrivacyApp());
}

class PrivacyApp extends StatelessWidget {
  const PrivacyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Privacy App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _janusSdk = Janus();
  bool _initialized = false;
  String? _error;
  Map<String, bool> _consent = {};
  
  @override
  void initState() {
    super.initState();
    _initializeJanus();
  }
  
  Future<void> _initializeJanus() async {
    final config = JanusConfiguration(
      apiHost: 'https://privacy-center.yourhost.com',
      propertyId: 'FDS-A0B1C2',
      ipLocation: true,
    );
    
    try {
      final success = await _janusSdk.initialize(config);
      
      setState(() {
        _initialized = success;
        _error = success ? null : 'Failed to initialize';
      });
      
      if (success) {
        // Add listener for consent changes
        _janusSdk.addConsentEventListener((event) {
          if (event.eventType == 'consent_updated') {
            _updateConsent();
          }
        });
        
        // Load initial consent values
        _updateConsent();
      }
    } catch (e) {
      setState(() {
        _initialized = false;
        _error = e.toString();
      });
    }
  }
  
  Future<void> _updateConsent() async {
    final consent = await _janusSdk.getConsent();
    setState(() {
      _consent = consent;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Privacy App')),
        body: Center(
          child: _error != null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: $_error'),
                    ElevatedButton(
                      onPressed: _initializeJanus,
                      child: const Text('Retry'),
                    ),
                  ],
                )
              : const CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy App')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton(
            onPressed: () => _janusSdk.showExperience(),
            child: const Text('Privacy Settings'),
          ),
          
          const SizedBox(height: 20),
          const Text('Current Consent Status:', style: TextStyle(fontWeight: FontWeight.bold)),
          
          ..._consent.entries.map((entry) => ListTile(
            title: Text(entry.key),
            trailing: Icon(
              entry.value ? Icons.check_circle : Icons.cancel,
              color: entry.value ? Colors.green : Colors.red,
            ),
          )),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    // Clean up resources
    _janusSdk.releaseConsentWebView();
    super.dispose();
  }
} 