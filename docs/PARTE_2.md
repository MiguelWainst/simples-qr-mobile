# Parte 2 — fotos e confirmação de e-mail

## Ativar fotos (uma vez)

1. No Supabase do Simples QR, abra SQL Editor → New query.
2. Cole todo o conteúdo de `supabase/migrations/002_menu_photos.sql` e clique Run.
3. Atualize o app. Em Meus restaurantes → Editar restaurante ou Produtos → Adicionar/Editar, use Escolher foto e Salvar.

Não é necessário criar outro projeto nem apagar dados. O SQL adiciona duas colunas opcionais e o bucket público `menu-photos`, com limite de 5 MB e escrita apenas na pasta do usuário autenticado. As fotos são públicas mesmo enquanto o restaurante está em rascunho; use somente imagens destinadas ao cardápio.

O app solicita redução para até 1200 × 1200 e qualidade 75 no Android/web, verifica tamanho e assinatura JPG/PNG/WebP, exibe prévia e fases de envio. O envio tem limite de espera de 45 segundos; falhas preservam o formulário para tentar novamente. Fotos são opcionais. O catálogo renderiza miniaturas e usa um ícone se a foto falhar. O cache offline guarda dados e URLs, não garante fotos offline. Arquivos antigos substituídos ou de edições abandonadas podem permanecer no Storage; não são apagados automaticamente para evitar quebrar referências em caso de falha de rede.

## Se o e-mail de confirmação não chega

O app agora oferece reenvio com intervalo de 60 segundos, aviso para conferir spam e mensagens separadas para limite de envio, falha no serviço e falta de conexão. O retorno do servidor não comprova entrega na caixa de entrada.

Para entregar e-mails a usuários reais, configure SMTP próprio em Authentication → Email/SMTP settings (a organização do menu pode variar). O serviço padrão do Supabase só envia a membros da organização e tem limites baixos. Use os dados SMTP do seu provedor, remetente/domínio verificado e mantenha segredos somente no painel. Não cole senha SMTP no código.

Confira Authentication → Logs: procure falhas de envio no horário da tentativa. Confira também Users: se o usuário foi criado e ainda está pendente de confirmação, o problema pode ser entrega. Se já foi confirmado, use Entrar/Recuperar senha.

Em Authentication → URL Configuration, autorize os endereços usados:
- `http://localhost:8080/`
- `https://miguelwainst.github.io/simples-qr-mobile/`
- `simplesqr://auth-callback`

Para uma demonstração acadêmica sem depender de e-mail, pode-se desativar Confirm email em Authentication → Sign In / Providers → Email. Nesse modo novos cadastros entram diretamente e os endereços não são verificados; isso NÃO corrige o envio e a recuperação de senha continua dependendo de SMTP. Contas antigas pendentes devem ser conferidas em Users. Não desativei essa configuração automaticamente.

Documentação oficial: https://supabase.com/docs/guides/auth/auth-smtp

## Teste manual após ativar

1. Cadastre/entre com sua conta. Com confirmação habilitada, confira o recebimento real e use o reenvio se necessário.
2. Adicione foto a um produto e ao restaurante, salve e abra o cardápio público.
3. Troque/remova uma foto e confira novamente.
4. Cancele a seleção, tente um formato inválido e desligue a conexão durante o envio: o formulário deve continuar utilizável e preservar os campos.
5. No Android, confira seleção de foto e no Chrome confira uma foto grande do celular. A fluidez em dispositivo real precisa desse teste; compilação e testes automatizados não substituem a medição.
