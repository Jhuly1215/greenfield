import 'package:flutter_gmaps/core/failure.dart';
import 'package:fpdart/fpdart.dart';


typedef FutureEither<T> = Future<Either<Failure, T>>;
typedef FutureEitherVoid = FutureEither<void>;
