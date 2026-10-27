# Publicação do MVP

O endereço do cardápio agora é automático. Não é preciso digitar slug nem alterar o banco. O link dos restaurantes existentes é preservado ao editar o nome.

## Ativação única no GitHub
1. Abra https://github.com/MiguelWainst/simples-qr-mobile/settings/pages
2. Em Build and deployment > Source, escolha GitHub Actions.
3. Em Actions > Publicar web, use Run workflow na branch main se necessário.

O workflow publica a versão de main. Endereço esperado após a publicação terminar:
https://miguelwainst.github.io/simples-qr-mobile/

O build define o caminho base do site e a URL pública usada nos QR codes. Os dados continuam no mesmo projeto Supabase. Não cria um banco novo.

## Supabase
Para confirmação de e-mail e recuperação de senha na versão publicada, adicione em Authentication > URL Configuration:
- Site URL: https://miguelwainst.github.io/simples-qr-mobile/
- Redirect URLs: https://miguelwainst.github.io/simples-qr-mobile/
- Mantenha http://localhost:8080/ para testes locais e simplesqr://auth-callback para Android.

## Demonstração
Entre com sua conta, crie restaurante sem preencher endereço, adicione categoria/produto, publique e abra o QR code. Leia com a câmera de outro celular e confira se o mesmo cardápio aparece sem login. Um QR criado na versão local continua apontando para localhost; use o QR da versão publicada.
