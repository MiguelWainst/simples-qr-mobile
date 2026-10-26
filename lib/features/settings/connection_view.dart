import 'package:flutter/material.dart';
import '../../shared/widgets/catalog_widgets.dart';
class ConnectionApp extends StatelessWidget {
  const ConnectionApp({required this.onConnect, this.initialUrl = '', super.key});
  final Future<void> Function(String, String) onConnect;
  final String initialUrl;
  @override
  Widget build(BuildContext context) => MaterialApp(title: 'Simples QR', debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xff206b53)),
    home: ConnectionView(onConnect: onConnect, initialUrl: initialUrl));
}
class ConnectionView extends StatefulWidget {
  const ConnectionView({required this.onConnect, required this.initialUrl, super.key});
  final Future<void> Function(String, String) onConnect;
  final String initialUrl;
  @override
  State<ConnectionView> createState() => _ConnectionViewState();
}
class _ConnectionViewState extends State<ConnectionView> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _url;
  final _key = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void initState() { super.initState(); _url = TextEditingController(text: widget.initialUrl); }
  @override
  void dispose() { _url.dispose(); _key.dispose(); super.dispose(); }
  Future<void> _connect() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try { await widget.onConnect(_url.text.trim(), _key.text.trim()); }
    catch (_) { if (mounted) setState(() => _error = 'Não foi possível iniciar. Confira a URL, a chave pública e sua conexão.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Simples QR')),
    body: ContentWidth(child: Form(key: _form, child: ListView(padding: const EdgeInsets.all(24), children: [
      const SectionTitle('Conectar seu projeto'),
      const Text('Configuração inicial do desenvolvimento. Cole a Project URL e a chave pública do projeto Supabase que você criou.'),
      const SizedBox(height: 24),
      TextFormField(controller: _url, decoration: const InputDecoration(labelText: 'Project URL', hintText: 'https://seu-projeto.supabase.co', border: OutlineInputBorder()),
        validator: (v) { final uri = Uri.tryParse((v ?? '').trim());
          return uri != null && uri.scheme == 'https' && uri.host.endsWith('.supabase.co') ? null : 'Informe a URL HTTPS do projeto Supabase.'; }),
      const SizedBox(height: 16),
      TextFormField(controller: _key, decoration: const InputDecoration(labelText: 'Chave pública publishable ou anon', border: OutlineInputBorder()),
        validator: (v) => (v ?? '').startsWith('sb_secret_') ? 'Use a chave pública, nunca a secret.'
          : (v ?? '').trim().length < 30 ? 'Cole a chave pública completa.' : null),
      const SizedBox(height: 16),
      if (_error != null) Notice(_error!, error: true),
      BusyButton(label: 'Conectar', busy: _busy, onPressed: _connect),
    ]))));
}
