/// Demo credentials configuration
///
/// These are resolved from environment variables at runtime. Do NOT hardcode secrets.
/// Provide values for:
/// - DEMO_EMAIL
/// - DEMO_PASSWORD
///
/// In Dreamflow, these can be configured as dart-define values when publishing or running
/// builds. If left empty, the Demo button will show guidance instead of attempting login.
class DemoCredentialsConfig {
  static const String email = String.fromEnvironment('DEMO_EMAIL');
  static const String password = String.fromEnvironment('DEMO_PASSWORD');

  static bool get isConfigured => email.isNotEmpty && password.isNotEmpty;
}
