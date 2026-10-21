import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'comentario.dart';
import 'comentarios_service.dart';

class ComentariosPage extends StatefulWidget {
  final DocumentReference<Map<String, dynamic>> postRef;
  final Widget postWidget;

  const ComentariosPage({super.key, required this.postRef,
    required this.postWidget});

  @override
  State<ComentariosPage> createState() => _ComentariosPageState();
}

class _ComentariosPageState extends State<ComentariosPage> {
  final _campoComentario = TextEditingController();
  final Set<String> _removendo = {};
  late final ComentariosService _servico;
  late final Stream<List<ComentarioItem>> _fluxo;
  bool _postando = false;

  @override
  void initState() {
    super.initState();
    _servico = ComentariosService(widget.postRef);
    _fluxo = _servico.observar();
  }

  @override
  void dispose() {
    _campoComentario.dispose();
    super.dispose();
  }

  void _mostrarErro(Object erro) {
    if (!mounted) return;
    final mensagem = erro is FirebaseException
      ? 'Falha na operação (${erro.code}). Verifique a internet e as regras do Firestore.'
      : erro.toString();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _postar() async {
    if (_postando || _campoComentario.text.trim().isEmpty) return;
    setState(() => _postando = true);
    try {
      await _servico.salvar(_campoComentario.text);
      if (mounted) _campoComentario.clear();
    } catch (e) {
      _mostrarErro(e);
    } finally {
      if (mounted) setState(() => _postando = false);
    }
  }

  Future<void> _remover(ComentarioItem comentario) async {
    final confirmar = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Apagar seu comentário?'),
      content: const Text('Ele deixará de aparecer para todos os usuários.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Voltar')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar')),
      ],
    ));
    if (confirmar != true || !mounted || _removendo.contains(comentario.id)) return;
    setState(() => _removendo.add(comentario.id));
    try {
      await _servico.apagar(comentario);
    } catch (e) {
      _mostrarErro(e);
    } finally {
      if (mounted) setState(() => _removendo.remove(comentario.id));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Discussão')),
    body: SafeArea(child: Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        initialData: FirebaseAuth.instance.currentUser,
        builder: (context, auth) {
          final user = auth.data;
          if (user == null) {
            return const Center(child: Text('Faça login para ver os comentários.'));
          }
          return Column(children: [
            Expanded(child: StreamBuilder<List<ComentarioItem>>(
              stream: _fluxo,
              builder: (context, snapshot) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  widget.postWidget,
                  const Divider(height: 32),
                  Text('Comentários da publicação', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (snapshot.hasError)
                    const Padding(padding: EdgeInsets.all(16), child: Text(
                      'Não foi possível carregar os comentários. Verifique a internet e as regras de acesso.'))
                  else if (!snapshot.hasData)
                    const Center(child: CircularProgressIndicator())
                  else if (snapshot.data!.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 24),
                      child: Text('Ainda não há comentários. Que tal começar a conversa?'))
                  else
                    for (final c in snapshot.data!)
                      Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(child: Icon(Icons.person_outline)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.autor, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(c.mensagem),
                              if (c.aguardandoEnvio) const Text('Publicando...', style: TextStyle(fontSize: 12)),
                            ],
                          )),
                          if (c.autorUid == user.uid)
                            IconButton(
                              tooltip: 'Apagar meu comentário',
                              onPressed: c.aguardandoEnvio || _removendo.contains(c.id) ? null : () => _remover(c),
                              icon: const Icon(Icons.delete_outline),
                            ),
                        ],
                      ))),
                ],
              ),
            )),
            const Divider(height: 1),
            Padding(padding: const EdgeInsets.all(12), child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: TextField(
                  controller: _campoComentario,
                  enabled: !_postando,
                  minLines: 1, maxLines: 4, maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Escreva um comentário', border: OutlineInputBorder()),
                )),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Publicar comentário',
                  onPressed: _postando ? null : _postar,
                  icon: _postando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
                ),
              ],
            )),
          ]);
        },
      ),
    ))),
  );
}
