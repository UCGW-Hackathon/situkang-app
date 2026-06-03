import 'package:glados/glados.dart';
import 'package:situkang_app/core/constants/app_constants.dart';
import 'package:situkang_app/core/constants/enums.dart';
import 'package:situkang_app/core/utils/validators.dart';

/// Property-based tests for core validators.
///
/// These tests verify universal properties hold across all randomly generated
/// inputs using the glados property-based testing library.
void main() {
  // ─── Property 1: Password Validation Correctness ───────────────────────────
  // **Validates: Requirements 1.4**
  group('Property 1: Password Validation Correctness', () {
    // Use a generator that produces strings with a mix of characters
    // including uppercase, lowercase, digits, and special chars.
    final passwordChars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%';

    Glados<String>(any.stringOf(passwordChars)).test(
      'accepts password iff >=8 chars AND has uppercase AND lowercase AND digit',
      (input) {
        final result = PasswordValidator.validate(input);

        final hasMinLength = input.length >= 8;
        final hasUppercase = input.contains(RegExp('[A-Z]'));
        final hasLowercase = input.contains(RegExp('[a-z]'));
        final hasDigit = input.contains(RegExp('[0-9]'));

        final shouldAccept =
            hasMinLength && hasUppercase && hasLowercase && hasDigit;

        if (shouldAccept) {
          expect(result, isNull,
              reason:
                  'Password "$input" meets all requirements but was rejected');
        } else {
          expect(result, isNotNull,
              reason:
                  'Password "$input" does not meet requirements but was accepted');
        }
      },
    );
  });

  // ─── Property 2: Password Confirmation Match ───────────────────────────────
  // **Validates: Requirements 1.5**
  group('Property 2: Password Confirmation Match', () {
    Glados<String>(any.letterOrDigits).test(
      'accepts when password and confirmation are identical',
      (input) {
        final result =
            PasswordConfirmationValidator.validate(input, input);
        expect(result, isNull,
            reason: 'Identical strings should always be accepted');
      },
    );

    Glados2<String, String>(any.letterOrDigits, any.letterOrDigits).test(
      'rejects iff password and confirmation are not identical',
      (password, confirmation) {
        final result =
            PasswordConfirmationValidator.validate(password, confirmation);

        if (password == confirmation) {
          expect(result, isNull,
              reason: 'Identical strings should be accepted');
        } else {
          expect(result, isNotNull,
              reason: 'Non-identical strings should be rejected');
        }
      },
    );
  });

  // ─── Property 5: File Upload Validation ────────────────────────────────────
  // **Validates: Requirements 2.5, 2.6, 14.9**
  group('Property 5: File Upload Validation', () {
    final validExtensions = ['jpg', 'jpeg', 'png'];
    final invalidExtensions = ['gif', 'bmp', 'tiff', 'webp', 'svg', 'pdf', 'doc', 'txt'];
    final allExtensions = [...validExtensions, ...invalidExtensions];

    Glados2<String, int>(
      any.choose(validExtensions),
      any.intInRange(0, AppConstants.maxAvatarFileSize + 1),
    ).test(
      'accepts file with valid extension and size within limit',
      (extension, fileSize) {
        final fileName = 'file.$extension';
        final result = FileUploadValidator.validate(fileName, fileSize);
        expect(result, isNull,
            reason:
                'File "$fileName" with size $fileSize should be accepted');
      },
    );

    Glados<int>(any.intInRange(
            AppConstants.maxAvatarFileSize + 1,
            AppConstants.maxAvatarFileSize * 3))
        .test(
      'rejects file exceeding size limit regardless of valid extension',
      (fileSize) {
        final result = FileUploadValidator.validate('photo.jpg', fileSize);
        expect(result, isNotNull,
            reason: 'File exceeding size limit should be rejected');
      },
    );

    Glados<String>(any.choose(invalidExtensions)).test(
      'rejects file with invalid extension regardless of size',
      (extension) {
        final fileName = 'file.$extension';
        final result = FileUploadValidator.validate(fileName, 1024);
        expect(result, isNotNull,
            reason:
                'File "$fileName" with invalid extension should be rejected');
      },
    );

    Glados2<String, int>(
      any.choose(allExtensions),
      any.intInRange(0, AppConstants.maxAvatarFileSize * 3),
    ).test(
      'accepts iff size <= limit AND extension in {jpg, jpeg, png}',
      (extension, fileSize) {
        final fileName = 'file.$extension';
        final maxSize = AppConstants.maxAvatarFileSize;
        final result = FileUploadValidator.validate(fileName, fileSize,
            maxSize: maxSize);

        final hasValidExtension = validExtensions.contains(extension);
        final hasValidSize = fileSize <= maxSize;
        final shouldAccept = hasValidExtension && hasValidSize;

        if (shouldAccept) {
          expect(result, isNull,
              reason:
                  'File "$fileName" (size=$fileSize) should be accepted');
        } else {
          expect(result, isNotNull,
              reason:
                  'File "$fileName" (size=$fileSize) should be rejected');
        }
      },
    );
  });

  // ─── Property 6: Input Field Length Validation ─────────────────────────────
  // **Validates: Requirements 2.8, 7.2, 7.9, 18.1**
  group('Property 6: Input Field Length Validation', () {
    final maxLengths = [255, 20, 2000, 50, 1000, 500];

    Glados2<String, int>(
      any.letterOrDigits,
      any.choose(maxLengths),
    ).test(
      'rejects strings exceeding max length; accepts strings at or below max',
      (value, maxLength) {
        final result = InputLengthValidator.validate(value, maxLength);

        if (value.length > maxLength) {
          expect(result, isNotNull,
              reason:
                  'String of length ${value.length} should be rejected for max $maxLength');
        } else {
          expect(result, isNull,
              reason:
                  'String of length ${value.length} should be accepted for max $maxLength');
        }
      },
    );
  });

  // ─── Property 11: Whitespace Message Rejection ─────────────────────────────
  // **Validates: Requirements 11.11**
  group('Property 11: Whitespace Message Rejection', () {
    // Test whitespace-only strings are always rejected
    Glados<String>(any.choose([
      '',
      ' ',
      '  ',
      '   ',
      '\t',
      '\n',
      '\r',
      ' \t \n ',
      '\t\t\t',
      '    \n    ',
      '\r\n',
      ' \r\n \t ',
    ])).test(
      'rejects whitespace-only or empty strings',
      (input) {
        final result = MessageValidator.validate(input);
        expect(result, isNotNull,
            reason: 'Whitespace-only message should be rejected');
      },
    );

    // Test strings with non-whitespace content within length limits
    final messageChars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';

    Glados<String>(any.nonEmptyStringOf(messageChars)).test(
      'accepts strings with non-whitespace content and length 1-2000',
      (input) {
        final result = MessageValidator.validate(input);

        final isWhitespaceOnly = input.trim().isEmpty;
        final exceedsMaxLength = input.length > 2000;

        if (isWhitespaceOnly || exceedsMaxLength) {
          expect(result, isNotNull,
              reason:
                  'Message (len=${input.length}, whitespaceOnly=$isWhitespaceOnly) should be rejected');
        } else {
          expect(result, isNull,
              reason:
                  'Message (len=${input.length}) with non-whitespace content should be accepted');
        }
      },
    );
  });

  // ─── Property 16: Purchase Input Validation ────────────────────────────────
  // **Validates: Requirements 18.1**
  group('Property 16: Purchase Input Validation', () {
    final validCategoryValues =
        PurchaseCategory.values.map((e) => e.value).toList();
    final invalidCategories = ['invalid', '', 'unknown', 'Material', 'ALAT'];

    Glados<String>(any.letterOrDigits).test(
      'item_name: accepts 1-255 chars, rejects empty or >255',
      (itemName) {
        final result = PurchaseInputValidator.validateItemName(itemName);

        if (itemName.isEmpty || itemName.length > 255) {
          expect(result, isNotNull,
              reason:
                  'Item name of length ${itemName.length} should be rejected');
        } else {
          expect(result, isNull,
              reason:
                  'Item name of length ${itemName.length} should be accepted');
        }
      },
    );

    Glados<String>(any.choose([
      ...validCategoryValues,
      ...invalidCategories,
    ])).test(
      'category: accepts only valid enum values',
      (category) {
        final result = PurchaseInputValidator.validateCategory(category);

        if (validCategoryValues.contains(category)) {
          expect(result, isNull,
              reason: 'Valid category "$category" should be accepted');
        } else {
          expect(result, isNotNull,
              reason: 'Invalid category "$category" should be rejected');
        }
      },
    );

    Glados<double>(any.doubleInRange(-100.0, 200000.0)).test(
      'quantity: accepts 0.01-99999.99, rejects outside range',
      (quantity) {
        final result = PurchaseInputValidator.validateQuantity(quantity);

        if (quantity >= 0.01 && quantity <= 99999.99) {
          expect(result, isNull,
              reason: 'Quantity $quantity should be accepted');
        } else {
          expect(result, isNotNull,
              reason: 'Quantity $quantity should be rejected');
        }
      },
    );

    Glados<String>(any.letterOrDigits).test(
      'unit: accepts 1-50 chars, rejects empty or >50',
      (unit) {
        final result = PurchaseInputValidator.validateUnit(unit);

        if (unit.isEmpty || unit.length > 50) {
          expect(result, isNotNull,
              reason: 'Unit of length ${unit.length} should be rejected');
        } else {
          expect(result, isNull,
              reason: 'Unit of length ${unit.length} should be accepted');
        }
      },
    );

    Glados<int>(any.intInRange(-100, 1100000000)).test(
      'unit_price: accepts 0-999999999, rejects outside range',
      (unitPrice) {
        final result = PurchaseInputValidator.validateUnitPrice(unitPrice);

        if (unitPrice >= 0 && unitPrice <= 999999999) {
          expect(result, isNull,
              reason: 'Unit price $unitPrice should be accepted');
        } else {
          expect(result, isNotNull,
              reason: 'Unit price $unitPrice should be rejected');
        }
      },
    );

    Glados<int>(any.intInRange(-100, 1100000000)).test(
      'total_price: accepts 0-999999999, rejects outside range',
      (totalPrice) {
        final result = PurchaseInputValidator.validateTotalPrice(totalPrice);

        if (totalPrice >= 0 && totalPrice <= 999999999) {
          expect(result, isNull,
              reason: 'Total price $totalPrice should be accepted');
        } else {
          expect(result, isNotNull,
              reason: 'Total price $totalPrice should be rejected');
        }
      },
    );
  });
}
