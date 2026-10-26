# Matriz de requisitos

Atualizado em 26/10/2026. Implementação na branch feat/projeto-final / PR #46. "Implementado" descreve código existente; validação em dispositivo e serviços reais é indicada separadamente. Evidências em VALIDACAO.md.

| ID | Requisito / issue | Sprint planejada | Estado |
|---|---|---|---|
| C1.1 | [C1.1] Identidade visual e tokens centralizados | 3 | Implementado — tema centralizado |
| C1.2 | [C1.2] Temas Claro/Escuro/Sistema persistidos | 3 | Implementado e teste automatizado |
| C1.3 | [C1.3] Biblioteca de pelo menos dez componentes próprios | 3 | Implementado — 11 componentes próprios |
| C1.4 | [C1.4] Responsividade 360x640, paisagem e teclado | 3 | Parcial — teste da base; validar todas as telas |
| C1.5 | [C1.5] Acessibilidade e fonte ampliada | 3 | Parcial — labels e tooltips; validar leitor de tela |
| C1.6 | [C1.6] Feedback de ações e estados vazios | 3 | Implementado — loading, erro, vazio e confirmação |
| C2.1 | [C2.1] Entregar no mínimo dez telas funcionais | 1 | Implementado — 17 telas de fluxo; validar ponta a ponta |
| C2.2 | [C2.2] Rotas centralizadas e retorno de resultados | 1 | Implementado — rotas e retorno dos formulários |
| C2.3 | [C2.3] Parâmetros tipados entre telas | 1 | Implementado — MenuArgs, ProductArgs, AdminArgs e EditorArgs |
| C2.4 | [C2.4] Auth real: cadastro, login, recuperação, sessão e logout | 1 | Implementado — teste Supabase real pendente |
| C2.5 | [C2.5] Guardas e autorização no backend por proprietário | 1 | Implementado — guardas; teste RLS entre contas pendente |
| C2.6 | [C2.6] Liberar controllers e verificar mounted | 1 | Implementado — dispose, mounted e ciclo da câmera |
| C2.7 | [C2.7] PopScope e confirmação de alterações não salvas | 1 | Implementado — confirmação de descarte |
| C2.8 | [C2.8] Validação dos formulários e regras de negócio | 1 | Implementado e testes de regras |
| C2.9 | [C2.9] ViewModels sem regra de negócio nas Views | 1 | Parcial — ViewModels principais; revisar orquestração das demais views |
| C3.1 | [C3.1] Lazy loading nas coleções | 2 | Implementado — ListView.builder |
| C3.2 | [C3.2] Eliminar renderização eager de coleções variáveis | 2 | Implementado nas listas principais |
| C3.3 | [C3.3] Paginar catálogos remotos | 2 | Implementado — páginas de 20 itens |
| C3.4 | [C3.4] Busca com debounce e filtros por categoria | 2 | Implementado — debounce e categorias |
| C4.1 | [C4.1] CRUD SQLite de favoritos e catálogos salvos | 1 | Implementado — SQLite Android; navegador usa preferências |
| C4.2 | [C4.2] DatabaseHelper Singleton e migrações | 1 | Implementado — singleton e schema v2 |
| C4.3 | [C4.3] DTOs tipados com toMap/fromMap/toJson/fromJson | 1 | Implementado e teste de roundtrip |
| C4.4 | [C4.4] Consulta offline e indicação de última sincronização | 1 | Implementado e teste de fallback offline |
| C4.5 | [C4.5] Preferências persistidas e tokens seguros | 1 | Implementado — secure storage no Android; SDK no navegador |
| C4.6 | [C4.6] Confirmação e desfazer de exclusões | 1 | Implementado — favoritos com confirmação e desfazer |
| C5.1 | [C5.1] Provisionar Supabase e dados compartilhados reais | 2 | Provisionado segundo relato do autor; integração pendente |
| C5.2 | [C5.2] Consumir catálogo pela API REST JSON | 2 | Implementado — Supabase/PostgREST |
| C5.3 | [C5.3] Estados carregando, erro, sucesso e vazio | 2 | Implementado |
| C5.4 | [C5.4] Tratar timeout, rede, HTTP, permissão e JSON inválido | 2 | Implementado — timeouts, mensagens e fallback |
| C5.5 | [C5.5] RLS por proprietário e nenhum segredo versionado | 2 | SQL RLS aplicado segundo autor; auditoria entre contas pendente |
| C5.6 | [C5.6] Isolar SDK/HTTP em serviços e repositórios | 2 | Implementado — CatalogRepository |
| C6.1 | [C6.1] Documentar e manter arquitetura MVVM | 3 | Implementado; refinamento MVVM documentado em C2.9 |
| C6.2 | [C6.2] Flutter analyze limpo e Clean Code | 3 | Analyze aprovado; fontes formatadas incorporadas |
| C6.3 | [C6.3] Testar DTOs, validação, regras e fluxos principais | 3 | Testes automatizados; integração real pendente |
| C6.4 | [C6.4] Governança com duas refatorações manuais reais | 3 | Pendente — duas refatorações MANUAIS do aluno |
| C6.5 | [C6.5] Branches, PRs e alinhar revisão do projeto individual | 3 | PR #46 criado; revisão humana pendente |
| C6.6 | [C6.6] Manter quadro e marcos por sprint | 3 | Quadro e 45 issues existentes; atualizar cartões após aceite |
| C6.7 | [C6.7] README com matriz, execução, imagens e evidências | 3 | README e roteiro atualizados; imagens/vídeo pendentes |
| S0-base | [Sprint 0] Validar base MVVM, temas e tela inicial | 0 | Validado pelos logs da Sprint 0 |
| S0-backend | [Sprint 0] Criar projeto Supabase e aplicar RLS inicial | 0 | SQL aplicado segundo relato do autor |
| S0-entrega | [Sprint 0] Conferir links, papéis e enviar no AVA | 0 | Envio AVA não confirmado |
| QR | [C5.8] Ler QR code e abrir cardápio identificado | 2 | Implementado — teste de câmera em aparelho pendente |
| CATALOGO | [Funcionalidade] CRUD de restaurante, categorias e produtos | 1 | Implementado — teste com dados reais pendente |
| FAVORITOS | [Funcionalidade] Favoritos e consulta de cardápios offline | 2 | Implementado — testes de persistência e cache |
| CI | [C6.9] CI com analyze, testes e build | 0 | Analyze, 14 testes, web e Android aprovados na CI |

