# sj_library: librería KiCad personal de Sebastian Jaimes

Librería de símbolos, huellas y modelos 3D para **KiCad 10**, organizada por categorías con el prefijo `SJ_`. Se integra en KiCad a través de un **hub** de tablas anidadas, junto con la librería estándar de KiCad y, en el PC del trabajo, las librerías de MS4M.

```
kicad_libraries\                 ← ${SJ_KICAD_LIBS}
├─ hub\                          ← única entrada registrada en KiCad
│  ├─ sym-lib-table, fp-lib-table      (KiCad estándar + SJ + MS4M)
│  └─ ms4m\sym-lib-table, fp-lib-table (librerías dhw_* de la empresa)
└─ sj_library\                   ← este repositorio
   ├─ symbols\SJ_<Cat>.kicad_sym
   ├─ footprints\SJ_<Cat>.pretty\
   ├─ 3dmodels\SJ_<Cat>.3dshapes\        (STEP/WRL en Git LFS)
   ├─ sym-lib-table, fp-lib-table        (categorías SJ; las anida el hub)
   ├─ worksheets\SJ_A4.kicad_wks
   ├─ templates\SJ_Project\              (plantilla de proyecto con BOM y campos SJ)
   ├─ tools\validate_library.ps1         (valida formato, campos y huellas)
   ├─ tools\check_project_libs.ps1       (detecta librerías no permitidas en un proyecto)
   └─ docs\
```

## Categorías

| Librería | Contenido |
|---|---|
| `SJ_Sensor` | Sensores (IMU, presión, temperatura, corriente) |
| `SJ_Power` | Reguladores, convertidores DC-DC, gestión de energía |
| `SJ_MCU` | Microcontroladores y procesadores |
| `SJ_Connector` | Conectores |
| `SJ_Protection` | ESD, TVS, filtros EMI, fusibles |
| `SJ_Interface` | Transceptores, traductores de nivel, drivers |
| `SJ_RF` | Radio, antenas, módulos RF discretos |
| `SJ_Audio` | Buzzers, altavoces, códecs |
| `SJ_Discrete` | Transistores, diodos y discretos específicos |
| `SJ_Mechanical` | Huecos de montaje, pads de potencia, fiduciales |
| `SJ_Module` | Módulos y placas hijas |
| `SJ_Template` | Solo símbolos plantilla con los campos SJ (no se usa en esquemáticos) |

## Documentación

- [docs/SETUP_PC_LIMPIO.md](docs/SETUP_PC_LIMPIO.md): instalación desde cero.
- [docs/CONVENCIONES.md](docs/CONVENCIONES.md): nombres, campos, reglas de símbolos y huellas.
- [docs/CHECKLIST_COMPONENTE.md](docs/CHECKLIST_COMPONENTE.md): cómo se crea y verifica una pieza.
- [docs/ADOPCION_EMPRESA.md](docs/ADOPCION_EMPRESA.md): cómo llevar este esquema a un equipo.

## Uso rápido

```powershell
# Validar la librería antes de cada commit
.\tools\validate_library.ps1

# Comprobar que un proyecto personal no depende de librerías externas no permitidas
.\tools\check_project_libs.ps1 C:\ruta\al\proyecto
```
