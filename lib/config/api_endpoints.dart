abstract final class ApiEndpoints {
  // Gateway Direct Endpoints
  static const String healthLive = '/health/live';

  // Series Microservice (via Gateway)
  static const String series = '/api/series';
  static String seriesByAuthor(String authorId) => '$series/author/$authorId';
  static const String genres = '/api/genres';
  static const String seriesSemanticSearch = '/api/series/semantic-search';
  static String seriesSimilar(String seriesId) =>
      '/api/series/$seriesId/similar';

  // Ratings & Comments (Community Microservice via Gateway)
  static const String ratings = '/api/ratings';
  static String seriesRating(String seriesId) =>
      '/api/ratings/series/$seriesId';
  static String seriesMyRating(String seriesId) =>
      '/api/ratings/series/$seriesId/my-rating';
  static const String comments = '/api/comments';
  static String commentDetail(String commentId) => '/api/comments/$commentId';

  // Media Microservice (via Gateway)
  static const String mediaUploadAvatar = '/api/media/upload-avatar';

  // Authentication Microservice (via Gateway)
  static const String authSignIn = '/api/auth/sign-in';
  static const String authGoogle = '/api/auth/google';
  static const String authSignUp = '/api/auth/sign-up';
  static const String authSignOut = '/api/auth/sign-out';
  static const String authChangePassword = '/api/auth/me/password';
  static const String authRefresh = '/api/auth/refresh';
  static const String authForgotPassword = '/api/auth/forgot-password';
  static const String authResetPassword = '/api/auth/reset-password';
  static const String authValidateResetToken = '/api/auth/validate-reset-token';

  // Notifications Microservice (via Gateway)
  static const String notifications = '/api/notifications';
  static const String notificationsHealth = '/api/notifications/health';
  static const String notificationsHub = '/hubs/notifications';

  static String notificationsByUser(String userId) =>
      '$notifications/user/$userId';

  static String notificationSeen(String notificationId) =>
      '$notifications/$notificationId/seen';

  // Library Microservice (via Gateway)
  static const String library = '/api/library';
  static const String libraryHistory = '$library/history';
  static const String libraryProgress = '$library/progress';
  static const String libraryBookmarks = '$library/bookmarks';
  static const String libraryCompletedChapters = '$library/completed-chapters';
  static String libraryBookmarkStatus(String seriesId) =>
      '$libraryBookmarks/$seriesId/status';
  static String libraryBookmarkDelete(String seriesId) =>
      '$libraryBookmarks/$seriesId';

  // Chapters Microservice (via Gateway)
  static const String chapters = '/api/chapters';

  static const String profiles = '/api/profiles/me';
  static const String libraryStats = '/api/library/stats';

  // Payment & Donation Microservice (via Gateway)
  static const String payments = '/api/payments';
  static const String paymentsWallet = '$payments/wallet';
  static const String paymentsTransactions = '$payments/transactions';
  static const String paymentsDeposits = '$payments/deposits';
  static String paymentsDepositDetail(int orderCode) =>
      '$paymentsDeposits/$orderCode';
  static String paymentsDepositCancel(int orderCode) =>
      '$paymentsDeposits/$orderCode/cancel';
  static String paymentsTransactionStatus(int orderCode) =>
      '$paymentsTransactions/$orderCode/status';
  static const String paymentsDonate = '$payments/donate';
  static String paymentsStoryDonations(String storyId) =>
      '$payments/stories/$storyId/donations';
}
