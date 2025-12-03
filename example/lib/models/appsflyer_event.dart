/// Model class for AppsFlyer events with configurable parameters
class AppsFlyerEventDefinition {
  final String eventName;
  final String description;
  final String category;
  final List<EventParameter> parameters;
  final Map<String, String> defaultValues;

  AppsFlyerEventDefinition({
    required this.eventName,
    required this.description,
    required this.category,
    required this.parameters,
    this.defaultValues = const {},
  });
}

/// Represents a configurable parameter for an event
class EventParameter {
  final String key;
  final String label;
  final String description;
  final ParameterType type;
  final bool required;
  final bool isPII;

  EventParameter({
    required this.key,
    required this.label,
    required this.description,
    this.type = ParameterType.text,
    this.required = false,
    this.isPII = false,
  });
}

enum ParameterType {
  text,
  email,
  phone,
  number,
  currency,
  date,
  boolean,
}

/// Predefined AppsFlyer events based on best practices
class AppsFlyerEvents {
  // Standard Events
  static final registration = AppsFlyerEventDefinition(
    eventName: 'af_complete_registration',
    description: 'User completes registration',
    category: 'User Lifecycle',
    parameters: [
      EventParameter(
        key: 'af_email',
        label: 'Email',
        description: 'User email address',
        type: ParameterType.email,
        isPII: true,
      ),
      EventParameter(
        key: 'af_phone',
        label: 'Phone Number',
        description: 'User phone number',
        type: ParameterType.phone,
        isPII: true,
      ),
      EventParameter(
        key: 'af_name',
        label: 'Full Name',
        description: 'User full name',
        isPII: true,
      ),
      EventParameter(
        key: 'af_registration_method',
        label: 'Registration Method',
        description: 'How user registered (e.g., email, google, apple)',
      ),
    ],
    defaultValues: {
      'af_email': 'test@example.com',
      'af_phone': '+1-555-0123',
      'af_name': 'John Doe',
      'af_registration_method': 'email',
    },
  );

  static final login = AppsFlyerEventDefinition(
    eventName: 'af_login',
    description: 'User logs in',
    category: 'User Lifecycle',
    parameters: [
      EventParameter(
        key: 'af_customer_user_id',
        label: 'Customer User ID',
        description: 'Internal user identifier',
        required: true,
      ),
      EventParameter(
        key: 'af_login_method',
        label: 'Login Method',
        description: 'Authentication method used',
      ),
    ],
    defaultValues: {
      'af_customer_user_id': 'user_12345',
      'af_login_method': 'email',
    },
  );

  static final purchase = AppsFlyerEventDefinition(
    eventName: 'af_purchase',
    description: 'User makes a purchase',
    category: 'Commerce',
    parameters: [
      EventParameter(
        key: 'af_revenue',
        label: 'Revenue',
        description: 'Purchase amount',
        type: ParameterType.currency,
        required: true,
      ),
      EventParameter(
        key: 'af_currency',
        label: 'Currency',
        description: 'Currency code (e.g., USD)',
        required: true,
      ),
      EventParameter(
        key: 'af_order_id',
        label: 'Order ID',
        description: 'Unique order identifier',
      ),
      EventParameter(
        key: 'af_email',
        label: 'Customer Email',
        description: 'Customer email address',
        type: ParameterType.email,
        isPII: true,
      ),
      EventParameter(
        key: 'af_quantity',
        label: 'Quantity',
        description: 'Number of items purchased',
        type: ParameterType.number,
      ),
    ],
    defaultValues: {
      'af_revenue': '19.99',
      'af_currency': 'USD',
      'af_order_id': 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      'af_email': 'customer@example.com',
      'af_quantity': '1',
    },
  );

  static final addPaymentInfo = AppsFlyerEventDefinition(
    eventName: 'af_add_payment_info',
    description: 'User adds payment information',
    category: 'Commerce',
    parameters: [
      EventParameter(
        key: 'af_payment_info_available',
        label: 'Payment Info Available',
        description: 'Whether payment info was successfully added',
        type: ParameterType.boolean,
      ),
      EventParameter(
        key: 'af_payment_method',
        label: 'Payment Method',
        description: 'Type of payment method (e.g., credit_card, paypal)',
      ),
    ],
    defaultValues: {
      'af_payment_info_available': 'true',
      'af_payment_method': 'credit_card',
    },
  );

