import '../constants/app_constants.dart';
import '../constants/enums.dart';

/// Validates password strength requirements.
///
/// Requirements: min 8 characters, at least 1 uppercase letter,
/// 1 lowercase letter, and 1 numeric digit.
class PasswordValidator {
  PasswordValidator._();

  /// Returns `null` if [password] meets all requirements, or an error message
  /// string describing the first violated constraint.
  static String? validate(String password) {
    if (password.length < 8) {
      return 'Password harus minimal 8 karakter';
    }
    if (!password.contains(RegExp('[A-Z]'))) {
      return 'Password harus mengandung minimal 1 huruf besar';
    }
    if (!password.contains(RegExp('[a-z]'))) {
      return 'Password harus mengandung minimal 1 huruf kecil';
    }
    if (!password.contains(RegExp('[0-9]'))) {
      return 'Password harus mengandung minimal 1 angka';
    }
    return null;
  }
}

/// Validates that password confirmation matches the original password.
class PasswordConfirmationValidator {
  PasswordConfirmationValidator._();

  /// Returns `null` if [confirmation] matches [password], or an error message
  /// if they differ.
  static String? validate(String password, String confirmation) {
    if (password != confirmation) {
      return 'Konfirmasi password tidak cocok';
    }
    return null;
  }
}

/// Validates file uploads for size and format constraints.
///
/// Uses constants from [AppConstants] for size limits and allowed extensions.
class FileUploadValidator {
  FileUploadValidator._();

  /// Validates a file by its [fileName] and [fileSize] in bytes.
  ///
  /// [maxSize] defaults to [AppConstants.maxAvatarFileSize] (5MB).
  /// Returns `null` if valid, or an error message describing the violation.
  static String? validate(
    String fileName,
    int fileSize, {
    int maxSize = AppConstants.maxAvatarFileSize,
  }) {
    // Check file extension
    final extension = _getFileExtension(fileName);
    if (!AppConstants.allowedImageExtensions.contains(extension)) {
      return 'Format file tidak didukung. Gunakan: ${AppConstants.allowedImageExtensions.join(', ')}';
    }

    // Check file size
    if (fileSize > maxSize) {
      final maxSizeMB = maxSize / (1024 * 1024);
      return 'Ukuran file melebihi batas maksimal ${maxSizeMB.toStringAsFixed(0)}MB';
    }

    return null;
  }

  /// Extracts the lowercase file extension from a file name.
  static String _getFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot == -1 || lastDot == fileName.length - 1) {
      return '';
    }
    return fileName.substring(lastDot + 1).toLowerCase();
  }
}

/// Validates input field length against configurable maximum constraints.
class InputLengthValidator {
  InputLengthValidator._();

  /// Validates that [value] does not exceed [maxLength] characters.
  ///
  /// [fieldName] is used in the error message for context.
  /// Returns `null` if valid, or an error message if the length is exceeded.
  static String? validate(
    String value,
    int maxLength, {
    String fieldName = 'Input',
  }) {
    if (value.length > maxLength) {
      return '$fieldName tidak boleh lebih dari $maxLength karakter';
    }
    return null;
  }
}

/// Validates chat/text messages.
///
/// Rejects empty strings and whitespace-only strings.
/// Accepts messages with at least one non-whitespace character
/// and length between 1 and 2000 characters.
class MessageValidator {
  MessageValidator._();

  /// Maximum allowed message length.
  static const int maxLength = 2000;

  /// Returns `null` if [message] is valid, or an error message if invalid.
  static String? validate(String message) {
    if (message.isEmpty) {
      return 'Pesan tidak boleh kosong';
    }
    if (message.trim().isEmpty) {
      return 'Pesan tidak boleh hanya berisi spasi';
    }
    if (message.length > maxLength) {
      return 'Pesan tidak boleh lebih dari $maxLength karakter';
    }
    return null;
  }
}

/// Validates purchase input fields for the Worker purchase management feature.
class PurchaseInputValidator {
  PurchaseInputValidator._();

  /// Valid category string values matching [PurchaseCategory] enum API values.
  static final List<String> validCategories =
      PurchaseCategory.values.map((e) => e.value).toList();

  /// Validates item name: must be 1-255 characters.
  static String? validateItemName(String itemName) {
    if (itemName.isEmpty) {
      return 'Nama item tidak boleh kosong';
    }
    if (itemName.length > 255) {
      return 'Nama item tidak boleh lebih dari 255 karakter';
    }
    return null;
  }

  /// Validates category: must be one of the valid [PurchaseCategory] enum values.
  static String? validateCategory(String category) {
    if (!validCategories.contains(category)) {
      return 'Kategori tidak valid. Pilih: ${validCategories.join(', ')}';
    }
    return null;
  }

  /// Validates quantity: must be between 0.01 and 99999.99.
  static String? validateQuantity(double quantity) {
    if (quantity < 0.01) {
      return 'Jumlah minimal adalah 0.01';
    }
    if (quantity > 99999.99) {
      return 'Jumlah maksimal adalah 99999.99';
    }
    return null;
  }

  /// Validates unit: must be 1-50 characters.
  static String? validateUnit(String unit) {
    if (unit.isEmpty) {
      return 'Satuan tidak boleh kosong';
    }
    if (unit.length > 50) {
      return 'Satuan tidak boleh lebih dari 50 karakter';
    }
    return null;
  }

  /// Validates unit price: must be an integer between 0 and 999999999.
  static String? validateUnitPrice(int unitPrice) {
    if (unitPrice < 0) {
      return 'Harga satuan tidak boleh negatif';
    }
    if (unitPrice > 999999999) {
      return 'Harga satuan tidak boleh lebih dari 999.999.999';
    }
    return null;
  }

  /// Validates total price: must be an integer between 0 and 999999999.
  static String? validateTotalPrice(int totalPrice) {
    if (totalPrice < 0) {
      return 'Total harga tidak boleh negatif';
    }
    if (totalPrice > 999999999) {
      return 'Total harga tidak boleh lebih dari 999.999.999';
    }
    return null;
  }
}
