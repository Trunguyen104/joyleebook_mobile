abstract final class ApiEndpoints {
  // Gateway Direct Endpoints
  static const String healthLive = '/health/live';

  // Series Microservice (via Gateway)
  static const String series = '/api/series';
  static const String genres = '/api/genres';

  // Ratings (Community Microservice via Gateway)
  static const String ratings = '/api/ratings';
  static String seriesRating(String seriesId) => '/api/ratings/series/$seriesId';
  static String seriesMyRating(String seriesId) => '/api/ratings/series/$seriesId/my-rating';

  // Authentication Microservice (via Gateway)
  static const String authSignIn = '/api/auth/sign-in';
  static const String authSignUp = '/api/auth/sign-up';
  static const String authSignOut = '/api/auth/sign-out';

  // Notifications Microservice (via Gateway)
  static const String notificationsHealth = '/api/notifications/health';

  // Library Microservice (via Gateway)
  static const String library = '/api/library';
  static const String libraryBookmarks = '/api/library/bookmarks';
  static String libraryBookmarkStatus(String seriesId) => '/api/library/bookmarks/$seriesId/status';
  static String libraryBookmarkDelete(String seriesId) => '/api/library/bookmarks/$seriesId';

  // Chapters Microservice (via Gateway)
  static const String chapters = '/api/chapters';

  static const String profiles = '/api/profiles/me';
  static const String libraryStats = '/api/library/stats';
}
