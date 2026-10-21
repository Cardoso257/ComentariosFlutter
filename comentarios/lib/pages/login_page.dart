import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _chaveForm = GlobalKey<FormState>();
  final _campoNome = TextEditingController();
  final _campoEmail = TextEditingController();
  final _campoSenha = TextEditingController();
  bool _modoCadastro = false;
  bool _carregando = false;
  String? _mensagemErro;

  @override
  void dispose() {
    _campoNome.dispose(); _campoEmail.dispose(); _campoSenha.dispose(); super.dispose();
  }

  Future<void> _autenticar() async {
    if (!_chaveForm.currentState!.validate() || _carregando) return;
    final nome = _campoNome.text.trim();
    final email = _campoEmail.text.trim();
    final senha = _campoSenha.text;
    setState(() { _carregando = true; _mensagemErro = null; });
    try {
      final auth = FirebaseAuth.instance;
      if (_modoCadastro) {
        final conta = await auth.createUserWithEmailAndPassword(
          email: email, password: senha);
        await conta.user!.updateDisplayName(nome);
      } else {
        await auth.signInWithEmailAndPassword(email: email, password: senha);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _mensagemErro = switch (e.code) {
        'email-already-in-use' => 'Esse e-mail já possui cadastro. Faça login.',
        'invalid-credential' || 'wrong-password' || 'user-not-found' => 'E-mail ou senha inválidos.',
        'operation-not-allowed' => 'Ative o login por E-mail/senha no Authentication do Firebase.',
        'weak-password' => 'A senha precisa ter ao menos 6 caracteres.',
        _ => 'Falha no acesso: ${e.code}.',
      });
    } catch (_) {
      if (mounted) setState(() => _mensagemErro = 'Algo deu errado. Verifique sua internet.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: SingleChildScrollView(
    padding: const EdgeInsets.all(24), child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420), child: Form(key: _chaveForm,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.forum_outlined, size: 64), const SizedBox(height: 16),
            Text(_modoCadastro ? 'Nova conta' : 'Rede Conecta', textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            if (_modoCadastro) ...[
              TextFormField(controller: _campoNome, enabled: !_carregando, maxLength: 80,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Digite seu nome.' : null),
              const SizedBox(height: 12),
            ],
            TextFormField(controller: _campoEmail, enabled: !_carregando,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail'),
              validator: (v) => v == null || !v.contains('@') ? 'Digite um e-mail válido.' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _campoSenha, enabled: !_carregando, obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
              validator: (v) => v == null || v.length < 6 ? 'Use ao menos 6 caracteres.' : null),
            const SizedBox(height: 16),
            if (_mensagemErro != null) Padding(padding: const EdgeInsets.only(bottom: 12),
              child: Text(_mensagemErro!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
            FilledButton(onPressed: _carregando ? null : _autenticar,
              child: Text(_carregando ? 'Aguarde...' : _modoCadastro ? 'Criar conta' : 'Acessar')),
            TextButton(onPressed: _carregando ? null : () => setState(() {
              _modoCadastro = !_modoCadastro; _mensagemErro = null;
            }), child: Text(_modoCadastro ? 'Já tenho cadastro' : 'Quero me cadastrar')),
          ],
        ),
      ),
    ),
  )));
}
