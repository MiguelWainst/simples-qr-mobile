# PROMPT_LOG — Governança de IA

## Ferramentas

| Ferramenta | Modelo | Finalidade |
|---|---|---|
| ChatGPT/Codex | Identificação exata não disponível | Leitura do enunciado, estrutura Flutter, backlog e documentação |

## #01 — 19/10/2026 — Miguel Wainstein — ChatGPT

**Objetivo:** preparar a Sprint 0 do Projeto Integrador.

**Prompt:** “Eu nao sei o que tem que fazer, faça voce TUDO, e me delegue apenas o que voce realmente não pode fazer. Se precisar de alguma coisa me diga sempre pra eu te dar”. Complemento: “O grupo é só eu; não existe repo ainda, pode criar. O projeto meu é basicamente um app de cardapio online pra ler por qr code”.

**Resultado:** base proposta pela IA, aguardando revisão e compreensão pessoal do autor. Não se afirma revisão humana já realizada.

**Arquivos:** lib/, test/, scripts/, supabase/, README.md e docs/.

**Análise crítica realizada pelo assistente:** não adicionar botões de login/QR sem implementação; catálogo vazio explícito na Sprint 0; persistir a escolha de tema; separar preferências da UI; não confundir backend planejado com provisionado; não registrar como executados testes bloqueados pelo ambiente; revisão de PR por colega é pendência a alinhar em projeto individual.

## Refatorações manuais críticas

Ainda não realizadas pelo autor. O mínimo final é duas refatorações reais com antes/depois, problema, justificativa, responsável e link do commit. Não inventar histórico de correções para satisfazer a rubrica. Registrar aqui conforme ocorrerem durante as próximas sprints.

## Revisão do autor antes de entregar

- Executar e compreender o fluxo de tema e a injeção de dependências.
- Revisar o SQL e testar RLS com duas contas distintas antes de habilitar o backend.
- Ler as limitações em docs/VALIDACAO.md.

## Lições

Uso de IA não substitui compreensão na arguição. Geração de código, execução de testes e validação humana são etapas diferentes e devem ter evidências separadas.

## #02 — 26/10/2026 — Projeto final

**Prompt do autor:** “agora vamos partir para o projeto final, faça o planejamento e depois execute, quero algo funcional para hoje ok?”

**Execução pela IA:** plano em docs/PLANO_FINAL.md; branch feat/projeto-final e PR #46; implementação de autenticação Supabase, catálogo paginado, CRUD, QR, favoritos e cache local, componentes e testes. Terminal do ambiente bloqueado; edições realizadas via GitHub, validação delegada ao GitHub Actions. Isso não é uma revisão humana.

**Decisões críticas:** preço inteiro em centavos; cache apenas de dados públicos; exclusão de cache após resposta de cardápio retirado do ar; guardas de sessão mais RLS do servidor; rejeição de conteúdo QR arbitrário; tratamento de respostas de busca fora de ordem; confirmação antes de excluir/sair de formulário. Não foram inseridos dados ou credenciais fictícios para simular integração.

**Dependências de validação:** Project URL/chave pública reais, teste de conta e e-mail, câmera em aparelho e isolamento RLS com duas contas. Não registrar como concluídas sem evidência.

**Refatorações manuais do aluno:** continuam pendentes. As alterações geradas pela IA não contam como duas refatorações manuais feitas pelo autor.
