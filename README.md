# Simples QR

Cardápio digital por QR code para pequenos restaurantes. Projeto individual de **Miguel Wainstein (@MiguelWainst)**, responsável por arquitetura, UI/UX, dados, backend, testes e governança.

## Uso

O proprietário cria uma conta, cadastra restaurante, categorias e produtos e publica o cardápio. O cliente consulta o cardápio sem login pelo link/QR, busca produtos, filtra categorias e salva favoritos no aparelho. Pedidos, pagamentos e delivery ficam fora do escopo.

## Rodar no Windows

Requisitos: Flutter 3.47.6 / Dart 3.13, Chrome ou Android SDK.

```powershell
git fetch origin
git switch feat/projeto-final
git pull --ff-only
flutter pub get
flutter run -d chrome --web-port 8080
```

No primeiro acesso, informe a **Project URL** e a **chave pública publishable ou anon** do seu Supabase. Não use senha, secret ou service_role. A configuração é persistida neste aparelho. No Android, conecte um celular com depuração USB e execute `flutter run`.

Para distribuir o app conectado ao seu backend, configure durante o build:

```powershell
flutter build web --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co --dart-define=SUPABASE_ANON_KEY=SUA_CHAVE_PUBLICA --dart-define=PUBLIC_APP_URL=https://SEU-SITE/
flutter build apk --debug --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co --dart-define=SUPABASE_ANON_KEY=SUA_CHAVE_PUBLICA --dart-define=PUBLIC_APP_URL=https://SEU-SITE/
```

URL e chave pública identificam o projeto; a autorização é feita pelas políticas RLS. Tokens de sessão não devem ser versionados.

## Supabase

O autor informou que criou o projeto e executou `supabase/migrations/001_initial.sql` com sucesso. Não execute novamente em um banco que já tem essas tabelas.

Em **Authentication > URL Configuration**, cadastre:
- desenvolvimento web: `http://localhost:8080/`;
- seu endereço HTTPS de produção;
- retorno Android: `simplesqr://auth-callback`.

Use a URL de produção como Site URL quando publicar. Mantenha a confirmação de e-mail e confirme a conta pelo e-mail recebido. O app implementa cadastro, login, recuperação, nova senha, restauração de sessão e logout. Validação real de e-mails depende do serviço Supabase do autor.

## Demonstração

1. Abra a área do proprietário e crie/confirme sua conta.
2. Adicione um restaurante com endereço como `cafe-do-miguel`.
3. Crie uma categoria e um produto com preço e ingredientes.
4. Edite o restaurante e ative **Publicar cardápio**.
5. Abra **Ver cardápio**; teste busca, categoria e favoritos.
6. Abra **QR code**; copie o link e teste em uma janela anônima.
7. Reabra um cardápio já consultado sem internet; a data da cópia deve aparecer.
8. Teste editar, indisponibilizar produto, excluir e sair da conta.

O QR gerado em localhost só funciona naquele computador. Para abrir em outro celular, publique o build web em HTTPS e use o endereço público. A câmera web também precisa de HTTPS ou localhost.

## Arquitetura

Flutter / Dart, MVVM com ChangeNotifier e dependências por construtor.
- `lib/domain`: DTOs tipados e regras de validação.
- `lib/data/remote`: Supabase Auth/REST, armazenamento da sessão e mensagens de erro.
- `lib/data/local`: DatabaseHelper singleton SQLite no Android e preferências.
- `lib/features`: autenticação, catálogo, favoritos, QR, administração e aparência.
- `lib/core`: rotas com argumentos tipados, serviços e temas.
- `lib/shared/widgets`: componentes reutilizáveis.

O catálogo usa paginação de 20 produtos, busca com debounce e listas lazy. O cache inclui somente consultas públicas sem filtros, com data e indicação de cópia parcial. A consulta offline cobre os produtos já carregados, não garante o catálogo inteiro. Dados removidos do servidor deixam o cache quando a consulta online confirma que o cardápio foi retirado do ar.

No Android, cache/favoritos usam SQLite e sessão usa flutter_secure_storage. No navegador, cache/favoritos usam persistência do navegador e a sessão usa a persistência padrão do SDK. Favoritos são locais ao aparelho. Alterações administrativas exigem internet e autorização do servidor.

## Telas implementadas

Início, scanner, cardápio, detalhes, favoritos, login, cadastro, recuperação, nova senha, meus restaurantes, edição de restaurante, categorias, edição de categoria, produtos, edição de produto, QR e aparência; além da conexão inicial de desenvolvimento.

## Validação

```powershell
dart format lib test
flutter analyze
flutter test
flutter build web
flutter build apk --debug
```

O workflow Flutter verifica a formatação, executa análise, testes e builds e fornece artefatos web e APK de teste. A rodada de 26/10 aprovou analyze, 14 testes e ambos os builds. Consulte [evidências e limitações](docs/VALIDACAO.md); implementação não significa teste de câmera, e-mail ou RLS realizado.

## Entrega acadêmica

[Plano](docs/PLANO_FINAL.md) · [Governança de IA](PROMPT_LOG.md) · [Matriz de requisitos](docs/REQUISITOS.md) · [Quadro](https://github.com/users/MiguelWainst/projects/1) · [PR da implementação](https://github.com/MiguelWainst/simples-qr-mobile/pull/46)

As duas refatorações **manuais do aluno**, revisão humana, vídeo, capturas e defesa oral não são substituídas pela geração do código. A forma de revisão de um projeto individual deve ser alinhada com o professor. Não rode novamente o antigo script publicar.ps1.
