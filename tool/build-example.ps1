param(
    [Parameter(Position = 0)]
    [string] $Target
)

$ErrorActionPreference = 'Stop'

function Write-Usage {
    [Console]::Error.WriteLine(
        'Usage: tool/build-example.ps1 <android|windows|web|all>'
    )
}

if ([string]::IsNullOrWhiteSpace($Target) -or $args.Count -ne 0) {
    Write-Usage
    exit 64
}

$validTargets = @('android', 'windows', 'web', 'all')
if ($Target -notin $validTargets) {
    [Console]::Error.WriteLine("Unknown or unsupported Windows target: $Target")
    Write-Usage
    exit 64
}

if (-not $IsWindows) {
    [Console]::Error.WriteLine(
        'This wrapper supports Windows only. Use tool/build-example.sh on Linux or macOS.'
    )
    exit 69
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$exampleDir = Join-Path $repoRoot 'example'
$selectedTargets = if ($Target -eq 'all') {
    @('android', 'windows', 'web')
} else {
    @($Target)
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    [Console]::Error.WriteLine(
        'Flutter was not found on PATH. Install Flutter 3.44.6 before building.'
    )
    exit 69
}

if ('android' -in $selectedTargets) {
    $androidSibling = Join-Path (Split-Path -Parent $repoRoot) 'comics-viewer-android'
    if (-not (Test-Path -PathType Container $androidSibling)) {
        [Console]::Error.WriteLine(
            "Android build requires the sibling checkout at: $androidSibling"
        )
        [Console]::Error.WriteLine(
            'Clone https://github.com/comics108/comics-viewer-android there and retry.'
        )
        exit 66
    }
}

function Invoke-Flutter {
    param([string[]] $Arguments)

    & flutter @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "flutter $($Arguments -join ' ') failed with exit code $LASTEXITCODE"
    }
}

Push-Location $exampleDir
try {
    Invoke-Flutter @('pub', 'get')

    foreach ($selectedTarget in $selectedTargets) {
        Write-Host "Building viewer_example for $selectedTarget..."
        switch ($selectedTarget) {
            'android' { Invoke-Flutter @('build', 'apk', '--release') }
            'windows' { Invoke-Flutter @('build', 'windows', '--release') }
            'web' { Invoke-Flutter @('build', 'web', '--release') }
        }
    }
} finally {
    Pop-Location
}
