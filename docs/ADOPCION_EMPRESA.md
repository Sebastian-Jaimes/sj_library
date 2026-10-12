# Adopción del esquema en un equipo (por ejemplo, MS4M)

Este esquema se diseñó para que la versión personal y la de empresa sean **la misma arquitectura con otro prefijo**.

## Equivalencias

| Personal | Empresa |
|---|---|
| `SJ_KICAD_LIBS` | `MS4M_KICAD_LIBS` (una sola raíz en lugar de `MS4M_SYMBOL`, `MS4M_FOOTPRINT` y `MS4M_3DMOD`) |
| `sj_library` (un repo) | `ms4m_library`: símbolos, huellas y 3D en **un solo repo**, para que una pieza quede completa en un único commit |
| `SJ_<Cat>` | `MSS_<Cat>` (el prefijo actual) |
| `hub/` | `hub/` versionado en su propio repo pequeño, igual en todos los PCs |
| Revisión propia con el checklist | **Revisión por pares**: *pull request* con el checklist y las vistas previas SVG |

## Pasos sugeridos

1. **Inventario.** Ejecutar `check_project_libs.ps1` sobre los proyectos activos para ver qué librerías se usan realmente.
2. **Unificar repos.** Juntar `dhw_symbols`, `dhw_footprints` y `dhw_packages3d` en un solo repo. Se puede hacer conservando el historial con `git subtree` o con `git filter-repo`. Hay que reescribir las rutas 3D a `${MS4M_KICAD_LIBS}/ms4m_library/3dmodels/...`.
3. **Hub común.** Repo `ms4m_kicad_hub` con las tablas anidadas. Cada ingeniero registra **solo** el hub en KiCad.
4. **Convenciones y checklist.** Partir de `CONVENCIONES.md` y `CHECKLIST_COMPONENTE.md`, adaptando los campos a los de la empresa.
5. **CI.** Ejecutar `validate_library.ps1` (o su equivalente en un contenedor con `kicad-cli`) en cada pull request. Opcionalmente, añadir el verificador oficial de la KLC (`kicad-library-utils`).
6. **Proyectos congelados.** En cada release de hardware, exportar las librerías usadas al propio proyecto (*Export Symbols / Footprints to New Library* → `libs/` con tabla `${KIPRJMOD}`), para que el release sea reproducible aunque la librería evolucione.
7. **Migración por versión de KiCad.** Con el hub, cambiar de versión es actualizar `KICADxx_TEMPLATE_DIR` en el hub y registrar el hub en la nueva versión.

## Beneficios para el equipo

- Todo el equipo ve las mismas librerías, porque el hub es idéntico en todos los PCs.
- Nada vive en `Program Files` ni en carpetas atadas a una versión de KiCad.
- Cada pieza nueva pasa por un proceso verificable (checklist, validación y revisión).
- Un proyecto puede auditarse en segundos con `check_project_libs.ps1`.
