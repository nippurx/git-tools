param(
    [string]$GitHubOwner = "",
    [switch]$NonInteractive
)
$ErrorActionPreference = 'Stop'
try {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'Git no esta instalado o no esta disponible en PATH.'
    }
    $payload = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'lib/commands.sh')).Replace("`r`n", "`n").TrimEnd()
    function Set-GitValue([string]$Name, [string]$Value) {
        # Preserve quotes on Windows PowerShell 5.1 as well as PowerShell 7.
        $escaped = '"' + ($Value -replace '(\\*)"', '$1$1\"' -replace '(\\+)$', '$1$1') + '"'
        $info = New-Object System.Diagnostics.ProcessStartInfo
        $info.FileName = (Get-Command git).Source
        $info.Arguments = "config --global --replace-all $Name $escaped"
        $info.UseShellExecute = $false
        $process = [Diagnostics.Process]::Start($info)
        $process.WaitForExit()
        if ($process.ExitCode -ne 0) { throw "No se pudo guardar $Name." }
        $installed = (& git config --global --get $Name) -join "`n"
        if ($LASTEXITCODE -ne 0 -or $installed -cne $Value) { throw "No se pudo verificar $Name." }
    }
    if (-not $GitHubOwner) {
        $GitHubOwner = & git config --global --get git-tools.github-owner
    }
    if (-not $GitHubOwner -and -not $NonInteractive) {
        $GitHubOwner = Read-Host 'Usuario de GitHub (Enter para omitir)'
    }
    if ($GitHubOwner) {
        if ($GitHubOwner -notmatch '^[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?$') {
            throw 'Usuario de GitHub invalido.'
        }
        Set-GitValue 'git-tools.github-owner' $GitHubOwner
    }
    foreach ($name in @('start', 'backup', 'release', 'rollback', 'rollback-release')) {
        Set-GitValue "alias.$name" ("!" + $payload + "`ngt_main " + $name)
    }
    Write-Host 'Git Tools instalado. Usa git start, backup, release y rollback.' -ForegroundColor Green
}
catch {
    Write-Error $_
    exit 1
}