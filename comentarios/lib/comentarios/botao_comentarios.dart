import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'comentarios_page.dart';

/// Botão que abre a tela de comentários de uma publicação.
/// Recebe a referência do documento da publicação e o widget que a exibe.
class BotaoComentarios extends StatelessWidget {
  final DocumentReference<Map<String, dynamic>> postRef;
  final Widget postWidget;

  const BotaoComentarios({super.key, required this.postRef,
    required this.postWidget});

  @override
  Widget build(BuildContext context) => TextButton.icon(
    icon: const Icon(Icons.chat_bubble_outline),
    label: const Text('Ver comentários'),
    onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ComentariosPage(
        postRef: postRef,
        postWidget: postWidget,
      ),
    )),
  );
}
