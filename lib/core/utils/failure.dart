abstract class Failure {
  final String message;
  final String? code;

  Failure(this.message, {this.code});
}

class ServerFailure extends Failure {
  ServerFailure(String message, {String? code}) : super(message, code: code);
}

class CacheFailure extends Failure {
  CacheFailure(String message, {String? code}) : super(message, code: code);
}

class NetworkFailure extends Failure {
  NetworkFailure(String message, {String? code}) : super(message, code: code);
}

class ValidationFailure extends Failure {
  ValidationFailure(String message, {String? code}) : super(message, code: code);
} 