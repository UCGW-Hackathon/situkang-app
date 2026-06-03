/// Defines the [Result] type alias for functional error handling.
///
/// Uses the `dartz` package's [Either] type to represent operations that
/// can either fail with a [Failure] (Left) or succeed with a value (Right).
///
/// All repository methods return `Future<Result<T>>` to make error handling
/// explicit and composable without throwing exceptions.
///
/// Example usage:
/// ```dart
/// Future<Result<User>> getUser(String id) async {
///   try {
///     final user = await remoteDataSource.getUser(id);
///     return Right(user);
///   } on ServerException catch (e) {
///     return Left(ServerFailure(e.message, statusCode: e.statusCode));
///   }
/// }
/// ```
library;

import 'package:dartz/dartz.dart';

import 'failures.dart';

/// A type alias representing the result of an operation that can fail.
///
/// - [Left] contains a [Failure] describing what went wrong.
/// - [Right] contains the success value of type [T].
typedef Result<T> = Either<Failure, T>;
