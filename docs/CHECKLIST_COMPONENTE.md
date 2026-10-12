# Checklist: agregar un componente a la librería SJ

## 0. ¿Hace falta crearlo?

Se busca en este orden y se usa la primera fuente que exista:

1. **Librería estándar de KiCad.** Se referencia, no se copia. Se busca por MPN y por encapsulado en el navegador de símbolos y huellas.
2. **PCM del fabricante** (por ejemplo, Espressif).
3. **Generada con el Footprint Wizard** del Footprint Editor, para encapsulados estándar (QFN, SOIC, SOT, LGA…), a partir de las cotas del datasheet.
4. **Modelo publicado por el propio fabricante** en su web, descargado y revisado a mano.
5. **Dibujada desde el datasheet.**

## 1. Selección (antes de dibujar nada)

- [ ] Ciclo de vida **Active** en DigiKey o Mouser (no NRND/EOL/LTB).
- [ ] Temperatura de operación de −40 a +85 °C o más.
- [ ] Encapsulado sin BGA.
- [ ] Stock disponible en al menos un distribuidor autorizado.
- [ ] Datasheet del fabricante descargado, con su versión anotada.

## 2. Símbolo (`SJ_<Cat>`)

- [ ] Copiado de `SJ_Template:SJ_IC_Template` y renombrado con el `Mfg Part #`.
- [ ] Todos los pines del datasheet presentes, con número y nombre correctos.
- [ ] Tipo eléctrico correcto en cada pin; los NC marcados como `no_connect`.
- [ ] Disposición: entradas a la izquierda, salidas a la derecha, alimentación arriba y GND abajo, sobre la rejilla de 100 mil.
- [ ] `Reference`, `Value`, `Footprint`, `Datasheet` y `Description` completos.
- [ ] Campos SJ: `Manufacturer` y `Mfg Part #` obligatorios; el resto, lo que aplique.

## 3. Huella (`SJ_<Cat>.pretty`), si no existe en la librería estándar

- [ ] Land pattern recomendado por el fabricante (o IPC-7351 nominal), con las cotas comprobadas contra el plano mecánico.
- [ ] Numeración de pads idéntica a la del símbolo, incluido el pad térmico.
- [ ] Origen en el centro (SMD).
- [ ] Capas `F.Fab`, `F.SilkS` y `F.CrtYd` según CONVENCIONES.md; marca del pin 1 en Fab y Silk.
- [ ] Pasta en el pad térmico: ventanas de pasta si el fabricante lo indica.
- [ ] Impresión 1:1 sobre papel y comparación con la pieza física o con el plano, en piezas críticas.

## 4. Modelo 3D

- [ ] STEP del fabricante o generado; con el mismo nombre que la huella.
- [ ] Ruta con `${SJ_KICAD_LIBS}/sj_library/3dmodels/...`.
- [ ] Offset y rotación verificados en el visor 3D (pines sobre los pads).

## 5. Cierre

- [ ] `.\tools\validate_library.ps1` sin errores; revisar el SVG en `out/preview/`.
- [ ] Probado en un esquemático y una PCB de prueba: ERC y DRC sin errores atribuibles a la pieza.
- [ ] Commit: `add(SJ_<Cat>): <MPN>`.
