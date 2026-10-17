abstract final class ApiEndpoints {
  // Gateway Direct Endpoints
  static const String healthLive = '/health/live';

  // Series Microservice (via Gateway)
  static const String series = '/api/series';
  static const String genres = '/api/genres';

  // Authentication Microservice (via Gateway)
  static const String authSignIn = '/api/auth/sign-in';
  static const String authSignUp = '/api/auth/sign-up';
  static const String authSignOut = '/api/auth/sign-out';

  // Notifications Microservice (via Gateway)
  static const String notificationsHealth = '/api/notifications/health';

  // Library Microservice (via Gateway)
  static const String library = '/api/library';

  // Chapters Microservice (via Gateway)
  static const String chapters = '/api/chapters';

  static const String profiles = '/api/profiles/me';
  static const String libraryStats = '/api/library/stats';
}
