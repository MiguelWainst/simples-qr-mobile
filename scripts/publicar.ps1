param([string]$RepositoryName = 'simples-qr-mobile')
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)

function Invoke-Gh {
  param([string[]]$Arguments)
  $result = & gh @Arguments
  if ($LASTEXITCODE -ne 0) { throw "GitHub CLI falhou: $($Arguments[0]). Corrija o erro acima e execute novamente." }
  return ($result -join "`n")
}
function Check-Native {
  if ($LASTEXITCODE -ne 0) { throw 'A validação falhou. Corrija o erro acima antes de publicar.' }
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw 'Flutter não está no PATH. Adicione a pasta flutter\bin e abra um PowerShell novo.'
}
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  throw 'Instale GitHub CLI: winget install --id GitHub.cli -e . Depois abra um PowerShell novo e execute novamente.'
}
& gh auth status
if ($LASTEXITCODE -ne 0) { & gh auth login --web --git-protocol https; Check-Native }
$login = Invoke-Gh -Arguments @('api','user','--jq','.login')
if ($login -ne 'MiguelWainst') { throw "Conta autenticada: $login. Entre como MiguelWainst para atribuir as tarefas corretamente." }

# Completa os scaffolds oficiais de plataforma sem --overwrite.
& flutter create --platforms=android,web --org br.com.simplesqr --project-name simples_qr .
Check-Native
& flutter pub get
Check-Native
& dart format lib test
Check-Native
& flutter analyze
Check-Native
& flutter test
Check-Native
& flutter build web
Check-Native

$repo = "$login/$RepositoryName"
$existingRepo = & gh repo view $repo --json name 2>$null
if ($LASTEXITCODE -ne 0) {
  $null = Invoke-Gh -Arguments @('repo','create',$repo,'--public','--description','Simples QR: cardápio digital por QR code — Projeto Integrador Flutter')
}
$null = Invoke-Gh -Arguments @('auth','setup-git')
if (-not (Test-Path -LiteralPath '.git')) { & git init -b main; Check-Native }
$remotes = & git remote
if ($remotes -notcontains 'origin') { & git remote add origin "https://github.com/$repo.git"; Check-Native }
$origin = & git remote get-url origin
if ($origin -notmatch [regex]::Escape($repo)) { throw "Origin aponta para outro repositório: $origin" }
& git config user.name 'Miguel Wainstein'
& git config user.email '242078675+MiguelWainst@users.noreply.github.com'

foreach ($category in @('C1','C2','C3','C4','C5','C6')) {
  $null = Invoke-Gh -Arguments @('label','create',$category,'--repo',$repo,'--color','126B50','--force')
}
foreach ($level in @('obrigatório','desejável','opcional')) {
  $null = Invoke-Gh -Arguments @('label','create',$level,'--repo',$repo,'--color','315A95','--force')
}
$milestoneNames = @('Sprint 0 - Setup','Sprint 1 - Fundacao e Dados','Sprint 2 - Conectividade','Sprint 3 - Qualidade e Governanca')
$milestones = (Invoke-Gh -Arguments @('api',"repos/$repo/milestones?state=all&per_page=100")) | ConvertFrom-Json
foreach ($name in $milestoneNames) {
  if (-not ($milestones | Where-Object title -eq $name)) {
    $null = Invoke-Gh -Arguments @('api',"repos/$repo/milestones",'--method','POST','-f',"title=$name")
  }
}

