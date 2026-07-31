# Prerequisite: Docker Desktop must be installed and running -- https://docs.docker.com/get-docker/
#
# Installs the `md-lint` command so it can be run from any directory on this
# Windows account, without needing to keep this cloned repo around.
#
# What it does:
#   1. Copies the Docker project files (Dockerfile, entrypoint.sh, package.json,
#      .markdownlint-cli2.jsonc) to $env:USERPROFILE\.md-lint -- this becomes
#      the Docker build context that `md-lint` uses no matter where it's invoked from.
#   2. Copies md-lint\md-lint (+ md-lint\md-lint.cmd) to a bin directory and
#      makes sure that directory is on this user's PATH.
#
# Requires bash (from Git for Windows / WSL) to be on PATH -- md-lint itself
# is a bash script; md-lint.cmd is just a thin wrapper that invokes it.

$ErrorActionPreference = "Stop"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker not found on PATH. Install Docker Desktop first: https://docs.docker.com/get-docker/"
    exit 1
}

$repoDir = $PSScriptRoot
$mdlintHome = Join-Path $env:USERPROFILE ".md-lint"

Write-Host "Installing markdown-reformatter project files to $mdlintHome ..."
New-Item -ItemType Directory -Force $mdlintHome | Out-Null
Copy-Item (Join-Path $repoDir "Dockerfile") $mdlintHome -Force
Copy-Item (Join-Path $repoDir "entrypoint.sh") $mdlintHome -Force
Copy-Item (Join-Path $repoDir "package.json") $mdlintHome -Force
Copy-Item (Join-Path $repoDir ".markdownlint-cli2.jsonc.example") $mdlintHome -Force

# .markdownlint-cli2.jsonc is gitignored (each clone/install customizes its
# own rules) -- bootstrap it from the example, but never overwrite an existing
# customized config on re-install.
$configPath = Join-Path $mdlintHome ".markdownlint-cli2.jsonc"
if (-not (Test-Path $configPath)) {
    Copy-Item (Join-Path $mdlintHome ".markdownlint-cli2.jsonc.example") $configPath
    Write-Host "Created $configPath from the example -- edit it to customize rules."
}

$binDir = Join-Path $env:USERPROFILE "bin"
New-Item -ItemType Directory -Force $binDir | Out-Null

Write-Host "Installing md-lint command to $binDir ..."
Copy-Item (Join-Path $repoDir "md-lint\md-lint") $binDir -Force
Copy-Item (Join-Path $repoDir "md-lint\md-lint.cmd") $binDir -Force

Write-Host ""
Write-Host "Done. Installed: $binDir\md-lint.cmd"

$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$pathEntries = $userPath -split ";"
if ($pathEntries -notcontains $binDir) {
    [Environment]::SetEnvironmentVariable("PATH", "$userPath;$binDir", "User")
    Write-Host "Added $binDir to your User PATH."
    Write-Host "Restart your terminal (PowerShell/Git Bash) for this to take effect."
} else {
    Write-Host "You can now run 'md-lint <path>' from any directory."
}
