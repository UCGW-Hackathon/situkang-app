/// API endpoint path constants for all SITUKANG features.
///
/// Organized by feature domain. All paths are relative to [AppConstants.baseUrl].
class ApiEndpoints {
  ApiEndpoints._();

  // ─── Authentication ──────────────────────────────────────────────────────────

  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authResetPassword = '/auth/reset-password';

  // ─── User Profile ────────────────────────────────────────────────────────────

  static const String userProfile = '/users/me';
  static const String userAvatar = '/users/me/avatar';
  static const String userLocation = '/users/me/location';

  // ─── Home (User) ─────────────────────────────────────────────────────────────

  static const String home = '/home';

  // ─── Service Categories ──────────────────────────────────────────────────────

  static const String categories = '/categories';

  /// Returns the path for services within a category.
  static String categoryServices(String categoryId) =>
      '/categories/$categoryId/services';

  // ─── Workers ─────────────────────────────────────────────────────────────────

  static const String workersNearby = '/workers/nearby';
  static const String workersSearch = '/workers/search';

  /// Returns the path for a specific worker's detail.
  static String workerDetail(String workerId) => '/workers/$workerId';

  /// Returns the path for a specific worker's reviews.
  static String workerReviews(String workerId) =>
      '/workers/$workerId/reviews';

  /// Returns the path for a specific worker's services.
  static String workerServices(String workerId) =>
      '/workers/$workerId/services';

  // ─── Orders (User Side) ──────────────────────────────────────────────────────

  static const String orders = '/orders';

  /// Returns the path for a specific order's detail.
  static String orderDetail(String orderId) => '/orders/$orderId';

  /// Returns the path to cancel a specific order.
  static String orderCancel(String orderId) => '/orders/$orderId/cancel';

  // ─── Tracking ────────────────────────────────────────────────────────────────

  /// Returns the path for order tracking data.
  static String orderTracking(String orderId) => '/orders/$orderId/tracking';

  /// Returns the path for polling worker location (fallback).
  static String orderTrackingLocation(String orderId) =>
      '/orders/$orderId/tracking/location';

  // ─── Purchases (User Side) ───────────────────────────────────────────────────

  /// Returns the path for purchases of an order.
  static String orderPurchases(String orderId) =>
      '/orders/$orderId/purchases';

  /// Returns the path for a specific purchase detail.
  static String orderPurchaseDetail(String orderId, String purchaseId) =>
      '/orders/$orderId/purchases/$purchaseId';

  /// Returns the path to approve a purchase.
  static String purchaseApprove(String orderId, String purchaseId) =>
      '/orders/$orderId/purchases/$purchaseId/approve';

  /// Returns the path to reject a purchase.
  static String purchaseReject(String orderId, String purchaseId) =>
      '/orders/$orderId/purchases/$purchaseId/reject';

  /// Returns the path to request clarification on a purchase.
  static String purchaseClarify(String orderId, String purchaseId) =>
      '/orders/$orderId/purchases/$purchaseId/clarify';

  /// Returns the path for bulk-approving purchases.
  static String purchasesBulkApprove(String orderId) =>
      '/orders/$orderId/purchases/bulk-approve';

  // ─── Chat (User Side) ────────────────────────────────────────────────────────

  /// Returns the path for chat messages of an order.
  static String chatMessages(String orderId) =>
      '/orders/$orderId/chat/messages';

  /// Returns the path to mark chat messages as read.
  static String chatMarkRead(String orderId) =>
      '/orders/$orderId/chat/read';

  /// Chat list for user.
  static const String chatList = '/chats';

  // ─── Rating (User Side) ──────────────────────────────────────────────────────

  /// Returns the path to submit/get rating for an order.
  static String orderRating(String orderId) => '/orders/$orderId/rating';

  // ─── Invoice & Payment ───────────────────────────────────────────────────────

  /// Returns the path for an order's invoice.
  static String orderInvoice(String orderId) => '/orders/$orderId/invoice';

  /// Returns the path for confirming payment.
  static String orderPayment(String orderId) => '/orders/$orderId/payment';

  /// Returns the path for downloading invoice PDF.
  static String orderInvoicePdf(String orderId) =>
      '/orders/$orderId/invoice/pdf';

  // ─── Notifications ───────────────────────────────────────────────────────────

  static const String notifications = '/notifications';

  /// Returns the path to mark a notification as read.
  static String notificationMarkRead(String notificationId) =>
      '/notifications/$notificationId/read';

  /// Mark all notifications as read.
  static const String notificationsReadAll = '/notifications/read-all';

  // ─── Knowledge / FAQ / Articles ──────────────────────────────────────────────

  static const String knowledgeArticles = '/knowledge/articles';

