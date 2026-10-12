<#
.SYNOPSIS
    Revisa que un proyecto personal solo use librerías permitidas: estándar de KiCad, SJ_*, PCM_*
    y las librerías locales del propio proyecto (tablas del proyecto con rutas ${KIPRJMOD}).

.DESCRIPTION
    Recorre los .kicad_sch, .kicad_pcb y .kicad_pro del proyecto y lista:
      - símbolos (lib_id) y huellas (Footprint / footprint) de librerías no permitidas
      - hojas de dibujo (page_layout_descr_file) fuera de ${SJ_KICAD_LIBS}/sj_library, de KiCad o del proyecto
    Devuelve código de salida 1 si encuentra algo no permitido.

.EXAMPLE
    .\tools\check_project_libs.ps1 C:\...\DroneNavigationController\electronics\DNC
#>
param(
    [Parameter(Mandatory = $true)][string]$ProjectDir,
    [string]$KicadShare = 'C:\Program Files\KiCad\10.0\share\kicad'
)

$ErrorActionPreference = 'Stop'

function Get-TableNames([string]$path) {
    if (-not (Test-Path $path)) { return @() }
    return [regex]::Matches((Get-Content $path -Raw), '\(lib \(name "([^"]+)"\)') | ForEach-Object { $_.Groups[1].Value }
}
$stock = @{}
foreach ($n in (Get-TableNames (Join-Path $KicadShare 'template\sym-lib-table')) + (Get-TableNames (Join-Path $KicadShare 'template\fp-lib-table'))) { $stock[$n] = $true }
if ($stock.Count -eq 0) { throw "No se encontraron las tablas estándar de KiCad en '$KicadShare'." }

# Librerías locales del proyecto: solo las que viven dentro del proyecto (${KIPRJMOD})
$local = @{}
foreach ($tbl in 'sym-lib-table', 'fp-lib-table') {
    $p = Join-Path $ProjectDir $tbl
    if (Test-Path -LiteralPath $p) {
        foreach ($m in [regex]::Matches((Get-Content -LiteralPath $p -Raw), '\(lib \(name "([^"]+)"\)\s*\(type "[^"]+"\)\s*\(uri "\$\{KIPRJMOD\}/[^"]*"\)')) { $local[$m.Groups[1].Value] = $true }
    }
}

function Test-Allowed([string]$lib) { return $stock.ContainsKey($lib) -or $local.ContainsKey($lib) -or $lib -like 'SJ_*' -or $lib -like 'PCM_*' }

$found = New-Object System.Collections.Generic.List[object]
$files = Get-ChildItem -LiteralPath $ProjectDir -Recurse -File |
    Where-Object { $_.Extension -in '.kicad_sch', '.kicad_pcb' -and $_.FullName -notmatch '\\(\.history|[^\\]*-backups)(\\|$)' }

foreach ($f in $files) {
    $t = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8
    $patterns = if ($f.Extension -eq '.kicad_sch') {
        @(@{ Kind = 'Símbolo'; Rx = '\(lib_id "([^":]+):([^"]+)"' }, @{ Kind = 'Huella'; Rx = '\(property "Footprint" "([^":]+):([^"]+)"' })
    } else {
        @(@{ Kind = 'Huella'; Rx = '\(footprint "([^":]+):([^"]+)"' })
    }
    foreach ($p in $patterns) {
        foreach ($m in [regex]::Matches($t, $p.Rx)) {
            $lib = $m.Groups[1].Value
            if (-not (Test-Allowed $lib)) {
                $found.Add([pscustomobject]@{ Tipo = $p.Kind; Libreria = $lib; Elemento = $m.Groups[2].Value; Archivo = $f.Name })
            }
        }
    }
}

foreach ($pro in Get-ChildItem -LiteralPath $ProjectDir -Filter '*.kicad_pro') {
    $j = Get-Content -LiteralPath $pro.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($ws in @($j.schematic.page_layout_descr_file, $j.pcbnew.page_layout_descr_file)) {
        if ($ws -and $ws -notmatch '^\$\{(SJ_KICAD_LIBS\}/sj_library/|KICAD\d+_TEMPLATE_DIR\}|KIPRJMOD\})') {
            $found.Add([pscustomobject]@{ Tipo = 'Hoja de dibujo'; Libreria = ($ws -replace '^\$\{([^}]+)\}.*', '$1'); Elemento = $ws; Archivo = $pro.Name })
        }
    }
}

if ($found.Count -eq 0) {
    Write-Host 'OK: el proyecto solo usa librerías estándar de KiCad, SJ_*, PCM_* o locales del proyecto.' -ForegroundColor Green
    exit 0
}
$found | Sort-Object Libreria, Elemento, Archivo -Unique | Format-Table -AutoSize
$libs = ($found | Select-Object -ExpandProperty Libreria -Unique) -join ', '
Write-Host ("{0} referencia(s) a librerías no permitidas: {1}" -f ($found | Sort-Object Libreria, Elemento, Archivo -Unique).Count, $libs) -ForegroundColor Red
exit 1
