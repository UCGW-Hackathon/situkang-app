param(
    [switch]$AllowLockfileUpdate
)

$ErrorActionPreference = "Stop"

$requiredDartVersion = [Version]"3.11.1"

function Get-DartVersion {
    $versionOutput = & dart --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Dart is not available on PATH. Install Flutter first, then try again."
    }

    if ($versionOutput -notmatch "Dart SDK version:\s+([0-9]+\.[0-9]+\.[0-9]+)") {
        throw "Could not parse Dart version from: $versionOutput"
    }

    return [Version]$Matches[1]
}

function Test-CommandExists($name) {
    return $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

$dartVersion = Get-DartVersion

if ($dartVersion -lt $requiredDartVersion) {
    Write-Host "Dart $dartVersion is too old for this project. Required: >= $requiredDartVersion < 4.0.0." -ForegroundColor Red
    Write-Host "Recommended Flutter SDK: 3.44.1." -ForegroundColor Yellow

    if (Test-CommandExists "fvm") {
        Write-Host "Run: fvm install 3.44.1; fvm use 3.44.1; fvm flutter pub get --enforce-lockfile" -ForegroundColor Yellow
    } else {
        Write-Host "Install/use Flutter 3.44.1, or install FVM and run: dart pub global activate fvm" -ForegroundColor Yellow
    }

    exit 1
}

if ($AllowLockfileUpdate) {
    Write-Host "Running flutter pub get. pubspec.lock may be updated." -ForegroundColor Yellow
    & flutter pub get
} else {
    Write-Host "Running flutter pub get with pubspec.lock enforced." -ForegroundColor Green
    & flutter pub get --enforce-lockfile
}

exit $LASTEXITCODE
