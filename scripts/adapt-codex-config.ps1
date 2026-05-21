param(
  [Parameter(Mandatory = $true)]
  [string]$ConfigPath,

  [Parameter(Mandatory = $true)]
  [string]$RepoRoot,

  [string]$SourceUserProfile = "C:\Users\James"
)

$ErrorActionPreference = "Stop"

function Format-CodexProjectPath {
  param([Parameter(Mandatory = $true)][string]$Path)

  return [System.IO.Path]::GetFullPath($Path).TrimEnd("\").ToLowerInvariant()
}

if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
  throw "Config file was not found: $ConfigPath"
}

$text = Get-Content -LiteralPath $ConfigPath -Raw
$targetProfile = [Environment]::GetFolderPath("UserProfile").TrimEnd("\").ToLowerInvariant()
$sourceProfiles = @($SourceUserProfile, "C:\Users\James") | Select-Object -Unique

foreach ($sourceProfile in $sourceProfiles) {
  $source = $sourceProfile.TrimEnd("\")
  if ($source) {
    $text = [regex]::Replace(
      $text,
      [regex]::Escape($source),
      { param($match) $targetProfile },
      [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )
  }
}

$repoProjectPath = Format-CodexProjectPath -Path $RepoRoot
$repoProjectHeader = "[projects.'$repoProjectPath']"

if ($text -notmatch [regex]::Escape($repoProjectHeader)) {
  $text = $text.TrimEnd() +
    [Environment]::NewLine +
    [Environment]::NewLine +
    $repoProjectHeader +
    [Environment]::NewLine +
    'trust_level = "trusted"' +
    [Environment]::NewLine
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($ConfigPath, $text, $utf8NoBom)

Write-Host "[OK] Adapted Codex config paths for $targetProfile."
Write-Host "[OK] Trusted codexbackup repository: $repoProjectPath."
