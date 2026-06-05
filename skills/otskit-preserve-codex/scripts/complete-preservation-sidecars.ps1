param(
  [Parameter(Mandatory=$true)][string]$OutputDir,
  [Parameter(Mandatory=$true)][string]$BaseName,
  [Parameter(Mandatory=$true)][string]$StampId,
  [Parameter(Mandatory=$true)][string]$StampHash,
  [string]$ProofPath = ""
)

$ErrorActionPreference = "Stop"

function Write-Utf8NoBom([string]$Path, [string]$Content) {
  $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

$resolvedOutput = (Resolve-Path -LiteralPath $OutputDir).ProviderPath
$zipPath = Join-Path $resolvedOutput "$BaseName.zip"
$shaPath = Join-Path $resolvedOutput "$BaseName.sha256"
$stampIdPath = Join-Path $resolvedOutput "$BaseName.stamp-id.txt"
$otsPath = Join-Path $resolvedOutput "$BaseName.ots"

if ($StampHash -notmatch '^[0-9a-fA-F]{64}$') {
  throw "StampHash must be a 64-character SHA-256 hex digest returned by OTSkit stamp_file."
}

if (-not (Test-Path -LiteralPath $zipPath)) {
  throw "Expected ZIP not found: $zipPath"
}

Write-Utf8NoBom $shaPath ($StampHash.ToLowerInvariant() + "  $BaseName.zip`n")
Write-Utf8NoBom $stampIdPath ($StampId + "`n")

$proofCopied = $false
if (-not [string]::IsNullOrWhiteSpace($ProofPath)) {
  if (Test-Path -LiteralPath $ProofPath) {
    Copy-Item -LiteralPath $ProofPath -Destination $otsPath -Force
    $proofCopied = $true
  }
}

$expected = @(
  $zipPath
  $shaPath
  $stampIdPath
)

if ($proofCopied) {
  $expected += $otsPath
}

$missing = @()
foreach ($path in $expected) {
  if (-not (Test-Path -LiteralPath $path)) {
    $missing += $path
  }
}

[pscustomobject]@{
  output_dir = $resolvedOutput
  sha256_path = (Resolve-Path -LiteralPath $shaPath).ProviderPath
  ots_path = if ($proofCopied) { (Resolve-Path -LiteralPath $otsPath).ProviderPath } else { $null }
  stamp_id_path = (Resolve-Path -LiteralPath $stampIdPath).ProviderPath
  sha256 = $StampHash.ToLowerInvariant()
  proof_copied = $proofCopied
  missing = $missing
} | ConvertTo-Json