& gh auth refresh -s project
Check-Native
if (Test-Path -LiteralPath '.publication.json') {
  $project = Get-Content -Encoding UTF8 -LiteralPath '.publication.json' -Raw | ConvertFrom-Json
} else {
  $project = (Invoke-Gh -Arguments @('project','create','--owner',$login,'--title','Simples QR - Projeto Integrador','--format','json')) | ConvertFrom-Json
  $project | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath '.publication.json' -Encoding utf8
}
$fields = (Invoke-Gh -Arguments @('project','field-list',"$($project.number)",'--owner',$login,'--format','json')) | ConvertFrom-Json
$statusField = $fields.fields | Where-Object name -eq 'Status'
$query = 'mutation($field:ID!){updateProjectV2Field(input:{fieldId:$field,singleSelectOptions:[{name:"Backlog",color:GRAY,description:"Trabalho futuro"},{name:"To Do",color:BLUE,description:"Pronto para iniciar"},{name:"In Progress",color:YELLOW,description:"Em desenvolvimento"},{name:"Review",color:PURPLE,description:"Aguardando revisão e evidência"},{name:"Done",color:GREEN,description:"Concluído e verificado"}]}){projectV2Field{... on ProjectV2SingleSelectField{id}}}}'
if (($statusField.options.name -join '|') -ne 'Backlog|To Do|In Progress|Review|Done') {
  $requestFile = Join-Path $env:TEMP 'simplesqr-graphql.json'
$requestJson = @{ query = $query; variables = @{ field = $statusField.id } } | ConvertTo-Json -Depth 10
[IO.File]::WriteAllText($requestFile, $requestJson, [Text.UTF8Encoding]::new($false))
$null = Invoke-Gh -Arguments @('api','graphql','--input',$requestFile)
}
$null = Invoke-Gh -Arguments @('project','edit',"$($project.number)",'--owner',$login,'--visibility','PUBLIC')
$fields = (Invoke-Gh -Arguments @('project','field-list',"$($project.number)",'--owner',$login,'--format','json')) | ConvertFrom-Json
$statusField = $fields.fields | Where-Object name -eq 'Status'
$items = (Invoke-Gh -Arguments @('project','item-list',"$($project.number)",'--owner',$login,'--limit','100','--format','json')) | ConvertFrom-Json
$existingIssues = (Invoke-Gh -Arguments @('issue','list','--repo',$repo,'--state','all','--limit','100','--json','title,url')) | ConvertFrom-Json
$backlog = Get-Content -Encoding UTF8 -LiteralPath 'docs/issues.json' -Raw | ConvertFrom-Json
foreach ($issue in $backlog) {
  $existing = $existingIssues | Where-Object title -eq $issue.title | Select-Object -First 1
  if ($existing) { $issueUrl = $existing.url } else {
    $bodyPath = Join-Path ([IO.Path]::GetTempPath()) ('simplesqr-issue-' + [guid]::NewGuid().ToString() + '.md')
    [IO.File]::WriteAllText($bodyPath,$issue.body,[Text.UTF8Encoding]::new($false))
    $issueUrl = Invoke-Gh -Arguments @('issue','create','--repo',$repo,'--title',$issue.title,'--body-file',$bodyPath,'--assignee',$login,'--label',$issue.category,'--label',$issue.level,'--milestone',$milestoneNames[$issue.sprint])
  }
  $item = $items.items | Where-Object { $_.content.url -eq $issueUrl } | Select-Object -First 1
  if (-not $item) {
    $item = (Invoke-Gh -Arguments @('project','item-add',"$($project.number)",'--owner',$login,'--url',$issueUrl,'--format','json')) | ConvertFrom-Json
    $option = $statusField.options | Where-Object name -eq $issue.status
    $null = Invoke-Gh -Arguments @('project','item-edit','--id',$item.id,'--project-id',$project.id,'--field-id',$statusField.id,'--single-select-option-id',$option.id)
  }
}
$null = Invoke-Gh -Arguments @('project','link',"$($project.number)",'--owner',$login,'--repo',$repo)
$projectUrl = "https://github.com/users/$login/projects/$($project.number)"
"# Links oficiais`n`n- Repositório: https://github.com/$repo`n- Quadro: $projectUrl`n" | Set-Content -LiteralPath 'docs/LINKS.md' -Encoding utf8
$ava = Get-Content -Encoding UTF8 -LiteralPath 'docs/AVA.md' -Raw
$ava = $ava.Replace('preencher com o link real após scripts/publicar.ps1',"https://github.com/$repo")
$ava = $ava.Replace("- Quadro GitHub Projects: https://github.com/$repo","- Quadro GitHub Projects: $projectUrl")
[IO.File]::WriteAllText((Join-Path (Get-Location) 'docs/AVA.md'),$ava,[Text.UTF8Encoding]::new($false))
& git add .
Check-Native
& git diff --cached --quiet
if ($LASTEXITCODE -eq 1) { & git commit -m 'feat: base Flutter e planejamento da Sprint 0'; Check-Native }
& git push -u origin main
Check-Native
Write-Host "Repositório: https://github.com/$repo"
Write-Host "Quadro: $projectUrl"
Write-Host 'Abra o Project, altere a visualização para Board e agrupe por Status caso esteja em Table. Confira os cinco status.'
Write-Host 'Confira a execução do CI e crie o Supabase antes de declarar a Sprint 0 totalmente concluída.'
Write-Host 'O texto para o AVA está em docs/AVA.md.'
