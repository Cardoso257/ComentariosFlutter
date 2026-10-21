# Questões

1. O Firebase Authentication distingue cada conta por um UID único. No momento de salvar
   um comentário, o app guarda o currentUser.uid no documento, e as regras do Firestore
   verificam se esse valor é igual ao request.auth.uid de quem está enviando.

2. Os comentários ficam dentro da subcoleção publicacoes/{id}/comentarios, e cada documento
   também registra o publicacaoId. Dessa forma, a tela de uma publicação lê apenas os
   comentários que pertencem a ela.

3. O StreamBuilder fica ouvindo o stream de snapshots do Firestore e redesenha a lista
   toda vez que chega uma mudança, então não é necessário recarregar a tela manualmente.

4. Todas as contas usam o mesmo projeto Firebase e ouvem a mesma subcoleção por meio de
   snapshots(). Ao salvar um comentário, o Firestore repassa a alteração para os usuários
   que estão com aquela discussão aberta.
