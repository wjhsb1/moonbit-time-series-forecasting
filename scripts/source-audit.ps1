param(
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepositoryRoot).Path
$rootFiles = @(Get-ChildItem -LiteralPath $root -File | Where-Object {
    $_.Extension -eq '.mbt'
} | Sort-Object Name)
$productionFiles = @($rootFiles | Where-Object {
    $_.Name -notlike '*_test.mbt' -and $_.Name -notlike '*_wbtest.mbt'
})
$testFiles = @($rootFiles | Where-Object {
    $_.Name -like '*_test.mbt' -or $_.Name -like '*_wbtest.mbt'
})
$exampleFiles = @(Get-ChildItem -LiteralPath (Join-Path $root 'examples') -File -Recurse | Where-Object {
    $_.Extension -eq '.mbt'
} | Sort-Object FullName)

function Measure-MoonBitSource {
    param([System.IO.FileInfo[]]$Files, [string]$Label)

    $physicalTotal = 0
    $substantiveTotal = 0
    foreach ($file in $Files) {
        $lines = @(Get-Content -LiteralPath $file.FullName)
        $substantive = @($lines | Where-Object {
            $trimmed = $_.Trim()
            $trimmed.Length -gt 0 -and -not $trimmed.StartsWith('//')
        }).Count
        $physicalTotal += $lines.Count
        $substantiveTotal += $substantive
        Write-Host ('{0,-12} {1,-38} physical={2,5} substantive={3,5}' -f $Label, $file.Name, $lines.Count, $substantive)
    }
    Write-Host ('{0,-12} TOTAL                                  physical={1,5} substantive={2,5}' -f $Label, $physicalTotal, $substantiveTotal)
    [PSCustomObject]@{ Physical = $physicalTotal; Substantive = $substantiveTotal }
}

$production = Measure-MoonBitSource -Files $productionFiles -Label 'production'
$tests = Measure-MoonBitSource -Files $testFiles -Label 'test'
$examples = Measure-MoonBitSource -Files $exampleFiles -Label 'example'

$allMoonBitFiles = @($rootFiles + $exampleFiles)
$placeholderPattern = '(?i)\b(TODO|MVP|stub|fake)\b'
$placeholderMatches = @($allMoonBitFiles | Select-String -Pattern $placeholderPattern)
if ($placeholderMatches.Count -gt 0) {
    $placeholderMatches | ForEach-Object { Write-Error $_.ToString() }
    throw 'Placeholder markers were found in MoonBit source files.'
}

$testCount = @($testFiles | Get-Content | Select-String -Pattern '^test ').Count
Write-Output "MoonBit test declarations: $testCount"

if ($productionFiles.Count -eq 0 -or $testFiles.Count -eq 0 -or $exampleFiles.Count -lt 5) {
    throw 'Production, test, and five example MoonBit sources are required.'
}
if ($production.Substantive -lt 4000) {
    throw "Substantive production MoonBit lines must be at least 4000; found $($production.Substantive)."
}
if ($testCount -lt 80) {
    throw "At least 80 MoonBit test declarations are required; found $testCount."
}
