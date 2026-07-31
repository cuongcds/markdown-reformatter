# Reverses install.ps1: removes the md-lint command, its Docker project files
# copy, and (if install.ps1 added it) the bin dir from your User PATH.
# Safe to re-run (no-op if already uninstalled).

$ErrorActionPreference = "Stop"

$mdlintHome = Join-Path $env:USERPROFILE ".md-lint"
$binDir = Join-Path $env:USERPROFILE "bin"
$removedAny = $false

if (Test-Path $mdlintHome) {
    Remove-Item -Recurse -Force $mdlintHome
    Write-Host "Removed $mdlintHome"
    $removedAny = $true
}

foreach ($name in "md-lint", "md-lint.cmd") {
    $f = Join-Path $binDir $name
    if (Test-Path $f) {
        Remove-Item -Force $f
        Write-Host "Removed $f"
        $removedAny = $true
    }
}

$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$pathEntries = $userPath -split ";" | Where-Object { $_ -ne "" }
$pathChanged = $false
if ($pathEntries -contains $binDir) {
    $newPath = ($pathEntries | Where-Object { $_ -ne $binDir }) -join ";"
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    Write-Host "Removed $binDir from your User PATH."
    $removedAny = $true
    $pathChanged = $true
}

if (-not $removedAny) {
    Write-Host "Nothing to uninstall -- md-lint doesn't appear to be installed."
} else {
    Write-Host ""
    Write-Host "Uninstalled md-lint."
    if ($pathChanged) {
        Write-Host "Restart your terminal for the PATH change to take effect."
    }
}

# Best-effort cleanup -- don't let a missing image (or any docker error) fail the script.
$oldPref = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"
docker rmi markdown-reformatter *>$null
$imageRemoved = $?
$ErrorActionPreference = $oldPref
$global:LASTEXITCODE = 0
if ($imageRemoved) { Write-Host "Removed the markdown-reformatter Docker image." }
