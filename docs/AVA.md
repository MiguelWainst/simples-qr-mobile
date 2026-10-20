PROJETO: Simples QR
PROJETO INTEGRADOR: Simples QR — Cardápio digital por QR code

1. LINKS OFICIAIS:
- Repositório GitHub: https://github.com/MiguelWainst/simples-qr-mobile
- Quadro GitHub Projects: https://github.com/users/MiguelWainst/projects/1

2. INTEGRANTES E PAPÉIS TÉCNICOS:
- Miguel Wainstein (@MiguelWainst) — Tech Lead/Arquiteto, UI/UX e Design System, Dados e Persistência Local, Backend/APIs, QA e Governança de IA. Projeto individual.

3. RECORTE DO PROJETO INTEGRADOR (ESCOPO MÓVEL):
O Simples QR atende pequenos restaurantes e clientes que desejam consultar o cardápio pelo celular a partir de um QR code. O aplicativo contemplará consulta pública por categorias, busca, detalhes dos produtos, favoritos e acesso offline ao conteúdo já carregado.
O proprietário terá uma área autenticada para manter dados do restaurante, categorias e produtos. Pedidos, pagamentos e delivery não fazem parte deste recorte.

4. BACKEND ESCOLHIDO:
Supabase.
Justificativa: autenticação, PostgreSQL e API REST gerenciados reduzem o esforço operacional do projeto individual. Políticas RLS limitarão a edição ao proprietário e a consulta pública aos cardápios publicados. SQLite será implementado explicitamente para dados locais e consulta offline.

Observação da Sprint 0: base Flutter com análise sem problemas, 2 testes aprovados e build web concluído. O projeto Supabase ainda precisa ser provisionado; a escolha do backend e a migração SQL com RLS estão documentadas. Conferir a visibilidade e os cartões do quadro antes do envio.
