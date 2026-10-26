param([switch]$Test, [switch]$TestsOnly, [switch]$Preview)
$ErrorActionPreference = 'Stop'
$source = Join-Path $PSScriptRoot 'src/FFWTrainerGui'
$output = Join-Path $source 'build'
$compiler = Join-Path $env:WINDIR 'Microsoft.NET/Framework64/v4.0.30319/csc.exe'
if (-not (Test-Path -LiteralPath $compiler)) { $compiler = Join-Path $env:WINDIR 'Microsoft.NET/Framework/v4.0.30319/csc.exe' }
if (-not (Test-Path -LiteralPath $compiler)) { throw 'The .NET Framework C# compiler is unavailable.' }
[void](New-Item -ItemType Directory -Force -Path $output)
$references = @('/nologo', '/utf8output', '/optimize+', '/r:System.dll', '/r:System.Core.dll', '/r:System.Web.Extensions.dll', '/r:System.Windows.Forms.dll', '/r:System.Drawing.dll')
$files = @(Get-ChildItem -LiteralPath $source -Filter '*.cs' | ForEach-Object { $_.FullName })
if (-not $TestsOnly) {
    $catalog = Join-Path $source 'catalog.json'
    if (-not (Test-Path -LiteralPath $catalog)) { throw 'The bilingual catalog.json must be generated before building the GUI.' }
    & $compiler @references /target:winexe /main:FFWTrainerGui.Program "/out:$output/FFWTrainer.exe" "/resource:$catalog,FFWTrainerGui.catalog.json" "/win32manifest:$source/app.manifest" @files
    if ($LASTEXITCODE -ne 0) { throw 'GUI compilation failed.' }
    Write-Output "Built $output/FFWTrainer.exe"
}
if ($Test -or $TestsOnly) {
    $testFile = Join-Path $PSScriptRoot 'tests/trainer_gui_test.cs'
    & $compiler @references /target:exe /main:TrainerGuiTests "/out:$output/trainer_gui_test.exe" @files $testFile
    if ($LASTEXITCODE -ne 0) { throw 'GUI test compilation failed.' }
    & (Join-Path $output 'trainer_gui_test.exe')
    if ($LASTEXITCODE -ne 0) { throw 'GUI tests failed.' }
}
if ($Preview) {
    $catalog = Join-Path $source 'catalog.json'
    $previewFile = Join-Path $PSScriptRoot 'tests/trainer_gui_preview.cs'
    & $compiler @references /target:exe /main:TrainerGuiPreview "/out:$output/trainer_gui_preview.exe" "/resource:$catalog,FFWTrainerGui.catalog.json" @files $previewFile
    if ($LASTEXITCODE -ne 0) { throw 'GUI preview compilation failed.' }
    & (Join-Path $output 'trainer_gui_preview.exe') $output
    if ($LASTEXITCODE -ne 0) { throw 'GUI preview rendering failed.' }
}
