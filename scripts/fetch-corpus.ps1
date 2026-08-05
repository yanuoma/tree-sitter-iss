<#
.SYNOPSIS
    Download the real-world validation corpus used to test this grammar.

.DESCRIPTION
    The corpus is other people's code, published under their own licenses, so it
    is deliberately NOT vendored into this repository. This script fetches it
    into examples/ (which .gitignore excludes) so you can reproduce the full
    validation run locally:

        pwsh scripts/fetch-corpus.ps1
        cargo test

    Sources:
      examples/real  - official example scripts from jrsoftware/issrc
      examples/wild  - scripts from assorted public GitHub projects
#>
[CmdletBinding()]
param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$headers = @{ 'User-Agent' = 'tree-sitter-iss-corpus'; 'Accept' = 'application/vnd.github+json' }

$realDir = Join-Path $Root 'examples\real'
$wildDir = Join-Path $Root 'examples\wild'
New-Item -ItemType Directory -Force -Path $realDir, $wildDir | Out-Null

Write-Host 'Fetching official Inno Setup examples from jrsoftware/issrc...'
$items = Invoke-RestMethod -Uri 'https://api.github.com/repos/jrsoftware/issrc/contents/Examples' -Headers $headers
$real = 0
foreach ($f in ($items | Where-Object { $_.name -like '*.iss' })) {
    try {
        Invoke-WebRequest -Uri $f.download_url -OutFile (Join-Path $realDir $f.name) -UseBasicParsing
        $real++
    } catch {
        Write-Warning "  could not fetch $($f.name)"
    }
}
Write-Host "  $real files -> examples/real"

$listPath = Join-Path $Root 'examples\corpus-list.txt'
if (-not (Test-Path $listPath)) {
    Write-Warning "examples/corpus-list.txt not found; skipping the 'wild' corpus."
    return
}

Write-Host 'Fetching real-world scripts from public GitHub projects...'
$wild = 0
foreach ($line in (Get-Content $listPath)) {
    if (-not $line.Trim()) { continue }
    $parts = $line -split '\|'
    if ($parts.Count -lt 3) { continue }
    $local, $repo, $path = $parts[0], $parts[1], $parts[2]
    $url = "https://raw.githubusercontent.com/$repo/HEAD/$([uri]::EscapeUriString($path))"
    try {
        Invoke-WebRequest -Uri $url -OutFile (Join-Path $wildDir $local) -UseBasicParsing
        $wild++
    } catch {
        Write-Warning "  could not fetch $repo/$path"
    }
}
Write-Host "  $wild files -> examples/wild"

Write-Host ''
Write-Host "Corpus ready: $($real + $wild) scripts. Now run: cargo test"
