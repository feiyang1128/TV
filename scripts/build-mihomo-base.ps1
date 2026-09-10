[CmdletBinding()]
param(
    [switch]$Check
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$yamlDirectory = Join-Path $repoRoot "Mihomo/file/yml"
$commonPath = Join-Path $yamlDirectory "base-common.yml"
$targets = @(
    "base-all.yml",
    "base-no6.yml",
    "base-nocf.yml",
    "base-no6nocf.yml"
)
$generatedNotice = "# Generated from base-common.yml by scripts/build-mihomo-base.ps1."
$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
$common = [System.IO.File]::ReadAllText($commonPath, $utf8WithoutBom).TrimEnd()
$outdated = @()

foreach ($target in $targets) {
    $targetPath = Join-Path $yamlDirectory $target
    $current = [System.IO.File]::ReadAllText($targetPath, $utf8WithoutBom)
    $ruleProvidersIndex = $current.IndexOf("rule-providers:")

    if ($ruleProvidersIndex -lt 0) {
        throw "Missing rule-providers section: $targetPath"
    }

    $variant = $current.Substring($ruleProvidersIndex).TrimStart()
    $expected = "$generatedNotice`n$common`n$variant".Replace("`r`n", "`n")
    $actual = $current.Replace("`r`n", "`n")

    if ($actual -eq $expected) {
        continue
    }

    if ($Check) {
        $outdated += $target
        continue
    }

    [System.IO.File]::WriteAllText($targetPath, $expected, $utf8WithoutBom)
    Write-Host "Generated $target"
}

if ($outdated.Count -gt 0) {
    throw "Outdated Mihomo base files: $($outdated -join ', '). Run scripts/build-mihomo-base.ps1."
}
