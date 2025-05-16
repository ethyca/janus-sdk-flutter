import 'dart:async';
import 'package:flutter/material.dart';
import 'package:janus_sdk_flutter/janus_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Configuration class for Janus
class JanusConfig {
  final String apiHost;
  final String? privacyCenterHost;
  final String? propertyId;
  final String? region;
  final String? website;
  final bool autoShowExperience;

  JanusConfig({
    required this.apiHost,
    this.privacyCenterHost,
    this.propertyId,
    this.region,
    this.website,
    this.autoShowExperience = true,
  });

  // Convert config to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'apiHost': apiHost,
      'privacyCenterHost': privacyCenterHost ?? '',
      'propertyId': propertyId ?? '',
      'region': region ?? '',
      'website': website ?? '',
      'autoShowExperience': autoShowExperience,
    };
  }

  // Create config from a map (for loading from storage)
  static JanusConfig fromMap(Map<String, dynamic> map) {
    return JanusConfig(
      apiHost: map['apiHost'] ?? 'https://privacy.ethyca.com',
      privacyCenterHost: map['privacyCenterHost']?.isNotEmpty == true ? map['privacyCenterHost'] : null,
      propertyId: map['propertyId']?.isNotEmpty == true ? map['propertyId'] : null,
      region: map['region']?.isNotEmpty == true ? map['region'] : null,
      website: map['website']?.isNotEmpty == true ? map['website'] : 'https://ethyca.com',
      autoShowExperience: map['autoShowExperience'] ?? true,
    );
  }

  // Save config to SharedPreferences
  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final map = toMap();
    for (var entry in map.entries) {
      if (entry.value is bool) {
        await prefs.setBool('custom_${entry.key}', entry.value);
      } else if (entry.value is String) {
        await prefs.setString('custom_${entry.key}', entry.value);
      }
    }
  }

  // Load config from SharedPreferences
  static Future<JanusConfig> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return JanusConfig(
      apiHost: prefs.getString('custom_apiHost') ?? 'https://privacy.ethyca.com',
      privacyCenterHost: prefs.getString('custom_privacyCenterHost')?.isNotEmpty == true 
          ? prefs.getString('custom_privacyCenterHost') 
          : null,
      propertyId: prefs.getString('custom_propertyId')?.isNotEmpty == true 
          ? prefs.getString('custom_propertyId') 
          : null,
      region: prefs.getString('custom_region')?.isNotEmpty == true 
          ? prefs.getString('custom_region') 
          : null,
      website: prefs.getString('custom_website')?.isNotEmpty == true 
          ? prefs.getString('custom_website') 
          : 'https://ethyca.com',
      autoShowExperience: prefs.getBool('custom_autoShowExperience') ?? true,
    );
  }
}

// Class to track WebView events
class WebViewEventTracker {
  final dynamic webViewController;
  final int webViewId;
  final List<String> events = [];
  Map<String, bool> consentValues = {};
  String fidesString = '';
  String? listenerId;

  // Callbacks
  Function(int, int)? onEventCountChanged;
  Function(int, Map<String, bool>)? onConsentValuesChanged;
  Function(int, String)? onFidesStringChanged;

  WebViewEventTracker({
    required this.webViewController,
    required this.webViewId,
  }) {
    _setupEventListener();
  }

  void _setupEventListener() {
    listenerId = Janus().addConsentEventListener((event) {
      // Add event to the list
      final eventDescription = _formatEventDescription(event);
      events.add(eventDescription);

      // Notify listeners
      onEventCountChanged?.call(webViewId, events.length);

      // Update consent values if needed
      if (event.eventType == JanusEventType.consentUpdatedFromWebView ||
          event.eventType == JanusEventType.experienceSelectionUpdated) {
        fetchCurrentConsentValues();
      }
    });
  }

  String _formatEventDescription(JanusEvent event) {
    // Base event description
    var eventDescription = "Event: ${event.eventType}";

    // Add event data information if available
    if (event.detail != null && event.detail is Map) {
      final detail = event.detail as Map;
      if (detail.isNotEmpty) {
        final dataString = detail.entries
            .map((e) => "${e.key}: ${e.value}")
            .join(", ");
        eventDescription += "\nData: $dataString";
      }
    }

    return eventDescription;
  }

