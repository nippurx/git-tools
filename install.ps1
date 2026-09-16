# Script de instalacion de git-tools para PowerShell / Windows

param(
    [string]$GitHubOwner = "",
    [switch]$NonInteractive
)

Write-Host "Configurando alias de git-tools..." -ForegroundColor Cyan

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Git no esta instalado o no esta disponible en PATH."
    exit 1
}

$aliasStart = '!f(){ msg="Initial commit"; remote=""; for arg in "$@"; do case "$arg" in http://*|https://*|git@*) remote="$arg" ;; *) msg="$arg" ;; esac; done; git init || exit 1; git branch -M main || exit 1; if ! git config user.name >/dev/null 2>&1 || ! git config user.email >/dev/null 2>&1; then echo "Advertencia: configura user.name y user.email antes de crear commits."; fi; git add . || exit 1; if git rev-parse --verify HEAD >/dev/null 2>&1; then if ! git diff --cached --quiet; then git commit -m "$msg" || exit 1; fi; else git commit -m "$msg" || git commit --allow-empty -m "$msg" || exit 1; fi; if [ -z "$remote" ]; then remote=$(git remote get-url origin 2>/dev/null || true); fi; if [ -z "$remote" ]; then owner=$(git config --global --get git-tools.github-owner 2>/dev/null || true); repo=${PWD##*/}; if [ -n "$owner" ]; then remote="https://github.com/$owner/$repo.git"; echo "Usando repositorio remoto detectado: $remote"; fi; fi; if [ -z "$remote" ]; then echo "ERROR: no se encontro un repositorio remoto. Usa: git start \"$msg\" https://github.com/usuario/repositorio.git"; exit 1; fi; current=$(git remote get-url origin 2>/dev/null || true); if [ "$current" != "$remote" ]; then git remote remove origin 2>/dev/null || true; git remote add origin "$remote" || exit 1; fi; git push -u origin main || exit 1; echo "Proyecto inicializado y publicado en: $remote"; }; f'

$aliasBackup = '!sh -c "d=$(date +%Y-%m-%d-%H%M%S); git add .; git diff --cached --quiet || git commit -m \"Backup $d\"; git tag backup-$d; git push origin HEAD; git push origin backup-$d"'

$aliasRelease = '!f(){ msg=${1:-"Version estable"}; base=v$(date +%Y.%m.%d); tag=$base; n=1; git remote get-url origin >/dev/null 2>&1 || { echo "ERROR: no existe el remoto origin."; exit 1; }; git add . || exit 1; git commit -m "$msg" || true; git push origin main || exit 1; while git rev-parse -q --verify "refs/tags/$tag" >/dev/null || git ls-remote --tags origin | grep -q "$tag"; do tag="$base.$n"; n=$((n+1)); done; git tag -a "$tag" -m "$msg" || exit 1; git push origin "$tag" || exit 1; echo "Release creado: $tag"; }; f'

$aliasRollback = '!f(){ tag=${1:-""}; git fetch --tags; if [ -z "$tag" ]; then tag=$(git for-each-ref --sort=-creatordate --format "%(refname:short)" refs/tags | grep -E "^(backup-|release-|v)" | head -n 1); if [ -z "$tag" ]; then echo "No se encontraron ni backups ni releases."; exit 1; fi; echo "No se especifico tag, usando el ultimo encontrado: $tag"; fi; git reset --hard "$tag"; if git remote | grep -q origin; then git push origin main --force; fi; echo "Rollback completado a: $tag"; }; f'

$aliasRollbackRelease = '!f(){ tag=${1:-""}; git fetch --tags; if [ -z "$tag" ]; then tag=$(git for-each-ref --sort=-creatordate --format "%(refname:short)" refs/tags | grep -E "^(release-|v)" | head -n 1); if [ -z "$tag" ]; then echo "No se encontraron releases para volver atras."; exit 1; fi; echo "Rollback a release completado: $tag"; }; f'

function Set-GitAlias {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    # Windows PowerShell 5.1 reconstruye la linea de comandos de programas
    # nativos. Hay que escapar las comillas segun las reglas de argv de Windows
    # para que el alias completo llegue a Git como un solo argumento.
    $escapedValue = '"' + ($Value -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = "git"
    $startInfo.Arguments = "config --global alias.$Name $escapedValue"
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardError = $true

    $process = [System.Diagnostics.Process]::Start($startInfo)
    $errorOutput = $process.StandardError.ReadToEnd()
    $process.WaitForExit()

    if ($process.ExitCode -ne 0) {
        if ($errorOutput) {
            Write-Host $errorOutput -ForegroundColor Red
        }
        throw "No se pudo instalar el alias 'git $Name'."
    }

    $installedValue = & git config --global --get "alias.$Name"
    if ($LASTEXITCODE -ne 0 -or $installedValue -ne $Value) {
        throw "No se pudo verificar el alias 'git $Name'."
    }
}

try {
    if (-not $GitHubOwner) {
        $GitHubOwner = & git config --global --get git-tools.github-owner 2>$null
    }
    if (-not $GitHubOwner -and -not $NonInteractive) {
        $GitHubOwner = Read-Host "Escribi tu usuario de GitHub (Enter para omitir)"
    }
    if ($GitHubOwner) {
        if ($GitHubOwner -notmatch '^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?$') {
            throw "El usuario de GitHub '$GitHubOwner' no es valido."
        }
        & git config --global git-tools.github-owner $GitHubOwner
        if ($LASTEXITCODE -ne 0) {
            throw "No se pudo guardar el usuario de GitHub '$GitHubOwner'."
        }
        Write-Host "Usuario de GitHub configurado: $GitHubOwner"
    }
    else {
        Write-Host "Usuario de GitHub omitido: git start requerira una URL remota." -ForegroundColor Yellow
    }

    Set-GitAlias -Name "start" -Value $aliasStart
    Set-GitAlias -Name "backup" -Value $aliasBackup
    Set-GitAlias -Name "release" -Value $aliasRelease
    Set-GitAlias -Name "rollback" -Value $aliasRollback
    Set-GitAlias -Name "rollback-release" -Value $aliasRollbackRelease
}
catch {
    Write-Error $_
    exit 1
}

Write-Host "Todos los alias de git-tools fueron instalados correctamente." -ForegroundColor Green
