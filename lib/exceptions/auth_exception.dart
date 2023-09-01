class AuthException implements Exception{
  static const Map<String, String> errors = {
    'EMAIL_EXISTS': 'E-mail ja cadastrado.',
    'OPERATION_NOT_ALLOWED': 'Operacao nao permitida',
    'TOO_MANY_ATTEMPTS_TRY_LATER': 'Muitas tentativas, tente mais tarde',
    'EMAIL_NOT_FOUND': 'email nao encontrado',
    'INVALID_PASSWORD': 'senha invalida',
    'USER_DISABLED': 'conta foi desabilitada',
  };

  final String key;

  AuthException(this.key);

  @override
  String toString() {
    return errors[key] ?? 'Ocorreu um erro no processo de autenticacao';
  }
}