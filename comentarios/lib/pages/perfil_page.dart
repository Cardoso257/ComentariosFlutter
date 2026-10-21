import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});
  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _campoNome = TextEditingController(text: FirebaseAuth.instance.currentUser?.displayName ?? '');
  bool _gravando = false;
  @override
  void dispose() { _campoNome.dispose(); super.dispose(); }

  Future<void> _gravar() async {
    if (_gravando || _campoNome.text.trim().isEmpty) return;
    setState(() => _gravando = true);
    try {
      await FirebaseAuth.instance.currentUser!.updateDisplayName(_campoNome.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao gravar o perfil.')));
    } finally {
      if (mounted) setState(() => _gravando = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Perfil')),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 500),
      child: ListView(padding: const EdgeInsets.all(24), children: [
        const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
        const SizedBox(height: 24),
        Text(FirebaseAuth.instance.currentUser?.email ?? ''), const SizedBox(height: 16),
        TextField(controller: _campoNome, maxLength: 80, enabled: !_gravando,
          decoration: const InputDecoration(labelText: 'Nome')),
        const SizedBox(height: 16),
        FilledButton(onPressed: _gravando ? null : _gravar,
          child: Text(_gravando ? 'Gravando...' : 'Gravar alterações')),
      ]),
    )),
  );
}