  static final contentView = AppsFlyerEventDefinition(
    eventName: 'af_content_view',
    description: 'User views content',
    category: 'Engagement',
    parameters: [
      EventParameter(
        key: 'af_content_id',
        label: 'Content ID',
        description: 'Unique content identifier',
        required: true,
      ),
      EventParameter(
        key: 'af_content_type',
        label: 'Content Type',
        description: 'Type of content (e.g., article, video, product)',
        required: true,
      ),
      EventParameter(
        key: 'af_content_name',
        label: 'Content Name',
        description: 'Human-readable content name',
      ),
    ],
    defaultValues: {
      'af_content_id': 'content_123',
      'af_content_type': 'article',
      'af_content_name': 'Sample Article Title',
    },
  );

  static final travelBooking = AppsFlyerEventDefinition(
    eventName: 'af_travel_booking',
    description: 'User books travel with geolocation',
    category: 'Travel',
    parameters: [
      EventParameter(
        key: 'af_revenue',
        label: 'Revenue',
        description: 'Booking amount',
        type: ParameterType.currency,
        required: true,
      ),
      EventParameter(
        key: 'af_currency',
        label: 'Currency',
        description: 'Currency code',
        required: true,
      ),
      EventParameter(
        key: 'af_origin_city',
        label: 'Origin City',
        description: 'Departure city',
      ),
      EventParameter(
        key: 'af_origin_country',
        label: 'Origin Country',
        description: 'Departure country',
      ),
      EventParameter(
        key: 'af_origin_latitude',
        label: 'Origin Latitude',
        description: 'Departure location latitude',
      ),
      EventParameter(
        key: 'af_origin_longitude',
        label: 'Origin Longitude',
        description: 'Departure location longitude',
      ),
      EventParameter(
        key: 'af_destination_city',
        label: 'Destination City',
        description: 'Arrival city',
      ),
      EventParameter(
        key: 'af_destination_country',
        label: 'Destination Country',
        description: 'Arrival country',
      ),
      EventParameter(
        key: 'af_destination_latitude',
        label: 'Destination Latitude',
        description: 'Arrival location latitude',
      ),
      EventParameter(
        key: 'af_destination_longitude',
        label: 'Destination Longitude',
        description: 'Arrival location longitude',
      ),
      EventParameter(
        key: 'af_travel_class',
        label: 'Travel Class',
        description: 'Class of service',
      ),
      EventParameter(
        key: 'af_num_travelers',
        label: 'Number of Travelers',
        description: 'Number of people traveling',
        type: ParameterType.number,
      ),
    ],
    defaultValues: {
      'af_revenue': '450.00',
      'af_currency': 'USD',
      'af_origin_city': 'San Francisco',
      'af_origin_country': 'United States',
      'af_origin_latitude': '37.7749',
      'af_origin_longitude': '-122.4194',
      'af_destination_city': 'New York',
      'af_destination_country': 'United States',
      'af_destination_latitude': '40.7128',
      'af_destination_longitude': '-74.0060',
      'af_travel_class': 'economy',
      'af_num_travelers': '2',
    },
  );

  static final profileUpdate = AppsFlyerEventDefinition(
    eventName: 'profile_update',
    description: 'User updates profile (custom event)',
    category: 'User Lifecycle',
    parameters: [
      EventParameter(
        key: 'name',
        label: 'Name',
        description: 'Updated name',
        isPII: true,
      ),
      EventParameter(
        key: 'email',
        label: 'Email',
        description: 'Updated email',
        type: ParameterType.email,
        isPII: true,
      ),
      EventParameter(
        key: 'address',
        label: 'Address',
        description: 'Updated address',
        isPII: true,
      ),
      EventParameter(
        key: 'phone',
        label: 'Phone',
        description: 'Updated phone number',
        type: ParameterType.phone,
        isPII: true,
      ),
    ],
    defaultValues: {
      'name': 'Jane Smith',
      'email': 'jane.smith@example.com',
      'address': '123 Main St, Anytown, CA 12345',
      'phone': '+1-555-9876',
    },
  );

  /// Get all predefined events
  static List<AppsFlyerEventDefinition> getAllEvents() {
    return [
      registration,
      login,
      purchase,
      addPaymentInfo,
      contentView,
      travelBooking,
      profileUpdate,
    ];
  }

  /// Get events grouped by category
  static Map<String, List<AppsFlyerEventDefinition>> getEventsByCategory() {
    final events = getAllEvents();
    final Map<String, List<AppsFlyerEventDefinition>> grouped = {};
    
    for (final event in events) {
      if (!grouped.containsKey(event.category)) {
        grouped[event.category] = [];
      }
      grouped[event.category]!.add(event);
    }
    
    return grouped;
  }
}

