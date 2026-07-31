# Prerequisite: Docker Desktop must be installed and running -- https://docs.docker.com/get-docker/
param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    # Only report lint issues, without auto-fixing them.
    [switch]$Check
)

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker not found on PATH. Install Docker Desktop first: https://docs.docker.com/get-docker/"
    exit 1
}

$resolved = (Resolve-Path $Path).Path

# .markdownlint-cli2.jsonc is gitignored (each clone customizes its own rules)
# -- bootstrap it from the tracked example on first run.
$configPath = Join-Path $PSScriptRoot ".markdownlint-cli2.jsonc"
if (-not (Test-Path $configPath)) {
    Copy-Item (Join-Path $PSScriptRoot ".markdownlint-cli2.jsonc.example") $configPath
    Write-Host "Created $configPath from the example -- edit it to customize rules."
}

# Use this script's own directory as the Docker build context, so it works
# regardless of the caller's current directory.
docker build -t markdown-reformatter $PSScriptRoot
if (-not $?) { exit 1 }

if ($Check) {
    docker run --rm -v "${resolved}:/data" markdown-reformatter --check "**/*.md"
} else {
    docker run --rm -v "${resolved}:/data" markdown-reformatter "**/*.md"
}
