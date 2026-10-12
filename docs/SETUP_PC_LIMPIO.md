# Instalación desde un PC limpio

Tiempo estimado: unos 20 minutos.

## 1. Software

1. **KiCad 10**, instalado en la ruta por defecto. **Nunca guardes librerías dentro de `C:\Program Files\KiCad`**: se pierden al desinstalar o actualizar.
2. **Git** y **Git LFS** (`git lfs install`).

## 2. Clonar las librerías

```powershell
mkdir C:\Users\<usuario>\kicad_libraries
cd C:\Users\<usuario>\kicad_libraries
git clone <url-de-sj_library> sj_library
# Solo en el PC de trabajo: clonar también dhw_symbols, dhw_footprints, dhw_packages3d, kicad_templates
```

Crea el hub copiando la plantilla del repo:

```powershell
mkdir hub
copy sj_library\hub_template\* hub\
```

Solo en el PC de trabajo: crea también `hub\ms4m\sym-lib-table` y `hub\ms4m\fp-lib-table` con las librerías `MSS_*` (rutas `${MS4M_SYMBOL}/...` y `${MS4M_FOOTPRINT}/...`). No se versionan aquí porque son de la empresa.

## 3. Variables de ruta en KiCad

*Preferences → Configure Paths…*, en la tabla de variables de entorno:

| Variable | Valor | Cuándo |
|---|---|---|
| `SJ_KICAD_LIBS` | `C:\Users\<usuario>\kicad_libraries` | Siempre |
| `KICAD_USER_TEMPLATE_DIR` | `C:\Users\<usuario>\kicad_libraries\sj_library\templates` | Siempre (plantillas de proyecto) |
| `MS4M_TEMPLATE`, `MS4M_PROJECT_TEMPLATE` | rutas a `kicad_templates` y `dhw_project_template` | Solo trabajo |

Las variables `KICAD10_*` las define KiCad y no se tocan. En esta tabla escribe siempre **rutas absolutas**, sin anidar otras variables. Las variables sí se usan dentro de las tablas de librerías y de las rutas 3D.
| `MS4M_SYMBOL` | `C:\Users\<usuario>\kicad_libraries\dhw_symbols` | Solo trabajo |
| `MS4M_FOOTPRINT` | `C:\Users\<usuario>\kicad_libraries\dhw_footprints` | Solo trabajo |
| `MS4M_3DMOD` | `C:\Users\<usuario>\kicad_libraries\dhw_packages3d` | Solo trabajo |

## 4. Registrar el hub (la única entrada global)

*Preferences → Manage Symbol Libraries… → Global Libraries*:

1. Elimina las entradas existentes, o déjalas solo si vienes de una instalación previa y aún no has migrado.
2. Añade una fila: nickname `HUB`, tipo **Table**, ruta `${SJ_KICAD_LIBS}/hub/sym-lib-table`.

*Preferences → Manage Footprint Libraries… → Global Libraries*:

3. Añade una fila: nickname `HUB`, tipo **Table**, ruta `${SJ_KICAD_LIBS}/hub/fp-lib-table`.

El hub ya incluye la librería estándar de KiCad (`${KICAD10_TEMPLATE_DIR}`), la SJ y la de MS4M. En un PC solo personal, elimina la fila `MS4M` de los dos archivos del hub.

Si prefieres editar los archivos a mano (con KiCad cerrado), el resultado en `%APPDATA%\kicad\10.0\sym-lib-table` es:

```
(sym_lib_table
	(version 7)
	(lib (name "HUB") (type "Table") (uri "${SJ_KICAD_LIBS}/hub/sym-lib-table") (options "") (descr "Hub de librerías"))
)
```

Lo mismo para `fp-lib-table`, con `fp_lib_table` y `hub/fp-lib-table`.

## 5. Librerías de fabricantes (PCM)

En la ventana principal de KiCad, abre el **Plugin and Content Manager**:
- Pestaña *Libraries*: instala las de los fabricantes que uses (por ejemplo, **Espressif**).
- El PCM las guarda en `Documents\KiCad\10.0\3rdparty` y las registra solo, con prefijo `PCM_`. **No guardes nada propio en esa carpeta.**

## 6. Verificación

1. Abre el Symbol Editor: deben aparecer las librerías estándar, las `SJ_*` y, si corresponde, las `MSS_*` y `PCM_*`.
2. Abre `SJ_Template:SJ_IC_Template` y comprueba que muestra los 10 campos.
3. En PowerShell:
   ```powershell
   cd C:\Users\<usuario>\kicad_libraries\sj_library
   .\tools\validate_library.ps1
   ```
4. Crea un proyecto desde la plantilla *SJ Project* (*File → New Project from Template*).

## 7. Cambio de versión de KiCad (por ejemplo, de la 10 a la 11)

1. En `hub/sym-lib-table` y `hub/fp-lib-table`, cambia `${KICAD10_TEMPLATE_DIR}` por `${KICAD11_TEMPLATE_DIR}`.
2. Repite los pasos 3 y 4 en la nueva versión. Son 1–5 variables y 2 filas.
3. Ejecuta `kicad-cli sym upgrade` / `fp upgrade` sobre `sj_library` si la nueva versión cambia el formato, y haz commit.
