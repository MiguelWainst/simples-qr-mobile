import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/remote/catalog_repository.dart';

enum AuthMode { login, register, recovery, password }

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this.client);
  final SupabaseClient client;
  bool busy = false, _disposed = false;
  String? error, message;
  bool needsConfirmation = false;
  int resendSeconds = 0;
  Timer? _resendTimer;
  String? get redirect =>
      kIsWeb ? Uri.base.origin + Uri.base.path : 'simplesqr://auth-callback';

  void _startCooldown() {
    resendSeconds = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      resendSeconds--;
      if (resendSeconds <= 0 || _disposed) timer.cancel();
      if (!_disposed) notifyListeners();
    });
  }

  Future<void> resendConfirmation(String email) async {
    if (busy || resendSeconds > 0 || _disposed) return;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
      error = 'Informe seu e-mail para reenviar a confirmação.';
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    message = null;
    notifyListeners();
    try {
      await client.auth
          .resend(
            type: OtpType.signup,
            email: email.trim(),
            emailRedirectTo: redirect,
          )
          .timeout(const Duration(seconds: 20));
      message = 'Solicitação de reenvio recebida. Confira a caixa de entrada e o spam. A entrega depende do serviço de e-mail.';
      _startCooldown();
    } catch (e) {
      error = friendlyError(e);
      if (e is AuthException && e.code == 'over_email_send_rate_limit')
        _startCooldown();
    } finally {
      busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> submit(AuthMode mode, String email, String password) async {
    if (busy) {
      return false;
    }
    busy = true;
    error = null;
    message = null;
    notifyListeners();
    try {
      switch (mode) {
        case AuthMode.login:
          await client.auth
              .signInWithPassword(email: email.trim(), password: password)
              .timeout(const Duration(seconds: 20));
        case AuthMode.register:
          final response = await client.auth
              .signUp(
                email: email.trim(),
                password: password,
                emailRedirectTo: redirect,
              )
              .timeout(const Duration(seconds: 20));
          if (response.session == null) {
            needsConfirmation = true;
            _startCooldown();
            message = 'Confirme seu e-mail para continuar. Confira também o spam. Se já tinha uma conta, use Entrar ou Recuperar senha.';
            return false;
          }
        case AuthMode.recovery:
          await client.auth
              .resetPasswordForEmail(email.trim(), redirectTo: redirect)
              .timeout(const Duration(seconds: 20));
          message = 'Se o e-mail estiver cadastrado, você receberá um link para definir uma nova senha.';
          return false;
        case AuthMode.password:
          await client.auth
              .updateUser(UserAttributes(password: password))
              .timeout(const Duration(seconds: 20));
      }
      return true;
    } catch (e) {
      error = friendlyError(e);
      if (e is AuthException &&
          (e.code == 'email_not_confirmed' ||
              e.message.contains('Email not confirmed'))) {
        needsConfirmation = true;
      }
      return false;
    } finally {
      busy = false;
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _resendTimer?.cancel();
    super.dispose();
  }
}
