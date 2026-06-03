/// User roles within the platform.
enum UserRole {
  user,
  worker,
  admin;

  /// Returns the API string value for this role.
  String get value => name;

  /// Parses an API string value into a [UserRole].
  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.user,
    );
  }
}

/// Order lifecycle statuses.
enum OrderStatus {
  pending,
  accepted,
  onTheWay,
  arrived,
  inProgress,
  workPaused,
  completed,
  cancelled,
  rejected;

  /// Returns the API snake_case string value.
  String get value {
    switch (this) {
      case OrderStatus.onTheWay:
        return 'on_the_way';
      case OrderStatus.inProgress:
        return 'in_progress';
      case OrderStatus.workPaused:
        return 'work_paused';
      default:
        return name;
    }
  }

  /// Parses an API string value into an [OrderStatus].
  static OrderStatus fromString(String value) {
    switch (value) {
      case 'on_the_way':
        return OrderStatus.onTheWay;
      case 'in_progress':
        return OrderStatus.inProgress;
      case 'work_paused':
        return OrderStatus.workPaused;
      default:
        return OrderStatus.values.firstWhere(
          (e) => e.name == value,
          orElse: () => OrderStatus.pending,
        );
    }
  }

  /// Whether this status represents an active order (visible on tracking).
  bool get isActive => [
        OrderStatus.accepted,
        OrderStatus.onTheWay,
        OrderStatus.arrived,
        OrderStatus.inProgress,
      ].contains(this);

  /// Whether this order can be cancelled by the user.
  bool get isCancellable => [
        OrderStatus.pending,
        OrderStatus.accepted,
        OrderStatus.onTheWay,
      ].contains(this);
}

/// Order urgency levels.
enum OrderUrgency {
  normal,
  urgent;

  /// Returns the API string value.
  String get value => name;

  /// Parses an API string value into an [OrderUrgency].
  static OrderUrgency fromString(String value) {
    return OrderUrgency.values.firstWhere(
      (e) => e.name == value,
      orElse: () => OrderUrgency.normal,
    );
  }
}

/// Purchase item statuses.
enum PurchaseStatus {
  draft,
  pendingApproval,
  approved,
  rejected,
  needsClarification;

  /// Returns the API snake_case string value.
  String get value {
    switch (this) {
      case PurchaseStatus.pendingApproval:
        return 'pending_approval';
      case PurchaseStatus.needsClarification:
        return 'needs_clarification';
      default:
        return name;
    }
  }

  /// Parses an API string value into a [PurchaseStatus].
  static PurchaseStatus fromString(String value) {
    switch (value) {
      case 'pending_approval':
        return PurchaseStatus.pendingApproval;
      case 'needs_clarification':
        return PurchaseStatus.needsClarification;
      default:
        return PurchaseStatus.values.firstWhere(
          (e) => e.name == value,
          orElse: () => PurchaseStatus.draft,
        );
    }
  }

  /// Whether this purchase can be acted upon by the user (approve/reject/clarify).
  bool get isActionable => this == PurchaseStatus.pendingApproval;
}

/// Purchase item categories.
enum PurchaseCategory {
  material,
  alat,
  sparepart,
  bahanBangunan,
  biayaTambahan,
  lainnya;

  /// Returns the API snake_case string value.
  String get value {
    switch (this) {
      case PurchaseCategory.bahanBangunan:
        return 'bahan_bangunan';
      case PurchaseCategory.biayaTambahan:
        return 'biaya_tambahan';
      default:
        return name;
    }
  }

  /// Returns a human-readable label for display.
  String get label {
    switch (this) {
      case PurchaseCategory.material:
        return 'Material';
      case PurchaseCategory.alat:
        return 'Alat';
      case PurchaseCategory.sparepart:
        return 'Sparepart';
      case PurchaseCategory.bahanBangunan:
        return 'Bahan Bangunan';
      case PurchaseCategory.biayaTambahan:
        return 'Biaya Tambahan';
      case PurchaseCategory.lainnya:
        return 'Lainnya';
    }
  }