  /// Returns the path for a specific article.
  static String knowledgeArticleDetail(String articleId) =>
      '/knowledge/articles/$articleId';

  static const String knowledgeFaq = '/knowledge/faq';

  // ─── Worker Profile & Verification ───────────────────────────────────────────

  static const String workerProfile = '/worker/profile';
  static const String workerCoverPhoto = '/worker/profile/cover-photo';
  static const String workerVerification = '/worker/profile/verification';

  // ─── Worker Home ─────────────────────────────────────────────────────────────

  static const String workerHome = '/worker/home';
  static const String workerAvailability = '/worker/availability';

  // ─── Worker Orders (Incoming) ────────────────────────────────────────────────

  static const String workerIncomingOrders = '/worker/orders/incoming';

  /// Returns the path for a specific incoming order detail.
  static String workerIncomingOrderDetail(String orderId) =>
      '/worker/orders/incoming/$orderId';

  /// Returns the path to accept an incoming order.
  static String workerOrderAccept(String orderId) =>
      '/worker/orders/$orderId/accept';

  /// Returns the path to reject an incoming order.
  static String workerOrderReject(String orderId) =>
      '/worker/orders/$orderId/reject';

  // ─── Worker Orders (Management) ──────────────────────────────────────────────

  static const String workerOrders = '/worker/orders';

  /// Returns the path for a specific worker order detail.
  static String workerOrderDetail(String orderId) =>
      '/worker/orders/$orderId';

  /// Returns the path to update order status.
  static String workerOrderStatus(String orderId) =>
      '/worker/orders/$orderId/status';

  /// Returns the path to generate invoice for an order.
  static String workerOrderGenerateInvoice(String orderId) =>
      '/worker/orders/$orderId/generate-invoice';

  // ─── Worker Purchases ────────────────────────────────────────────────────────

  /// Returns the path for worker purchases on an order.
  static String workerOrderPurchases(String orderId) =>
      '/worker/orders/$orderId/purchases';

  /// Returns the path for AI processing of purchase text.
  static String workerPurchaseAiProcess(String orderId) =>
      '/worker/orders/$orderId/purchases/ai-process';

  /// Returns the path for receipt OCR scanning.
  static String workerPurchaseReceiptScan(String orderId) =>
      '/worker/orders/$orderId/purchases/receipt-scan';

  /// Returns the path for a specific worker purchase.
  static String workerPurchaseDetail(String orderId, String purchaseId) =>
      '/worker/orders/$orderId/purchases/$purchaseId';

  /// Returns the path to submit a purchase for approval.
  static String workerPurchaseSubmit(String orderId, String purchaseId) =>
      '/worker/orders/$orderId/purchases/$purchaseId/submit';

  /// Returns the path for bulk-submitting purchases.
  static String workerPurchasesBulkSubmit(String orderId) =>
      '/worker/orders/$orderId/purchases/bulk-submit';

  /// Returns the path to respond to a clarification request.
  static String workerPurchaseClarifyResponse(
          String orderId, String purchaseId) =>
      '/worker/orders/$orderId/purchases/$purchaseId/clarify-response';

  // ─── Worker Chat ─────────────────────────────────────────────────────────────

  /// Returns the path for worker chat messages on an order.
  static String workerChatMessages(String orderId) =>
      '/worker/orders/$orderId/chat/messages';

  /// Returns the path to mark worker chat messages as read.
  static String workerChatMarkRead(String orderId) =>
      '/worker/orders/$orderId/chat/read';

  /// Worker chat list.
  static const String workerChatList = '/worker/chats';

  // ─── Worker Rating (Rate Customer) ───────────────────────────────────────────

  /// Returns the path to submit/get customer rating.
  static String workerCustomerRating(String orderId) =>
      '/worker/orders/$orderId/customer-rating';

  // ─── Worker History & Statistics ─────────────────────────────────────────────

  static const String workerHistory = '/worker/history';
  static const String workerStatistics = '/worker/statistics';

  // ─── Worker Wallet ───────────────────────────────────────────────────────────

  static const String workerWallet = '/worker/wallet';
  static const String workerWalletTransactions = '/worker/wallet/transactions';
  static const String workerWalletWithdraw = '/worker/wallet/withdraw';

  // ─── Worker Location ─────────────────────────────────────────────────────────

  static const String workerLocationUpdate = '/worker/location';

  // ─── WebSocket Channels ──────────────────────────────────────────────────────

  /// Returns the WebSocket URL for order tracking.
  static String wsTracking(String orderId) => '/ws/tracking/$orderId';

  /// Returns the WebSocket URL for order chat.
  static String wsChat(String orderId) => '/ws/chat/$orderId';
}
