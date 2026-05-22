param(
  [Parameter(Mandatory = $true)]
  [string]$ConfigPath,

  [Parameter(Mandatory = $true)]
  [string]$RepoRoot,

  [string]$SourceUserProfile = "",

  [string]$CodexHome = (Join-Path $env:USERPROFILE ".codex"),

  [switch]$IncludeState,

  [switch]$EnsureProjectDirectories,

  [string]$BackupRoot = ""
)

$ErrorActionPreference = "Stop"
$script:TotalReplacementCount = 0
$script:BackupStamp = Get-Date -Format "yyyyMMdd-HHmmss"

if (-not $BackupRoot) {
  $BackupRoot = Join-Path $CodexHome "pathfix-backups"
}

function Format-CodexProjectPath {
  param([Parameter(Mandatory = $true)][string]$Path)

  return [System.IO.Path]::GetFullPath($Path).TrimEnd("\").ToLowerInvariant()
}

if (-not (Test-Path -LiteralPath $ConfigPath -PathType Leaf)) {
  throw "Config file was not found: $ConfigPath"
}

$targetProfile = [Environment]::GetFolderPath("UserProfile").TrimEnd("\").ToLowerInvariant()
$targetProfileEscaped = $targetProfile.Replace("\", "\\")

function Get-DetectedSourceProfiles {
  $profiles = New-Object System.Collections.Generic.List[string]

  if ($SourceUserProfile) {
    $profiles.Add($SourceUserProfile.TrimEnd("\"))
  }

  $candidateFiles = @($ConfigPath)
  if ($IncludeState) {
    $candidateFiles += @(
      (Join-Path $CodexHome "session_index.jsonl"),
      (Join-Path $CodexHome ".codex-global-state.json"),
      (Join-Path $CodexHome ".codex-global-state.json.bak")
    )
  }

  $profilePattern = [regex]'(?i)c:(?:\\\\|\\)users(?:\\\\|\\)([^\\/"''\]\}\s]+)'

  foreach ($candidateFile in $candidateFiles | Select-Object -Unique) {
    if (-not (Test-Path -LiteralPath $candidateFile -PathType Leaf)) {
      continue
    }

    $text = [System.IO.File]::ReadAllText($candidateFile)
    foreach ($match in $profilePattern.Matches($text)) {
      $profiles.Add("C:\Users\$($match.Groups[1].Value)")
    }
  }

  return @(
    $profiles |
      Where-Object { $_ } |
      ForEach-Object { $_.TrimEnd("\") } |
      Where-Object { $_ -and $_.ToLowerInvariant() -ne $targetProfile } |
      Sort-Object -Unique
  )
}

$sourceProfiles = Get-DetectedSourceProfiles

function Convert-CodexPathsInText {
  param([Parameter(Mandatory = $true)][string]$Text)

  $result = $Text

  foreach ($sourceProfile in $sourceProfiles) {
    $source = $sourceProfile.TrimEnd("\")
    if (-not $source) {
      continue
    }

    $sourceEscaped = $source.Replace("\", "\\")
    $pairs = @(
      @{ Source = $sourceEscaped; Target = $targetProfileEscaped },
      @{ Source = $source; Target = $targetProfile }
    )

    foreach ($pair in $pairs) {
      $count = [regex]::Matches(
        $result,
        [regex]::Escape($pair.Source),
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
      ).Count

      if ($count -gt 0) {
        $replacement = $pair.Target
        $result = [regex]::Replace(
          $result,
          [regex]::Escape($pair.Source),
          { param($match) $replacement },
          [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
        )
        $script:TotalReplacementCount += $count
      }
    }
  }

  return $result
}

function Backup-File {
  param([Parameter(Mandatory = $true)][string]$Path)

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    return
  }

  $relative = $Path
  if ($Path.StartsWith($CodexHome, [System.StringComparison]::OrdinalIgnoreCase)) {
    $relative = $Path.Substring($CodexHome.Length).TrimStart("\")
  } else {
    $relative = Split-Path -Leaf $Path
  }

  $backupPath = Join-Path (Join-Path $BackupRoot $script:BackupStamp) $relative
  $backupDir = Split-Path -Parent $backupPath
  if (-not (Test-Path -LiteralPath $backupDir)) {
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
  }

  Copy-Item -LiteralPath $Path -Destination $backupPath -Force
}

function Update-TextFile {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [switch]$EnsureRepoTrust
  )

  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    return [pscustomobject]@{ Path = $Path; Changed = $false; Replacements = 0; Error = "missing" }
  }

  try {
    $beforeTotal = $script:TotalReplacementCount
    $text = [System.IO.File]::ReadAllText($Path)
    $updated = Convert-CodexPathsInText -Text $text

    if ($EnsureRepoTrust) {
      $repoProjectPath = Format-CodexProjectPath -Path $RepoRoot
      $repoProjectHeader = "[projects.'$repoProjectPath']"

      if ($updated -notmatch [regex]::Escape($repoProjectHeader)) {
        $updated = $updated.TrimEnd() +
          [Environment]::NewLine +
          [Environment]::NewLine +
          $repoProjectHeader +
          [Environment]::NewLine +
          'trust_level = "trusted"' +
          [Environment]::NewLine
      }
    }

    $replacementCount = $script:TotalReplacementCount - $beforeTotal
    if ($updated -ne $text) {
      Backup-File -Path $Path
      $utf8NoBom = New-Object System.Text.UTF8Encoding $false
      [System.IO.File]::WriteAllText($Path, $updated, $utf8NoBom)
      return [pscustomobject]@{ Path = $Path; Changed = $true; Replacements = $replacementCount; Error = $null }
    }

    return [pscustomobject]@{ Path = $Path; Changed = $false; Replacements = $replacementCount; Error = $null }
  } catch {
    return [pscustomobject]@{ Path = $Path; Changed = $false; Replacements = 0; Error = $_.Exception.Message }
  }
}

$results = @()
$results += Update-TextFile -Path $ConfigPath -EnsureRepoTrust

if ($IncludeState) {
  $stateFiles = @(
    "session_index.jsonl",
    ".codex-global-state.json",
    ".codex-global-state.json.bak"
  ) | ForEach-Object { Join-Path $CodexHome $_ }

  foreach ($stateFile in $stateFiles) {
    $results += Update-TextFile -Path $stateFile
  }

  foreach ($dirName in @("sessions", "archived_sessions")) {
    $dir = Join-Path $CodexHome $dirName
    if (Test-Path -LiteralPath $dir -PathType Container) {
      Get-ChildItem -LiteralPath $dir -Recurse -File -Include *.json,*.jsonl |
        ForEach-Object { $results += Update-TextFile -Path $_.FullName }
    }
  }
}

$changed = @($results | Where-Object { $_.Changed }).Count
$errors = @($results | Where-Object { $_.Error -and $_.Error -ne "missing" })

Write-Host "[OK] Adapted Codex paths for $targetProfile."
Write-Host "[OK] Trusted codexbackup repository: $(Format-CodexProjectPath -Path $RepoRoot)."
Write-Host "[OK] Files changed: $changed; replacements: $script:TotalReplacementCount."

if ($changed -gt 0) {
  Write-Host "[OK] Backups written under: $(Join-Path $BackupRoot $script:BackupStamp)"
}

if ($EnsureProjectDirectories) {
  $configText = [System.IO.File]::ReadAllText($ConfigPath)
  $projectPaths = [regex]::Matches(
    $configText,
    "^\[projects\.'(.+)'\]",
    [System.Text.RegularExpressions.RegexOptions]::Multiline
  ) | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique

  $createdCount = 0
  foreach ($projectPath in $projectPaths) {
    if (-not (Test-Path -LiteralPath $projectPath)) {
      New-Item -ItemType Directory -Force -Path $projectPath | Out-Null
      $createdCount += 1
    }
  }

  Write-Host "[OK] Missing trusted project directories created: $createdCount."
}

foreach ($errorResult in $errors) {
  Write-Host "[WARN] Skipped $($errorResult.Path): $($errorResult.Error)"
}

$configResult = $results | Where-Object { $_.Path -eq $ConfigPath } | Select-Object -First 1
if ($configResult.Error -and $configResult.Error -ne "missing") {
  exit 1
}
