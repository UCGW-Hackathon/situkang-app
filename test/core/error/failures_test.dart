import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:situkang_app/core/error/failures.dart';
import 'package:situkang_app/core/error/result.dart';

void main() {
  group('FieldError', () {
    test('should create FieldError with required fields', () {
      const fieldError = FieldError(field: 'email', message: 'Invalid email');

      expect(fieldError.field, 'email');
      expect(fieldError.message, 'Invalid email');
    });

    test('should create FieldError from JSON', () {
      final json = {'field': 'phone', 'message': 'Phone already registered'};
      final fieldError = FieldError.fromJson(json);

      expect(fieldError.field, 'phone');
      expect(fieldError.message, 'Phone already registered');
    });

    test('should handle missing fields in JSON with defaults', () {
      final json = <String, dynamic>{};
      final fieldError = FieldError.fromJson(json);

      expect(fieldError.field, '');
      expect(fieldError.message, '');
    });

    test('should convert to JSON', () {
      const fieldError = FieldError(field: 'email', message: 'Invalid');
      final json = fieldError.toJson();

      expect(json, {'field': 'email', 'message': 'Invalid'});
    });

    test('should support equality', () {
      const error1 = FieldError(field: 'email', message: 'Invalid');
      const error2 = FieldError(field: 'email', message: 'Invalid');
      const error3 = FieldError(field: 'phone', message: 'Invalid');

      expect(error1, equals(error2));
      expect(error1, isNot(equals(error3)));
    });
  });

  group('Failure hierarchy', () {
    test('ServerFailure should store statusCode and fieldErrors', () {
      const failure = ServerFailure(
        'Internal server error',
        statusCode: 500,
        fieldErrors: [FieldError(field: 'name', message: 'Required')],
        errorCode: 'SERVER_ERROR',
      );

      expect(failure.message, 'Internal server error');
      expect(failure.statusCode, 500);
      expect(failure.fieldErrors, isNotNull);
      expect(failure.fieldErrors!.length, 1);
      expect(failure.errorCode, 'SERVER_ERROR');
    });

    test('NetworkFailure should have default message', () {
      const failure = NetworkFailure();

      expect(failure.message, 'Tidak ada koneksi internet');
      expect(failure.errorCode, isNull);
    });

    test('NetworkFailure should accept custom message', () {
      const failure = NetworkFailure('Custom network error');

      expect(failure.message, 'Custom network error');
    });

    test('CacheFailure should have default message', () {
      const failure = CacheFailure();

      expect(failure.message, 'Data cache tidak tersedia');
      expect(failure.errorCode, isNull);
    });

    test('CacheFailure should accept custom message', () {
      const failure = CacheFailure('Cache corrupted');

      expect(failure.message, 'Cache corrupted');
    });

    test('AuthFailure should store message and errorCode', () {
      const failure = AuthFailure(
        'Token expired',
        errorCode: 'TOKEN_EXPIRED',
      );

      expect(failure.message, 'Token expired');
      expect(failure.errorCode, 'TOKEN_EXPIRED');
    });

    test('ValidationFailure should store fieldErrors map', () {
      const failure = ValidationFailure(
        'Validation failed',
        fieldErrors: {'email': 'Invalid format', 'phone': 'Too short'},
      );

      expect(failure.message, 'Validation failed');
      expect(failure.fieldErrors.length, 2);
      expect(failure.fieldErrors['email'], 'Invalid format');
      expect(failure.fieldErrors['phone'], 'Too short');
    });

    test('TimeoutFailure should have default message', () {
      const failure = TimeoutFailure();

      expect(failure.message, 'Koneksi timeout, coba lagi');
      expect(failure.errorCode, isNull);
    });

    test('TimeoutFailure should accept custom message', () {
      const failure = TimeoutFailure('Request timed out after 30s');

      expect(failure.message, 'Request timed out after 30s');
    });

    test('WebSocketFailure should store message', () {
      const failure = WebSocketFailure('Connection lost');

      expect(failure.message, 'Connection lost');
      expect(failure.errorCode, isNull);
    });

    test('Failure subclasses support exhaustive pattern matching', () {
      const Failure failure = NetworkFailure();

      final result = switch (failure) {
        ServerFailure() => 'server',
        NetworkFailure() => 'network',
        CacheFailure() => 'cache',
        AuthFailure() => 'auth',
        ValidationFailure() => 'validation',
        TimeoutFailure() => 'timeout',
        WebSocketFailure() => 'websocket',
      };

      expect(result, 'network');
    });

    test('Failure subclasses support equality via Equatable', () {
      const failure1 = NetworkFailure();
      const failure2 = NetworkFailure();
      const failure3 = CacheFailure();

      expect(failure1, equals(failure2));
      expect(failure1, isNot(equals(failure3)));
    });
  });

  group('Result type', () {
    test('Result<T> can represent success (Right)', () {
      const Result<String> result = Right('success data');

      expect(result.isRight(), isTrue);
      expect(result.isLeft(), isFalse);
      result.fold(
        (failure) => fail('Should not be Left'),
        (value) => expect(value, 'success data'),
      );
    });

    test('Result<T> can represent failure (Left)', () {
      const Result<String> result = Left(NetworkFailure());

      expect(result.isLeft(), isTrue);
      expect(result.isRight(), isFalse);
      result.fold(
        (failure) => expect(failure, isA<NetworkFailure>()),
        (value) => fail('Should not be Right'),
      );
    });

    test('Result<T> works with complex types', () {
      const Result<List<int>> result = Right([1, 2, 3]);

      result.fold(
        (failure) => fail('Should not be Left'),
        (value) => expect(value, [1, 2, 3]),
      );
    });

    test('Result<T> failure preserves Failure details', () {
      const Result<int> result = Left(
        ServerFailure('Not found', statusCode: 404, errorCode: 'NOT_FOUND'),
      );

      result.fold(
        (failure) {
          expect(failure, isA<ServerFailure>());
          final serverFailure = failure as ServerFailure;
          expect(serverFailure.statusCode, 404);
          expect(serverFailure.errorCode, 'NOT_FOUND');
        },
        (value) => fail('Should not be Right'),
      );
    });
  });
}
