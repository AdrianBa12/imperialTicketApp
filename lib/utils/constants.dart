class Constants {
  // API URLs
  static const String apiBaseUrl = 'https://bus-booking-api.example.com';
  static const String apiVersion = '/api/v1';

  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String profileEndpoint = '/auth/profile';
  static const String routesEndpoint = '/routes';
  static const String busesEndpoint = '/buses';
  static const String bookingsEndpoint = '/bookings';
  static const String paymentsEndpoint = '/payments';
  static const String ticketsEndpoint = '/tickets';

  // Shared Preferences Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';
  static const String userPhoneKey = 'user_phone';

  // Payment
  static const String stripePublishableKey = 'pk_test_your_publishable_key';

  // App Constants
  static const int maxSeatsPerBooking = 6;
  static const double serviceFeePercentage = 0.05; // 5%
  static const double gstPercentage = 0.18; // 18%

  // Seat Types
  static const String seatTypeWindow = 'window';
  static const String seatTypeAisle = 'aisle';
  static const String seatTypeMiddle = 'middle';
  static const String seatTypeNormal = 'normal';
}