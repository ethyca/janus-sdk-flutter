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

### Custom Logging

The Janus SDK supports custom logging implementations through the `JanusLogger` interface. This is useful for debugging, monitoring, and integrating with your app's existing logging infrastructure.

#### JanusLogger Interface

```dart
abstract class JanusLogger {
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    Map<String, String>? metadata,
    Exception? error,
  });
}

enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
}
```

#### Setting a Custom Logger

If you have implemented your own custom logger implementation, be sure to call setLogger() prior to initialize() in order to receive logs that occur during the initialization of the SDK.

```dart
// Set custom logger BEFORE initializing Janus
final myCustomLogger = MyCustomJanusLogger();
janusSdk.setLogger(myCustomLogger);

// Now initialize Janus - logs during initialization will use your custom logger
final config = JanusConfiguration(
  apiHost: 'https://privacy-plus.yourhost.com',
  propertyId: 'FDS-A0B1C2',
);

final success = await janusSdk.initialize(config);
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
        apiHost: 'https://privacy-plus.yourhost.com',
        privacyCenterHost: 'https://privacy-center.yourhost.com',
        propertyId: 'FDS-A0B1C2',
        ipLocation: true,
        region: 'US-CA',
        fidesEvents: true
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
  apiHost: 'https://privacy-plus.yourhost.com',             // 🌎 FidesPlus API server base URL (REQUIRED)
  privacyCenterHost: 'https://privacy-center.yourhost.com', // 🏢 Privacy Center host URL - if not provided, Janus will use the apiHost
  propertyId: 'FDS-A0B1C2',                                 // 🏢 Property identifier for this app
  ipLocation: true,                                         // 📍 Use IP-based geolocation (default true)
  region: 'US-CA',                                          // 🌎 Provide if geolocation is false or fails
  fidesEvents: true,                                        // 🔄 Map JanusEvents to FidesJS events in WebViews (default true)
  autoShowExperience: true,                                 // 🚀 Automatically show privacy experience after initialization (default true)
  saveUserPreferencesToFides: true                          // 💾 Save user preferences to Fides via privacy-preferences API (default true)
  saveNoticesServedToFides: true                            // 💾 Save notices served to Fides via notices-served API (default true)
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
final versionHash = metadata['versionHash']; // Version hash of the privacy experience used to set consent

// Get the Fides string
// (List of IAB strings like CPzHq4APzHq4AAMABBENAUEAALAAAEOAAAAAAEAEACACAAAA,1~61.70)
final fidesString = await _janusSdk.fidesString;
```

### Region and Geolocation

```dart
// Get the current region being used by the SDK
// This could be from configuration, IP geolocation, or a fallback
final region = await _janusSdk.region;
print('Current region: $region');

// Perform IP-based geolocation to determine the user's region
final locationInfo = await _janusSdk.getLocationByIPAddress();
print('Detected region: ${locationInfo['region']}');
print('Detected country: ${locationInfo['country']}');

// Example of using geolocation in a UI
FutureBuilder<Map<String, dynamic>>(
  future: _janusSdk.getLocationByIPAddress(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    }

    if (snapshot.hasError) {
      return Text('Error detecting location: ${snapshot.error}');
    }

    final locationInfo = snapshot.data ?? {};
    final region = locationInfo['region'] ?? 'Unknown';
    final country = locationInfo['country'] ?? 'Unknown';

    return Text('You appear to be in $region, $country');
  },
)
```

### WebView Integration

The Janus SDK provides a WebView controller that integrates with consent management. This allows you to create WebViews that automatically sync consent preferences with websites.

```dart
import 'package:flutter/material.dart';
import 'package:janus_sdk_flutter/janus_sdk_flutter.dart';

class ConsentWebViewPage extends StatefulWidget {
  @override
  _ConsentWebViewPageState createState() => _ConsentWebViewPageState();
}

class _ConsentWebViewPageState extends State<ConsentWebViewPage> {
  final _janusSdk = Janus();
  JanusWebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    // Create a WebView controller with consent integration
    final controller = await _janusSdk.createConsentWebView(autoSyncOnStart: true);
    setState(() {
      _webViewController = controller;
    });

    // Load a URL in the WebView
    await controller.loadUrl('https://example.com');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consent WebView')),
      body: _webViewController == null
          ? const Center(child: CircularProgressIndicator())
          : _webViewController!.buildWidget(),
    );
  }

  @override
  void dispose() {
    // IMPORTANT: Release the WebView when you're done with it
    if (_webViewController != null) {
      _janusSdk.releaseConsentWebView(_webViewController!);
    }
    super.dispose();
  }
}
```

#### Advanced WebView Usage

The `JanusWebViewController` provides access to the underlying Flutter `WebViewController` for more advanced operations:

```dart
// Access the underlying WebViewController for advanced operations
final flutterController = _webViewController!.controller;

// Execute JavaScript
await flutterController.runJavaScript('document.getElementById("consent").click()');

// Add JavaScript channels for communication between JavaScript and Dart
flutterController.addJavaScriptChannel(
  'ConsentChannel',
  onMessageReceived: (JavaScriptMessage message) {
    print('Message from JavaScript: ${message.message}');
  },
);
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
      apiHost: 'https://privacy-plus.yourhost.com',
      privacyCenterHost: 'https://privacy-center.yourhost.com',
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

  // Example of creating a WebView
  Future<void> _openWebView() async {
    final webViewController = await _janusSdk.createConsentWebView();

    // Navigate to a new screen with the WebView
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Consent WebView')),
          body: webViewController.buildWidget(),
        ),
      ),
    ).then((_) {
      // Release the WebView when the screen is popped
      _janusSdk.releaseConsentWebView(webViewController);
    });
  }

  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }
}
```

### Controlling Privacy Experience Display

By default, Janus will automatically show the privacy experience after successful initialization if `shouldShowExperience` returns true. You can control this behavior with the `autoShowExperience` configuration parameter.

#### Option 1: Automatic display (default)

```dart
// With autoShowExperience set to true (default), Janus will automatically
// show the privacy experience after initialization if shouldShowExperience is true
final config = JanusConfiguration(
  apiHost: 'https://privacy-plus.yourhost.com',
  // Other parameters...
  autoShowExperience: true // Default behavior
);
```

#### Option 2: Manual control

```dart
// Disable automatic display by setting autoShowExperience to false
final config = JanusConfiguration(
  apiHost: 'https://privacy-plus.yourhost.com',
  // Other parameters...
  autoShowExperience: false // Prevent automatic display
);

// Initialize Janus without showing the privacy experience immediately
final success = await _janusSdk.initialize(config);

if (success) {
  // You can now decide when to show the experience
  
  // Check if the experience should be shown (based on consent status, etc.)
  final shouldShow = await _janusSdk.shouldShowExperience;
  if (shouldShow) {
    // Show at the appropriate time in your app flow
    Future.delayed(const Duration(seconds: 2), () {
      _janusSdk.showExperience();
    });
  }
}
```
