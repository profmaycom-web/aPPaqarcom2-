class CustomException implements Exception {
  CustomException([this._message]);
  final dynamic _message;

  @override
  String toString() {
    return '$_message';
  }
}

class FetchDataException extends CustomException {
  FetchDataException([super._message]);
}

class BadRequestException extends CustomException {
  BadRequestException([super._message]);
}

class UnauthorisedException extends CustomException {
  UnauthorisedException([super._message]);
}

class VerificationException extends CustomException {
  VerificationException([super._message]);
}

class InvalidInputException extends CustomException {
  InvalidInputException([super._message]);
}
