# Plano do projeto final — 26/10/2026

Objetivo: fluxo completo de cadastro do proprietário, publicação e consulta de cardápio por QR code, mantendo Flutter/Dart e Supabase.

## Ordem de execução
1. Dados tipados, validação, serviço Supabase e autenticação persistida.
2. Login, cadastro, recuperação e alteração de senha; proteção de telas administrativas.
3. CRUD de restaurantes, categorias e produtos com autorização RLS existente.
4. Catálogo público paginado, busca, detalhes e QR code (geração/leitura).
5. Favoritos e cache offline SQLite no Android; persistência equivalente no navegador.
6. Temas, acessibilidade, formulários com confirmação ao sair, testes e build automatizado.
7. Documentação e roteiro de demonstração.

## Telas
Início; scanner; cardápio; detalhes do produto; favoritos; login; cadastro; recuperação; nova senha; restaurantes do proprietário; formulário de restaurante; categorias; formulário de categoria; produtos; formulário de produto; QR do restaurante; aparência.

## Critérios de aceite
- Proprietário autentica, cria restaurante/categoria/produto e publica.
- Visitante sem login abre slug/link/QR e consulta produtos disponíveis.
- Produto indisponível e restaurante não publicado não aparecem para visitantes.
- Busca e filtros funcionam; favoritos e catálogo previamente carregado persistem.
- Logout impede acesso às rotas administrativas.
- Analyze, testes e build web aprovados; câmera e APK precisam de teste em aparelho.

## Dependências externas
Usuário fornece somente Project URL e chave pública anon/publishable. Nunca service_role. Supabase já provisionado conforme relato do usuário; SQL inicial aplicado. Configurar URLs de retorno de autenticação no painel para produção. Hospedagem HTTPS necessária para compartilhar cardápios e câmera web.

## Limites honestos
A conclusão será registrada somente com evidências. Revisão humana e duas refatorações manuais exigidas pela disciplina dependem do aluno e não serão inventadas. Integração real depende de configuração Supabase e teste com conta do proprietário.
