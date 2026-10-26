# Evidências de validação

## Sprint 0
Em 19/10/2026, o autor forneceu logs de format, analyze sem problemas, dois testes aprovados, build web e push do commit 47bac38.

## Projeto final — 26/10/2026
A implementação está no PR #46, branch feat/projeto-final. O terminal do ambiente do assistente não pôde iniciar por restrição do sandbox; a compilação foi executada pelo GitHub Actions, sem alegar execução local.

Primeira rodada completa aprovada: commit 360077b8e519d2353951d0a3006ce19e613ea425, execução [40412600690](https://github.com/MiguelWainst/simples-qr-mobile/actions/runs/40412600690):
- flutter analyze: nenhum diagnóstico;
- flutter test: 11 testes aprovados;
- flutter build web: sucesso;
- flutter build apk --debug: sucesso.

Rodada final aprovada: commit 636233d260f5f1719bfaa97fa24b4bf747af76ae, execução [40413036561](https://github.com/MiguelWainst/simples-qr-mobile/actions/runs/40413036561):
- flutter analyze: No issues found;
- flutter test: **14 testes aprovados**, incluindo SQLite real e telas de cadastro/favoritos;
- flutter build web: sucesso;
- flutter build apk --debug: sucesso.

[APK de teste (ZIP)](https://github.com/MiguelWainst/simples-qr-mobile/actions/runs/40413036561/artifacts/12693844851) · [Build web (ZIP)](https://github.com/MiguelWainst/simples-qr-mobile/actions/runs/40413036561/artifacts/12694785221).

As fontes formatadas e pubspec.lock produzidos por essa execução foram incorporados ao repositório, sem alterações funcionais. A CI voltou a exigir formatação sem diferenças. Os artefatos são do commit validado acima; não incluem configuração privada nem URL/chave pública do backend do autor.

## O que os testes cobrem
Regras de preço em centavos, formato de QR/link, DTOs, e-mail/senha/slug, CRUD de favoritos e cache, fallback offline, invalidação de cardápio despublicado, recuperação após falha de conexão, persistência do tema e navegação da base em tela pequena. Testes de fluxo e SQLite adicionados na rodada complementar.

## Limites
- O usuário informou que o SQL do Supabase foi aplicado com sucesso; não foi feita inspeção remota do banco pelo assistente.
- Project URL e chave pública não foram fornecidos nesta etapa. Não se afirma login ou CRUD testados no servidor real.
- O build não comprova câmera funcionando em aparelho, recebimento de e-mail, RLS entre duas contas ou usabilidade em todas as telas.
- A consulta offline usa somente os produtos carregados anteriormente. Android usa SQLite; navegador usa preferências locais.
- O APK é de teste, assinado para desenvolvimento. Não é uma publicação em loja.
- Sem hospedagem HTTPS configurada, um link de localhost não abre o cardápio em outro aparelho.
- Refatorações manuais do aluno, revisão humana, vídeo e capturas ainda dependem de evidências próprias.

## Aceite em dispositivo e backend reais
1. Configurar URL/chave pública no primeiro acesso; autorizar URLs de retorno no painel Supabase.
2. Criar e confirmar conta; entrar e recuperar senha por e-mail.
3. Criar restaurante, categoria e produto; publicar e abrir o link em janela anônima.
4. Confirmar que itens indisponíveis e restaurantes em rascunho não aparecem publicamente.
5. Entrar com segunda conta e verificar ausência de acesso de edição aos dados da primeira; verificar políticas RLS também na API.
6. Testar leitura de QR no celular, fonte ampliada, orientação horizontal e teclado.
7. Carregar cardápio, desligar internet, reabrir e conferir indicação da cópia local.
8. Testar logout e bloqueio das telas administrativas.
