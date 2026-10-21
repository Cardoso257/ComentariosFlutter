import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'comentario.dart';

class ComentariosService {
  final DocumentReference<Map<String, dynamic>> post;
  ComentariosService(this.post);

  CollectionReference<Map<String, dynamic>> get _colecao =>
      post.collection('comentarios');

  Stream<List<ComentarioItem>> observar() => _colecao
      .orderBy('criadoEm')
      .snapshots(includeMetadataChanges: true)
      .map((s) => s.docs.map(ComentarioItem.fromDocument).toList());

  Future<void> salvar(String texto) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('É preciso estar logado para comentar.');
    final conteudo = texto.trim();
    if (conteudo.isEmpty || conteudo.length > 1000) {
      throw ArgumentError('O comentário deve ter entre 1 e 1000 caracteres.');
    }
    final nome = user.displayName?.trim();
    await _colecao.add({
      'texto': conteudo,
      'nome': nome == null || nome.isEmpty ? 'Anônimo' : nome,
      'uid': user.uid,
      'publicacaoId': post.id,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> apagar(ComentarioItem comentario) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || comentario.autorUid != user.uid) {
      throw StateError('Só é possível apagar comentários que você mesmo escreveu.');
    }
    await _colecao.doc(comentario.id).delete();
  }
}
