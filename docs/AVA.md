PROJETO: Simples QR
PROJETO INTEGRADOR: Simples QR — Cardápio digital por QR code

1. LINKS OFICIAIS:
- Repositório GitHub: preencher com o link real após scripts/publicar.ps1
- Quadro GitHub Projects: preencher com o link real após scripts/publicar.ps1

2. INTEGRANTES E PAPÉIS TÉCNICOS:
- Miguel Wainstein (@MiguelWainst) — Tech Lead/Arquiteto, UI/UX e Design System, Dados e Persistência Local, Backend/APIs, QA e Governança de IA. Projeto individual.

3. RECORTE DO PROJETO INTEGRADOR (ESCOPO MÓVEL):
O Simples QR atende pequenos restaurantes e clientes que desejam consultar o cardápio pelo celular a partir de um QR code. O aplicativo contemplará consulta pública por categorias, busca, detalhes dos produtos, favoritos e acesso offline ao conteúdo já carregado.
O proprietário terá uma área autenticada para manter dados do restaurante, categorias e produtos. Pedidos, pagamentos e delivery não fazem parte deste recorte.

4. BACKEND ESCOLHIDO:
Supabase.
Justificativa: autenticação, PostgreSQL e API REST gerenciados reduzem o esforço operacional do projeto individual. Políticas RLS limitarão a edição ao proprietário e a consulta pública aos cardápios publicados. SQLite será implementado explicitamente para dados locais e consulta offline.

ANTES DE ENVIAR: substituir os dois links, executar a validação e informar honestamente se o projeto Supabase ainda não estiver criado.