  void fetchCurrentConsentValues() async {
    try {
      // This is a simplified approach - in a real implementation,
      // you would need to communicate with the WebView to get its specific consent values
      final consent = await Janus().consent;
      consentValues = consent;
      onConsentValuesChanged?.call(webViewId, consentValues);

      final fidesStr = await Janus().fidesString;
      fidesString = fidesStr;
      onFidesStringChanged?.call(webViewId, fidesString);
    } catch (e) {
      debugPrint('Error fetching consent values: $e');
    }
  }

  void dispose() {
    if (listenerId != null) {
      Janus().removeConsentEventListener(listenerId!);
      listenerId = null;
    }
  }
}

class JanusManager extends ChangeNotifier {
  bool isInitialized = false;
  bool isInitializing = false;
  String? initializationError;
  bool isListening = false;
  String? listenerId;
  Map<String, bool> consentValues = {};
  Map<String, dynamic> consentMetadata = {};
  String fidesString = '';
  String consentMethod = '';
  List<String> events = [];
  bool hasExperience = false;
  String currentRegion = '';
  Map<String, String> ipLocationDetails = {};

  // Configuration
  JanusConfig? config;

  // WebView tracking
  List<({int id, dynamic controller, int eventCount})> backgroundWebViews = [];
  int nextWebViewId = 1;
  Map<int, WebViewEventTracker> webViewEventTrackers = {};
  Map<int, List<String>> webViewEvents = {};
  Map<int, Map<String, bool>> webViewConsent = {};
  Map<int, String> webViewFidesString = {};
  Set<int> expandedWebViews = {};
  int? selectedWebViewId;

  // Helper to get the configured website URL
  String get websiteURL => config?.website ?? 'https://ethyca.com';

  void setConfig(JanusConfig newConfig) {
    config = newConfig;
    setupJanus();
  }

  Future<void> setupJanus() async {
    if (config == null) return;

    isInitializing = true;
    isInitialized = false;
    initializationError = null;
    hasExperience = false;
    currentRegion = '';
    ipLocationDetails.clear();
    notifyListeners();

    final janusConfig = JanusConfiguration(
      apiHost: config!.apiHost,
      privacyCenterHost: config!.privacyCenterHost ?? "",
      propertyId: config!.propertyId ?? "",
      ipLocation: config!.region == null, // Only use IP location if no region is provided
      region: config!.region ?? "",
      fidesEvents: true,
      autoShowExperience: config!.autoShowExperience
    );

    try {
      final success = await Janus().initialize(janusConfig);
      isInitializing = false;
      isInitialized = success;

      if (success) {
        await refreshConsentValues();
        addEventListeners();
        hasExperience = await Janus().hasExperience;
        currentRegion = await Janus().region;
      }
    } catch (error) {
      isInitializing = false;
      initializationError = error.toString();

      // Handle specific error types if possible
      if (error is Exception) {
        debugPrint('Janus initialization error: $error');

        // Try to extract location data if available
        if (error.toString().contains('IP Location detection failed')) {
          await testIPLocationDetection();
        }
      }
    } finally {
      notifyListeners();
    }
  }

  // Store IP location details in a structured format for display
  void storeIPLocationDetails(Map<String, dynamic> location) {
    if (location.containsKey('country')) {
      ipLocationDetails['Country'] = location['country'];
    }
    if (location.containsKey('region')) {
      ipLocationDetails['Region'] = location['region'];
    }
    if (location.containsKey('location')) {
      ipLocationDetails['Location'] = location['location'];
    }
    if (location.containsKey('ip')) {
      ipLocationDetails['IP'] = location['ip'];
    }
    notifyListeners();
  }