  /// Parses an API string value into a [PurchaseCategory].
  static PurchaseCategory fromString(String value) {
    switch (value) {
      case 'bahan_bangunan':
        return PurchaseCategory.bahanBangunan;
      case 'biaya_tambahan':
        return PurchaseCategory.biayaTambahan;
      default:
        return PurchaseCategory.values.firstWhere(
          (e) => e.name == value,
          orElse: () => PurchaseCategory.lainnya,
        );
    }
  }
}

/// Payment statuses.
enum PaymentStatus {
  unpaid,
  pending,
  paid,
  refunded;

  /// Returns the API string value.
  String get value => name;

  /// Parses an API string value into a [PaymentStatus].
  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentStatus.unpaid,
    );
  }
}

/// Payment methods available.
enum PaymentMethod {
  cash,
  bankTransfer,
  ewallet;

  /// Returns the API snake_case string value.
  String get value {
    switch (this) {
      case PaymentMethod.bankTransfer:
        return 'bank_transfer';
      default:
        return name;
    }
  }

  /// Returns a human-readable label for display.
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Tunai';
      case PaymentMethod.bankTransfer:
        return 'Transfer Bank';
      case PaymentMethod.ewallet:
        return 'E-Wallet';
    }
  }

  /// Parses an API string value into a [PaymentMethod].
  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'bank_transfer':
        return PaymentMethod.bankTransfer;
      default:
        return PaymentMethod.values.firstWhere(
          (e) => e.name == value,
          orElse: () => PaymentMethod.cash,
        );
    }
  }
}

/// Worker identity verification statuses.
enum VerificationStatus {
  unverified,
  pending,
  verified,
  rejected;

  /// Returns the API string value.
  String get value => name;

  /// Parses an API string value into a [VerificationStatus].
  static VerificationStatus fromString(String value) {
    return VerificationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VerificationStatus.unverified,
    );
  }

  /// Whether the worker can appear in search results and receive orders.
  bool get canReceiveOrders => this == VerificationStatus.verified;
}

/// Notification types.
enum NotificationType {
  order,
  purchase,
  chat,
  promo,
  system,
  payment;

  /// Returns the API string value.
  String get value => name;

  /// Parses an API string value into a [NotificationType].
  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => NotificationType.system,
    );
  }
}

/// Chat message types.
enum MessageType {
  text,
  image,
  system;

  /// Returns the API string value.
  String get value => name;

  /// Parses an API string value into a [MessageType].
  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageType.text,
    );
  }
}

/// Chat message delivery statuses (client-side tracking).
enum MessageDeliveryStatus {
  sending,
  sent,
  delivered,
  failed;

  /// Returns the API string value.
  String get value => name;

  /// Parses an API string value into a [MessageDeliveryStatus].
  static MessageDeliveryStatus fromString(String value) {
    return MessageDeliveryStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MessageDeliveryStatus.sending,
    );
  }
}

/// Wallet transaction types.
enum WalletTxType {
  earning,
  withdrawal,
  refund,
  bonus,
  fee;

  /// Returns the API string value.
  String get value => name;

  /// Parses an API string value into a [WalletTxType].
  static WalletTxType fromString(String value) {
    return WalletTxType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WalletTxType.earning,
    );
  }

  /// Returns a human-readable label for display.
  String get label {
    switch (this) {
      case WalletTxType.earning:
        return 'Pendapatan';
      case WalletTxType.withdrawal:
        return 'Penarikan';
      case WalletTxType.refund:
        return 'Refund';
      case WalletTxType.bonus:
        return 'Bonus';
      case WalletTxType.fee:
        return 'Biaya';
    }
  }
}

/// Wallet transaction statuses.
enum WalletTxStatus {
  pending,
  completed,
  failed,
  cancelled;

  /// Returns the API string value.
  String get value => name;

  /// Parses an API string value into a [WalletTxStatus].
  static WalletTxStatus fromString(String value) {
    return WalletTxStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WalletTxStatus.pending,
    );
  }
}
