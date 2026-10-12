# Convenciones de la librería SJ

La base es la **KLC (KiCad Library Convention)**: https://klc.kicad.org. Son las reglas que sigue la librería oficial de KiCad. Este documento recoge solo las reglas propias y las de la KLC que más importan. Ante una duda no cubierta aquí, se aplica la KLC.

## 1. Organización

- Una librería por categoría y tipo: `symbols/SJ_<Cat>.kicad_sym`, `footprints/SJ_<Cat>.pretty`, `3dmodels/SJ_<Cat>.3dshapes`. Las tres comparten el nombre `SJ_<Cat>`.
- Una categoría nueva se agrega en los tres sitios y en `sym-lib-table` / `fp-lib-table` de este repo. El hub la incluye sola.
- **Las librerías estándar de KiCad nunca se copian ni se editan.** Si una pieza ya existe ahí, se referencia directamente; por ejemplo, `Connector_AMASS:AMASS_XT60-M_1x02_P7.20mm_Vertical`.
- **Las librerías de fabricantes** (Espressif, etc.) se instalan con el PCM. Si una pieza de ellas necesita correcciones, se copia a `SJ_<Cat>` y se corrige ahí.

## 2. Campos

Campos propios. **Todo símbolo de `SJ_<Cat>` debe tenerlos, pero vacíos en la librería.** Son datos de la **selección de componentes**: se completan en el esquemático cuando se elige la pieza concreta, porque pueden cambiar (otro fabricante, otro proveedor, otro precio o el mismo componente con distinta tolerancia). `validate_library.ps1` comprueba que existan y avisa si alguno tiene valor.

La librería define **qué es** la pieza (símbolo, pinout, huella, datasheet, descripción). El esquemático define **cuál se compra**.

| Campo (se llena en el esquemático) | Contenido | Ejemplo |
|---|---|---|
| `Manufacturer` | Fabricante | `Bosch Sensortec` |
| `Mfg Part #` | **Número de parte del fabricante: identidad única de la pieza** | `BMP581` |
| `LCSC Part #` | Código LCSC (compras personales / JLCPCB) | `C5362283` |
| `Supplier` | Distribuidor de compra | `DigiKey` |
| `Cost` | Costo unitario de referencia | `2.10 USD @100` |
| `Voltage` | Tensión nominal o máxima | `3.6 V` |
| `Current` | Corriente nominal o máxima | `1.3 mA` |
| `TC` | Coeficiente de temperatura / dieléctrico | `X7R` |
| `Power` | Potencia | `0.1 W` |
| `Tol` | Tolerancia | `1 %` |

Los campos que genera KiCad (`Reference`, `Value`, `Footprint`, `Datasheet`, `Description`, `ki_keywords`, `ki_fp_filters`) se completan siempre. `Datasheet` enlaza al documento **del fabricante**.

Para crear un símbolo nuevo, se copia `SJ_Template:SJ_IC_Template`, que ya trae todos los campos.

## 3. Símbolos

- **Nombre:** el número de parte base, sin sufijo de embalaje (`R`/`T` de bobina), como hace KiCad. Si la pieza existe en varios encapsulados con distinto pinout o número de pines, se agrega el código de encapsulado del fabricante: `TPS54331DDA` (SO PowerPAD-8) frente a `TPS54331D` (SOIC-8). El número completo (`TPS54331DDAR`) se escribe en `Mfg Part #` durante la selección de componentes.
- **Un símbolo por pieza y encapsulado:** cada símbolo tiene su pinout y su huella asignada; los campos SJ quedan vacíos.
- **Pasivos genéricos (R, C, L):** se usan los de `Device` de la librería estándar. Los campos SJ se llenan en el esquemático, al final del diseño.
- **Rejilla de 100 mil (2,54 mm)** para el origen de los pines, que van fuera del cuerpo.
- **Disposición:** entradas a la izquierda, salidas a la derecha, alimentación arriba y GND abajo. Los pines se agrupan por función, no por número.
- **Nombres de pin:** los del datasheet. Las señales activas en bajo se marcan con `~{...}`, por ejemplo `~{RESET}`.
- **Tipo eléctrico correcto** en cada pin: `power_in`, `input`, `output`, `bidirectional`, `passive`, etc. Es lo que hace útil el ERC.
- `Reference` con el prefijo estándar: U, J, D, Q, R, C, L, Y, SW, BZ, FB, TP, H.

## 4. Huellas

- **Nombre:**
  - Encapsulado estándar: `Package_Size_Pitch`, al estilo KLC. Por ejemplo, `LGA-10_2x2mm_P0.5mm`.
  - Pieza específica del fabricante: `Fabricante_MPN[_variante]`. Por ejemplo, `Bosch_BMP581` o `Molex_472192001`.
- **Origen:** en el centro del encapsulado para SMD (lo usa el pick and place) y en el pin 1 para conectores THT cuando el fabricante lo indique.
- **Capas obligatorias:**
  - `F.Fab`: contorno real, marca del pin 1 y `${REFERENCE}`.
  - `F.SilkS`: contorno sin solaparse con los pads, con marca del pin 1.
  - `F.CrtYd`: courtyard a 0,25 mm del cuerpo y los pads (0,5 mm en conectores), con rejilla de 0,01 mm.
- **Land pattern:** el recomendado por el fabricante. Si no lo publica, se usa IPC-7351 nominal.
- **Pads:** se numeran igual que los pines del símbolo. El pad térmico se numera según el datasheet (por ejemplo, `EP` o el número siguiente).

## 5. Modelos 3D

- Formato **STEP** (obligatorio) y, opcionalmente, WRL. Llevan **el mismo nombre que la huella**.
- La ruta siempre usa variable: `${SJ_KICAD_LIBS}/sj_library/3dmodels/SJ_<Cat>.3dshapes/<Huella>.step`.
- El modelo debe quedar alineado con los pads (offset y rotación verificados en el visor 3D).

## 6. Requisitos de selección de componentes

- Temperatura de operación de **−40 a +85 °C** como mínimo.
- Ciclo de vida **Active**: nada de NRND, EOL ni *Last Time Buy*.
- **Sin BGA.**
- Disponible en distribuidores autorizados (DigiKey / Mouser); LCSC es opcional.
- ESD IEC 61000-4-2 nivel 4 en todo lo que sale de la placa (requisito de diseño, no de la librería).

## 7. Commits

- Un commit por pieza o por cambio lógico.
- Mensaje: `add(SJ_Sensor): BMP581`, `fix(SJ_Power): TPS54331 pad térmico`, `docs: ...`.
- `tools/validate_library.ps1` debe terminar sin errores antes de hacer commit.
