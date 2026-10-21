import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de um comentário lido do Firestore.
class ComentarioItem {
  final String id;
  final String mensagem;
  final String autor;
  final String autorUid;
  final String postId;
  final DateTime? dataCriacao;
  final bool aguardandoEnvio;

  const ComentarioItem({required this.id, required this.mensagem, required this.autor,
    required this.autorUid, required this.postId, required this.dataCriacao,
    required this.aguardandoEnvio});

  factory ComentarioItem.fromDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final dados = doc.data();
    return ComentarioItem(
      id: doc.id,
      mensagem: dados['texto'] as String,
      autor: dados['nome'] as String,
      autorUid: dados['uid'] as String,
      postId: dados['publicacaoId'] as String,
      dataCriacao: (dados['criadoEm'] as Timestamp?)?.toDate(),
      aguardandoEnvio: doc.metadata.hasPendingWrites,
    );
  }
}
