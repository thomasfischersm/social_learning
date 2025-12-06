param(
    [string]$Path = "."
)

Write-Host "Scanning for .dart files under '$Path'..."`n

# Get all .dart files recursively
$files = Get-ChildItem -Path $Path -Recurse -Include *.dart -File

if (-not $files) {
    Write-Host "No .dart files found."
    exit 0
}

$totalLines = 0

foreach ($file in $files) {
    $lineCount = (Get-Content $file.FullName | Measure-Object -Line).Lines
    $totalLines += $lineCount
}

$fileCount = $files.Count

Write-Host "Dart files: $fileCount   Total Dart lines: $totalLines"
