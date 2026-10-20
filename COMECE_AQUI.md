# Entrega da Sprint 0

## 1. Publicar e validar

Extraia o ZIP. Abra o PowerShell dentro da pasta que contém `pubspec.yaml`.

```powershell
.\scripts\publicar.ps1
```

O script usa Flutter, Git e GitHub CLI. Se faltar o GitHub CLI, execute `winget install --id GitHub.cli -e`, abra um terminal novo e rode novamente. Se faltar Flutter no PATH, adicione a pasta `flutter\bin` do seu SDK.

O login é feito no seu navegador pelo GitHub CLI. Nunca cole senha, token, código de recuperação ou chave privada no chat. A autorização `project` é necessária para criar e organizar o GitHub Projects.

O script valida o código, cria um repositório público novo `MiguelWainst/simples-qr-mobile`, cria quatro milestones (Sprints 0 a 3), nove labels, 45 issues atribuídas a você e um GitHub Project. Em caso de erro, pare e envie a mensagem de erro ao assistente; não declare que a validação passou.

O script não altera nem apaga outros repositórios. Se `origin` apontar para outro projeto, interrompe.

## 2. Conferir o quadro

Abra o link impresso. Se a visualização estiver em Table, altere o layout para **Board** e agrupe por **Status**. Confira os cinco status: Backlog, To Do, In Progress, Review e Done. Colunas vazias são normais na Sprint 0; nenhum item foi falsamente marcado como concluído.

## 3. Criar o backend

Entre em https://supabase.com/dashboard e crie um projeto na sua conta. Use o plano gratuito; não ative recursos pagos. Defina a senha do banco pessoalmente e guarde-a fora do código.

No **SQL Editor**, execute o conteúdo de `supabase/migrations/001_initial.sql` no projeto novo. Confirme as tabelas `restaurants`, `categories` e `products` e RLS habilitado. Não execute o script em banco existente com dados de outro projeto.

O schema está preparado; a integração do app ao Auth e ao catálogo real é trabalho da Sprint 1. A chave service_role e a senha do banco nunca devem ir para o app ou repositório.

## 4. Conferir e entregar

- Rode `flutter run -d chrome` e confira Início → Aparência → Claro/Escuro/Sistema.
- Abra o GitHub e confirme os arquivos e o workflow verde.
- Leia `docs/AVA.md`, que terá os links preenchidos pelo script.
- Copie o texto e envie no AVA. Se alguma etapa falhou, informe a pendência; não apresente a Sprint como completa.
- Alinhe com o professor a forma de revisão por pares em projeto individual.

## O que existe neste pacote

Base MVVM com duas telas, temas e preferência persistida; scaffolds oficiais Android/web; testes escritos; CI; SQL inicial com RLS; backlog rastreável; README e governança de IA. Nenhuma conta, repositório, quadro ou backend foi criado remotamente pelo assistente neste ambiente.
