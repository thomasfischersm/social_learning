param(
    [string]$Path = "."
)

# Single regex to ignore dependency/build/IDE folders
$ignoreRegex = '\\node_modules\\|\\.dart_tool\\|\\build\\|\\.git\\|\\.idea\\|\\.vscode'

function Count-Lines {
    param(
        [string]$Extension
    )

    $files = Get-ChildItem -Path $Path -Recurse -File -Include "*.$Extension" |
        Where-Object { $_.FullName -notmatch $ignoreRegex }

    if (-not $files) {
        return @{ Files = 0; Lines = 0 }
    }

    $totalLines = 0
    foreach ($file in $files) {
        $totalLines += (Get-Content $file.FullName | Measure-Object -Line).Lines
    }

    return @{ Files = $files.Count; Lines = $totalLines }
}

Write-Host "Scanning source files under '$Path'..."`n

$dart = Count-Lines -Extension "dart"
$java = Count-Lines -Extension "java"
$ts   = Count-Lines -Extension "ts"

Write-Host "Dart:       $($dart.Files) files, $($dart.Lines) lines"
Write-Host "Java:       $($java.Files) files, $($java.Lines) lines"
Write-Host "TypeScript: $($ts.Files) files, $($ts.Lines) lines"