  // Directly test the getLocationByIPAddress method
  Future<void> testIPLocationDetection() async {
    isInitializing = true;
    notifyListeners();

    try {
      final locationData = await Janus().getLocationByIPAddress();

      // Only update the ipLocationDetails, not the currentRegion
      if (locationData.isNotEmpty) {
        Map<String, String> updatedDetails = {};

        if (locationData.containsKey('country')) {
          updatedDetails['Country'] = locationData['country'];
        }
        if (locationData.containsKey('region')) {
          updatedDetails['Region'] = locationData['region'];
        }
        if (locationData.containsKey('location')) {
          updatedDetails['Location'] = locationData['location'];
        }
        if (locationData.containsKey('ip')) {
          updatedDetails['IP'] = locationData['ip'];
        }

        if (updatedDetails.isNotEmpty) {
          ipLocationDetails = updatedDetails;
        }

        // Also fetch the current region from the SDK to ensure we're displaying the correct value
        currentRegion = await Janus().region;
      }
    } catch (error) {
      initializationError = error.toString();
      debugPrint('IP Location detection error: $error');

      // Try to extract partial location data if available
      if (error.toString().contains('location data')) {
        // This is a simplified approach - in a real implementation,
        // you would need to parse the error message to extract location data
      }
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> refreshConsentValues() async {
    consentValues = await Janus().consent;
    consentMetadata = await Janus().consentMetadata;
    hasExperience = await Janus().hasExperience;
    fidesString = await Janus().fidesString;
    consentMethod = consentMetadata['consentMethod'] ?? '';
    notifyListeners();
  }

  Future<void> showPrivacyExperience() async {
    await Janus().showExperience();
  }

  void addEventListeners() {
    // Set hasExperience value
    Janus().hasExperience.then((value) {
      hasExperience = value;
      notifyListeners();
    });

    listenerId = Janus().addConsentEventListener((event) {
      // Base event description
      var eventDescription = "Event: ${event.eventType}";

      // Add event data information if available
      if (event.detail != null && event.detail is Map) {
        final detail = event.detail as Map;
        if (detail.isNotEmpty) {
          final dataString = detail.entries
              .map((e) => "${e.key}: ${e.value}")
              .join(", ");
          eventDescription += "\nData: $dataString";
        }
      }

      events.add(eventDescription);

      // Refresh consent values for certain events
      if (event.eventType == JanusEventType.consentUpdatedFromWebView ||
          event.eventType == JanusEventType.experienceSelectionUpdated) {
        refreshConsentValues();
      }

      notifyListeners();
    });

    isListening = listenerId != null;
    notifyListeners();
  }

  void removeEventListeners() {
    if (listenerId != null) {
      Janus().removeConsentEventListener(listenerId!);
      listenerId = null;
      isListening = false;
      notifyListeners();
    }
  }

  void clearEventLog() {
    events.clear();
    notifyListeners();
  }

  Future<void> clearConsent({bool clearMetadata = false}) async {
    // Clear Janus SDK storage
    await Janus().clearConsent(clearMetadata: clearMetadata);

    // Reset consent values
    consentValues.clear();
    fidesString = '';

    // Refresh values
    await refreshConsentValues();

    notifyListeners();
  }

  Future<void> clearLocalStorage() async {
    // Clear Janus SDK storage
    await Janus().clearConsent(clearMetadata: true);

    // Reset consent values
    consentValues.clear();
    fidesString = '';

    // Clear events
    events.clear();

    // Clear WebView events
    webViewEvents.clear();

    // Clear WebView consent
    webViewConsent.clear();

    notifyListeners();
  }

  // Add a background WebView to the manager
  Future<void> addBackgroundWebView({bool autoSyncOnStart = true}) async {
    final webViewController = await Janus().createConsentWebView(
      autoSyncOnStart: autoSyncOnStart
    );

    // Create webview entry with unique ID
    final webViewId = nextWebViewId;
    nextWebViewId++;

    // Create a tuple with the WebView and initial event count
    final webViewEntry = (
      id: webViewId,
      controller: webViewController,
      eventCount: 0
    );
    backgroundWebViews.add(webViewEntry);

    // Initialize empty event array for this WebView
    webViewEvents[webViewId] = [];

    // Initialize empty consent values for this WebView
    webViewConsent[webViewId] = {};

    // Initialize empty fides_string for this WebView
    webViewFidesString[webViewId] = '';

    // Create and store a tracker for this WebView
    final tracker = WebViewEventTracker(
      webViewController: webViewController,
      webViewId: webViewId,
    );

    // Set callbacks
    tracker.onEventCountChanged = (id, count) {
      updateWebViewEventCount(id: id, count: count);
      if (webViewEventTrackers[id]?.events != null) {
        webViewEvents[id] = webViewEventTrackers[id]!.events;
        notifyListeners();
      }
    };

    tracker.onConsentValuesChanged = (id, consent) {
      webViewConsent[id] = consent;
      notifyListeners();
    };

    tracker.onFidesStringChanged = (id, fidesString) {
      webViewFidesString[id] = fidesString;
      notifyListeners();
    };

    webViewEventTrackers[webViewId] = tracker;

    // Load the configured website
    await webViewController.loadUrl(websiteURL);

    notifyListeners();
  }

  // Remove a background WebView by ID
  Future<void> removeBackgroundWebView({required int id}) async {
    final index = backgroundWebViews.indexWhere((entry) => entry.id == id);

    if (index >= 0 && index < backgroundWebViews.length) {
      // Get the WebView to release
      final webViewController = backgroundWebViews[index].controller;

      // Remove from our managed array
      backgroundWebViews.removeAt(index);

      // Remove the event tracker
      final tracker = webViewEventTrackers[id];
      if (tracker != null) {
        tracker.dispose();
        webViewEventTrackers.remove(id);
      }

      // Remove events for this WebView
      webViewEvents.remove(id);

      // Remove consent values for this WebView
      webViewConsent.remove(id);

      // Remove fides_string for this WebView
      webViewFidesString.remove(id);

      // Remove from expanded set if needed
      expandedWebViews.remove(id);

      // If this was the selected WebView, clear the selection
      if (selectedWebViewId == id) {
        selectedWebViewId = null;
      }

      // Tell Janus to release it
      await Janus().releaseConsentWebView(webViewController);

      notifyListeners();
    }
  }

  // Update the event count for a specific WebView
  void updateWebViewEventCount({required int id, required int count}) {
    final index = backgroundWebViews.indexWhere((entry) => entry.id == id);

    if (index >= 0) {
      final webView = backgroundWebViews[index];
      backgroundWebViews[index] = (
        id: webView.id,
        controller: webView.controller,
        eventCount: count
      );
      notifyListeners();
    }
  }

  // Select a WebView to view its events
  void selectWebView({required int id}) {
    selectedWebViewId = id;
    notifyListeners();
  }

  // Toggle the expanded state of a WebView
  void toggleExpandWebView({required int id}) {
    if (expandedWebViews.contains(id)) {
      expandedWebViews.remove(id);
    } else {
      expandedWebViews.add(id);
      // Fetch the latest consent values when expanding
      webViewEventTrackers[id]?.fetchCurrentConsentValues();
    }
    notifyListeners();
  }

  // Check if a WebView is expanded
  bool isWebViewExpanded({required int id}) {
    return expandedWebViews.contains(id);
  }

  // Remove all background WebViews at once
  Future<void> removeAllBackgroundWebViews() async {
    // Release all WebViews in a single pass
    for (final entry in backgroundWebViews) {
      final webViewController = entry.controller;
      // Tell Janus to release it
      await Janus().releaseConsentWebView(webViewController);
    }

    // Dispose all trackers
    for (final tracker in webViewEventTrackers.values) {
      tracker.dispose();
    }

    // Clear all data structures at once instead of one by one
    backgroundWebViews.clear();
    webViewEventTrackers.clear();
    webViewEvents.clear();
    webViewConsent.clear();
    webViewFidesString.clear();
    expandedWebViews.clear();
    selectedWebViewId = null;

    debugPrint('Removed all background WebViews and cleared associated data');
    notifyListeners();
  }

  // Update the region and reinitialize Janus
  Future<void> updateRegion({required String newRegion}) async {
    if (config == null) return;

    // Update the region
    config = JanusConfig(
      apiHost: config!.apiHost,
      privacyCenterHost: config!.privacyCenterHost,
      propertyId: config!.propertyId,
      region: newRegion.isEmpty ? null : newRegion,
      website: config!.website,
      autoShowExperience: config!.autoShowExperience,
    );

    // Clear all states immediately before reinitializing
    isInitializing = true;
    isInitialized = false;
    initializationError = null;
    hasExperience = false;
    currentRegion = newRegion;
    ipLocationDetails.clear();
    notifyListeners();

    // Reinitialize Janus with the new region
    await setupJanus();
  }

  @override
  void dispose() {
    removeEventListeners();
    removeAllBackgroundWebViews();
    super.dispose();
  }
}
