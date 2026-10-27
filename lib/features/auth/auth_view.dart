import 'package:flutter/material.dart';

import '../../core/app_services.dart';
import '../../domain/catalog.dart';
import '../../shared/widgets/catalog_widgets.dart';
import 'auth_view_model.dart';

class AuthView extends StatefulWidget {
  const AuthView({required this.services, required this.mode, super.key});
  final AppServices services;
  final AuthMode mode;
  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController(), _password = TextEditingController();
  AuthViewModel? _model;
  bool _visible = false;
  @override
  void initState() {
    super.initState();
    final client = widget.services.client;
    if (client != null) {
      _model = AuthViewModel(client);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _model?.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    final ok = await _model!.submit(widget.mode, _email.text, _password.text);
    if (!mounted || !ok) {
      return;
    }
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/owner', (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.mode) {
      AuthMode.login => 'Entrar',
      AuthMode.register => 'Criar conta',
      AuthMode.recovery => 'Recuperar senha',
      AuthMode.password => 'Nova senha',
    };
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ContentWidth(
        child: _model == null
            ? const EmptyState('Conecte o aplicativo ao Supabase para entrar.')
            : ListenableBuilder(
                listenable: _model!,
                builder: (context, _) => Form(
                  key: _form,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const Icon(Icons.storefront_outlined, size: 64),
                      SectionTitle(title),
                      const Text(
                        'Sua cozinha, seu cardápio. Gerencie tudo por aqui.',
                      ),
                      const SizedBox(height: 24),
                      if (widget.mode != AuthMode.password)
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          validator: Rules.email,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (widget.mode != AuthMode.recovery)
                        TextFormField(
                          controller: _password,
                          obscureText: !_visible,
                          autofillHints: [
                            widget.mode == AuthMode.login
                                ? AutofillHints.password
                                : AutofillHints.newPassword,
                          ],
                          validator: widget.mode == AuthMode.login
                              ? (v) => (v ?? '').isEmpty
                                    ? 'Informe sua senha.'
                                    : null
                              : Rules.password,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              tooltip: _visible
                                  ? 'Ocultar senha'
                                  : 'Mostrar senha',
                              onPressed: () =>
                                  setState(() => _visible = !_visible),
                              icon: Icon(
                                _visible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (_model!.error != null)
                        Notice(_model!.error!, error: true),
                      if (_model!.message != null) Notice(_model!.message!),
                      BusyButton(
                        label: title,
                        busy: _model!.busy,
                        onPressed: _submit,
                      ),
                      if (widget.mode == AuthMode.login) ...[
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                          child: const Text('Criar uma conta'),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/recovery'),
                          child: const Text('Esqueci minha senha'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class OwnerGuard extends StatelessWidget {
  const OwnerGuard({required this.services, required this.child, super.key});
  final AppServices services;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final client = services.client;
    if (client == null) {
      return AuthView(services: services, mode: AuthMode.login);
    }
    return StreamBuilder(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) => client.auth.currentUser == null
          ? AuthView(services: services, mode: AuthMode.login)
          : child,
    );
  }
}
