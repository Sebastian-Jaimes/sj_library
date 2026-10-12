<#
.SYNOPSIS
    Valida la librería SJ: formato KiCad 10, vistas previas SVG, campos SJ y huellas asignadas.

.DESCRIPTION
    1. kicad-cli sym/fp upgrade sobre cada librería (en una carpeta temporal; no modifica los originales).
    2. Exporta vistas previas SVG a out/preview/ (ignorada por git).
    3. Verifica que cada símbolo de las librerías SJ_<Cat> tenga los 10 campos SJ (vacíos: se
       completan en la selección de componentes) y una huella asignada que exista
       (en sj_library o en la librería estándar de KiCad).
    Devuelve código de salida 1 si hay errores.

.EXAMPLE
    .\tools\validate_library.ps1
    .\tools\validate_library.ps1 -NoPreview
#>
param(
    [string]$LibRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$KicadCli = $(if ($env:KICAD_CLI) { $env:KICAD_CLI } else { 'C:\Program Files\KiCad\10.0\bin\kicad-cli.exe' }),
    [switch]$NoPreview
)

$ErrorActionPreference = 'Stop'
$SjFields = @('Manufacturer', 'Mfg Part #', 'LCSC Part #', 'Supplier', 'Cost', 'Voltage', 'Current', 'TC', 'Power', 'Tol')
$KicadShare = Join-Path (Split-Path -Parent (Split-Path -Parent $KicadCli)) 'share\kicad'
$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

if (-not (Test-Path $KicadCli)) { throw "No se encontró kicad-cli en '$KicadCli'. Usa -KicadCli o la variable KICAD_CLI." }

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("sjlib_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
$preview = Join-Path $LibRoot 'out\preview'

function Invoke-Cli([string[]]$CliArgs) {
    $out = & $KicadCli @CliArgs 2>&1
    return @{ Code = $LASTEXITCODE; Out = ($out -join "`n") }
}

function Test-FootprintExists([string]$fp) {
    if ($fp -notmatch '^([^:]+):(.+)$') { return $false }
    $lib = $Matches[1]; $name = $Matches[2]
    $candidates = @(
        (Join-Path $LibRoot "footprints\$lib.pretty\$name.kicad_mod"),
        (Join-Path $KicadShare "footprints\$lib.pretty\$name.kicad_mod")
    )
    foreach ($c in $candidates) { if (Test-Path -LiteralPath $c) { return $true } }
    return $false
}

try {
    # ---------- Símbolos ----------
    foreach ($lib in Get-ChildItem (Join-Path $LibRoot 'symbols') -Filter '*.kicad_sym') {
        $r = Invoke-Cli @('sym', 'upgrade', '--force', '-o', (Join-Path $tmp $lib.Name), $lib.FullName)
        if ($r.Code -ne 0) { $errors.Add("[$($lib.BaseName)] KiCad no puede leer la librería: $($r.Out)"); continue }

        $text = Get-Content -LiteralPath $lib.FullName -Raw -Encoding UTF8
        # Bloques de símbolos de primer nivel: empiezan con exactamente un tab
        $blocks = [regex]::Split($text, '(?m)^\t\(symbol "') | Select-Object -Skip 1
        if ($blocks.Count -eq 0) { $warnings.Add("[$($lib.BaseName)] librería vacía"); continue }

        if (-not $NoPreview) {
            $dir = Join-Path $preview "symbols\$($lib.BaseName)"
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
            $r = Invoke-Cli @('sym', 'export', 'svg', '-o', $dir, $lib.FullName)
            if ($r.Code -ne 0) { $warnings.Add("[$($lib.BaseName)] no se pudo exportar SVG") }
        }

        if ($lib.BaseName -eq 'SJ_Template') { continue }
        foreach ($b in $blocks) {
            $sym = ($b -split '"', 2)[0]
            $props = @{}
            foreach ($m in [regex]::Matches($b, '(?m)^\t\t\(property "([^"]+)" "([^"]*)"')) { $props[$m.Groups[1].Value] = $m.Groups[2].Value }
            $isDerived = $b -match '(?m)^\t\t\(extends "'
            $missing = $SjFields | Where-Object { -not $props.ContainsKey($_) }
            if ($missing -and -not $isDerived) { $errors.Add("[$($lib.BaseName):$sym] faltan campos: $($missing -join ', ')") }
            # Los campos SJ se completan en la selección de componentes, no en la librería
            $filled = $SjFields | Where-Object { $props[$_] }
            if ($filled) { $warnings.Add("[$($lib.BaseName):$sym] campos SJ con valor en la librería (deberían ir vacíos): $($filled -join ', ')") }
            $fp = $props['Footprint']
            if (-not $fp) { if (-not $isDerived) { $errors.Add("[$($lib.BaseName):$sym] sin huella asignada") } }
            elseif (-not (Test-FootprintExists $fp)) { $errors.Add("[$($lib.BaseName):$sym] la huella '$fp' no existe en SJ ni en la librería estándar") }
        }
    }

    # ---------- Huellas ----------
    foreach ($pretty in Get-ChildItem (Join-Path $LibRoot 'footprints') -Directory -Filter '*.pretty') {
        $libName = $pretty.Name -replace '\.pretty$', ''
        $mods = @(Get-ChildItem $pretty.FullName -Filter '*.kicad_mod')
        if ($mods.Count -eq 0) { $warnings.Add("[$libName] librería de huellas vacía"); continue }
        $r = Invoke-Cli @('fp', 'upgrade', '--force', '-o', (Join-Path $tmp $pretty.Name), $pretty.FullName)
        if ($r.Code -ne 0) { $errors.Add("[$libName] KiCad no puede leer la librería: $($r.Out)") }

        foreach ($mod in $mods) {
            $t = Get-Content -LiteralPath $mod.FullName -Raw -Encoding UTF8
            foreach ($m in [regex]::Matches($t, '\(model "([^"]+)"')) {
                $p = $m.Groups[1].Value
                if ($p -notmatch '^\$\{(SJ_KICAD_LIBS|KICAD\d+_3DMODEL_DIR)\}') { $errors.Add("[${libName}:$($mod.BaseName)] ruta 3D sin variable válida: $p") }
                elseif ($p -match '^\$\{SJ_KICAD_LIBS\}/sj_library/(.+)$' -and -not (Test-Path -LiteralPath (Join-Path $LibRoot $Matches[1]))) { $errors.Add("[${libName}:$($mod.BaseName)] no existe el modelo 3D: $p") }
            }
        }
        if (-not $NoPreview) {
            $dir = Join-Path $preview "footprints\$libName"
            New-Item -ItemType Directory -Force -Path $dir | Out-Null
            $r = Invoke-Cli @('fp', 'export', 'svg', '-o', $dir, $pretty.FullName)
            if ($r.Code -ne 0) { $warnings.Add("[$libName] no se pudo exportar SVG") }
        }
    }
}
finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
}

Write-Host ''
foreach ($w in $warnings) { Write-Host "AVISO  $w" -ForegroundColor Yellow }
foreach ($e in $errors) { Write-Host "ERROR  $e" -ForegroundColor Red }
Write-Host ("`nResultado: {0} error(es), {1} aviso(s)" -f $errors.Count, $warnings.Count)
if (-not $NoPreview) { Write-Host "Vistas previas: $preview" }
if ($errors.Count -gt 0) { exit 1 } else { exit 0 }
