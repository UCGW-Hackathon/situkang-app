import 'package:flutter_test/flutter_test.dart';
import 'package:situkang_app/core/constants/app_constants.dart';
import 'package:situkang_app/core/utils/validators.dart';

void main() {
  group('PasswordValidator', () {
    test('accepts valid password with all requirements met', () {
      expect(PasswordValidator.validate('Abcdef1g'), isNull);
      expect(PasswordValidator.validate('Password123'), isNull);
      expect(PasswordValidator.validate('MyP4ssword'), isNull);
    });

    test('rejects password shorter than 8 characters', () {
      expect(PasswordValidator.validate('Ab1cdef'), isNotNull);
      expect(PasswordValidator.validate('A1b'), isNotNull);
      expect(PasswordValidator.validate(''), isNotNull);
    });

    test('rejects password without uppercase letter', () {
      expect(PasswordValidator.validate('abcdefg1'), isNotNull);
    });

    test('rejects password without lowercase letter', () {
      expect(PasswordValidator.validate('ABCDEFG1'), isNotNull);
    });

    test('rejects password without digit', () {
      expect(PasswordValidator.validate('Abcdefgh'), isNotNull);
    });
  });

  group('PasswordConfirmationValidator', () {
    test('accepts matching passwords', () {
      expect(
        PasswordConfirmationValidator.validate('Password1', 'Password1'),
        isNull,
      );
    });

    test('rejects non-matching passwords', () {
      expect(
        PasswordConfirmationValidator.validate('Password1', 'Password2'),
        isNotNull,
      );
    });

    test('rejects case-different passwords', () {
      expect(
        PasswordConfirmationValidator.validate('password1', 'Password1'),
        isNotNull,
      );
    });
  });

  group('FileUploadValidator', () {
    test('accepts valid jpg file within size limit', () {
      expect(
        FileUploadValidator.validate('photo.jpg', 1024 * 1024),
        isNull,
      );
    });

    test('accepts valid jpeg file within size limit', () {
      expect(
        FileUploadValidator.validate('photo.jpeg', 2 * 1024 * 1024),
        isNull,
      );
    });

    test('accepts valid png file within size limit', () {
      expect(
        FileUploadValidator.validate('image.png', 4 * 1024 * 1024),
        isNull,
      );
    });

    test('accepts file at exact size limit', () {
      expect(
        FileUploadValidator.validate(
          'photo.jpg',
          AppConstants.maxAvatarFileSize,
        ),
        isNull,
      );
    });

    test('rejects file exceeding size limit', () {
      expect(
        FileUploadValidator.validate(
          'photo.jpg',
          AppConstants.maxAvatarFileSize + 1,
        ),
        isNotNull,
      );
    });

    test('rejects unsupported file format', () {
      expect(
        FileUploadValidator.validate('document.pdf', 1024),
        isNotNull,
      );
      expect(
        FileUploadValidator.validate('image.gif', 1024),
        isNotNull,
      );
      expect(
        FileUploadValidator.validate('file.bmp', 1024),
        isNotNull,
      );
    });

    test('rejects file with no extension', () {
      expect(
        FileUploadValidator.validate('noextension', 1024),
        isNotNull,
      );
    });

    test('uses custom maxSize for receipt photos', () {
      // 9MB should be valid for receipt (10MB limit)
      expect(
        FileUploadValidator.validate(
          'receipt.jpg',
          9 * 1024 * 1024,
          maxSize: AppConstants.maxReceiptFileSize,
        ),
        isNull,
      );
      // 11MB should be invalid for receipt (10MB limit)
      expect(
        FileUploadValidator.validate(
          'receipt.jpg',
          11 * 1024 * 1024,
          maxSize: AppConstants.maxReceiptFileSize,
        ),
        isNotNull,
      );
    });
  });

  group('InputLengthValidator', () {
    test('accepts string within max length', () {
      expect(InputLengthValidator.validate('hello', 255), isNull);
    });

    test('accepts string at exact max length', () {
      final value = 'a' * 255;
      expect(InputLengthValidator.validate(value, 255), isNull);
    });

    test('rejects string exceeding max length', () {
      final value = 'a' * 256;
      expect(InputLengthValidator.validate(value, 255), isNotNull);
    });

    test('accepts empty string (length validation only)', () {
      expect(InputLengthValidator.validate('', 255), isNull);
    });

    test('includes field name in error message', () {
      final result = InputLengthValidator.validate(
        'a' * 256,
        255,
        fieldName: 'Nama lengkap',
      );
      expect(result, contains('Nama lengkap'));
    });
  });

  group('MessageValidator', () {
    test('accepts valid message with non-whitespace content', () {
      expect(MessageValidator.validate('Hello'), isNull);
      expect(MessageValidator.validate('a'), isNull);
    });

    test('accepts message at max length', () {
      final message = 'a' * 2000;
      expect(MessageValidator.validate(message), isNull);
    });

    test('rejects empty message', () {
      expect(MessageValidator.validate(''), isNotNull);
    });

    test('rejects whitespace-only message', () {
      expect(MessageValidator.validate('   '), isNotNull);
      expect(MessageValidator.validate('\t\n'), isNotNull);
      expect(MessageValidator.validate(' \t \n '), isNotNull);
    });

    test('rejects message exceeding max length', () {
      final message = 'a' * 2001;
      expect(MessageValidator.validate(message), isNotNull);
    });

    test('accepts message with leading/trailing whitespace if has content', () {
      expect(MessageValidator.validate('  hello  '), isNull);
    });
  });

  group('PurchaseInputValidator', () {
    group('validateItemName', () {
      test('accepts valid item name', () {
        expect(PurchaseInputValidator.validateItemName('Pipa PVC'), isNull);
      });

      test('rejects empty item name', () {
        expect(PurchaseInputValidator.validateItemName(''), isNotNull);
      });

      test('rejects item name exceeding 255 chars', () {
        expect(
          PurchaseInputValidator.validateItemName('a' * 256),
          isNotNull,
        );
      });

      test('accepts item name at exactly 255 chars', () {
        expect(
          PurchaseInputValidator.validateItemName('a' * 255),
          isNull,
        );
      });
    });

    group('validateCategory', () {
      test('accepts valid categories', () {
        expect(PurchaseInputValidator.validateCategory('material'), isNull);
        expect(PurchaseInputValidator.validateCategory('alat'), isNull);
        expect(PurchaseInputValidator.validateCategory('sparepart'), isNull);
        expect(
          PurchaseInputValidator.validateCategory('bahan_bangunan'),
          isNull,
        );
        expect(
          PurchaseInputValidator.validateCategory('biaya_tambahan'),
          isNull,
        );
        expect(PurchaseInputValidator.validateCategory('lainnya'), isNull);
      });

      test('rejects invalid category', () {
        expect(PurchaseInputValidator.validateCategory('invalid'), isNotNull);
        expect(PurchaseInputValidator.validateCategory(''), isNotNull);
      });
    });

    group('validateQuantity', () {
      test('accepts valid quantity', () {
        expect(PurchaseInputValidator.validateQuantity(1.0), isNull);
        expect(PurchaseInputValidator.validateQuantity(0.01), isNull);
        expect(PurchaseInputValidator.validateQuantity(99999.99), isNull);
        expect(PurchaseInputValidator.validateQuantity(500.5), isNull);
      });

      test('rejects quantity below minimum', () {
        expect(PurchaseInputValidator.validateQuantity(0.0), isNotNull);
        expect(PurchaseInputValidator.validateQuantity(0.009), isNotNull);
        expect(PurchaseInputValidator.validateQuantity(-1.0), isNotNull);
      });

      test('rejects quantity above maximum', () {
        expect(PurchaseInputValidator.validateQuantity(100000.0), isNotNull);
        expect(PurchaseInputValidator.validateQuantity(99999.999), isNotNull);
      });
    });

    group('validateUnit', () {
      test('accepts valid unit', () {
        expect(PurchaseInputValidator.validateUnit('kg'), isNull);
        expect(PurchaseInputValidator.validateUnit('meter'), isNull);
      });

      test('rejects empty unit', () {
        expect(PurchaseInputValidator.validateUnit(''), isNotNull);
      });

      test('rejects unit exceeding 50 chars', () {
        expect(PurchaseInputValidator.validateUnit('a' * 51), isNotNull);
      });

      test('accepts unit at exactly 50 chars', () {
        expect(PurchaseInputValidator.validateUnit('a' * 50), isNull);
      });
    });

    group('validateUnitPrice', () {
      test('accepts valid unit price', () {
        expect(PurchaseInputValidator.validateUnitPrice(0), isNull);
        expect(PurchaseInputValidator.validateUnitPrice(50000), isNull);
        expect(PurchaseInputValidator.validateUnitPrice(999999999), isNull);
      });

      test('rejects negative unit price', () {
        expect(PurchaseInputValidator.validateUnitPrice(-1), isNotNull);
      });

      test('rejects unit price exceeding max', () {
        expect(PurchaseInputValidator.validateUnitPrice(1000000000), isNotNull);
      });
    });

    group('validateTotalPrice', () {
      test('accepts valid total price', () {
        expect(PurchaseInputValidator.validateTotalPrice(0), isNull);
        expect(PurchaseInputValidator.validateTotalPrice(100000), isNull);
        expect(PurchaseInputValidator.validateTotalPrice(999999999), isNull);
      });

      test('rejects negative total price', () {
        expect(PurchaseInputValidator.validateTotalPrice(-1), isNotNull);
      });

      test('rejects total price exceeding max', () {
        expect(
          PurchaseInputValidator.validateTotalPrice(1000000000),
          isNotNull,
        );
      });
    });
  });
}
