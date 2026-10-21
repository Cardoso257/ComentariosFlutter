import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../comentarios/botao_comentarios.dart';
import 'perfil_page.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final _campoPublicacao = TextEditingController();
  late final _fluxoPublicacoes = FirebaseFirestore.instance.collection('publicacoes')
    .orderBy('criadoEm', descending: true).snapshots(includeMetadataChanges: true);
  bool _publicando = false;
  @override
  void dispose() { _campoPublicacao.dispose(); super.dispose(); }

  Future<void> _criarPublicacao() async {
    if (_publicando || _campoPublicacao.text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final nome = user.displayName?.trim();
    if (nome == null || nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cadastre seu nome no perfil para poder publicar.')));
      return;
    }
    setState(() => _publicando = true);
    try {
      await FirebaseFirestore.instance.collection('publicacoes').add({
        'texto': _campoPublicacao.text.trim(), 'nome': nome, 'uid': user.uid,
        'criadoEm': FieldValue.serverTimestamp(),
      });
      if (mounted) _campoPublicacao.clear();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Falha ao publicar. Verifique a internet e as regras do Firestore.')));
    } finally {
      if (mounted) setState(() => _publicando = false);
    }
  }

  Widget _cartaoPublicacao(Map<String, dynamic> d) => Card(child: Padding(
    padding: const EdgeInsets.all(16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(d['nome'] as String? ?? 'Anônimo', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10), Text(d['texto'] as String? ?? ''),
      ],
    ),
  ));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Rede Conecta • Publicações'), actions: [
      IconButton(tooltip: 'Perfil', icon: const Icon(Icons.account_circle_outlined),
        onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const PerfilPage()))),
      IconButton(tooltip: 'Sair', icon: const Icon(Icons.logout), onPressed: () async {
        try { await FirebaseAuth.instance.signOut(); }
        catch (_) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao sair da conta.')));
        }
      }),
    ]),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 800),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(controller: _campoPublicacao, enabled: !_publicando, minLines: 2, maxLines: 4, maxLength: 2000,
              decoration: const InputDecoration(labelText: 'No que você está pensando?')),
            FilledButton.icon(onPressed: _publicando ? null : _criarPublicacao,
              icon: const Icon(Icons.send), label: Text(_publicando ? 'Enviando...' : 'Postar')),
          ],
        )),
        Expanded(child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _fluxoPublicacoes,
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Não foi possível carregar as publicações. Verifique as regras do Firebase.'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Center(child: Text('Sem publicações por aqui. Seja o primeiro a postar!'));
            return ListView.builder(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: docs.length, itemBuilder: (context, index) {
                final doc = docs[index];
                return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: double.infinity, child: _cartaoPublicacao(doc.data())),
                    if (doc.metadata.hasPendingWrites) const Text('Salvando publicação...')
                    else BotaoComentarios(postRef: doc.reference,
                      postWidget: _cartaoPublicacao(doc.data())),
                  ],
                ));
              },
            );
          },
        )),
      ]),
    )),
  );
}
