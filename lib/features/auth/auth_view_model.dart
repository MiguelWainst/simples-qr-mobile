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
  String? get redirect => kIsWeb
    ? Uri.base.replace(query: '', fragment: '').toString()
    : 'simplesqr://auth-callback';
  Future<bool> submit(AuthMode mode, String email, String password) async {
    if (busy) return false;
    busy = true; error = null; message = null; notifyListeners();
    try {
      switch (mode) {
        case AuthMode.login:
          await client.auth.signInWithPassword(email: email.trim(), password: password)
            .timeout(const Duration(seconds: 20));
        case AuthMode.register:
          final response = await client.auth.signUp(email: email.trim(), password: password,
            emailRedirectTo: redirect).timeout(const Duration(seconds: 20));
          if (response.session == null) {
            message = 'Confira seu e-mail para confirmar o cadastro. Depois, entre com sua senha.';
            return false;
          }
        case AuthMode.recovery:
          await client.auth.resetPasswordForEmail(email.trim(), redirectTo: redirect)
            .timeout(const Duration(seconds: 20));
          message = 'Se o e-mail estiver cadastrado, você receberá um link para definir uma nova senha.';
          return false;
        case AuthMode.password:
          await client.auth.updateUser(UserAttributes(password: password))
            .timeout(const Duration(seconds: 20));
      }
      return true;
    } catch (e) {
      error = friendlyError(e); return false;
    } finally {
      busy = false; if (!_disposed) notifyListeners();
    }
  }
  @override
  void dispose() { _disposed = true; super.dispose(); }
}
