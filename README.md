# Turno Nocturno: El último cuatrimestre

Juego de terror y sigilo en Godot 4.7.2. Lalo despierta encerrado en su universidad. El Archivero intenta borrar los nombres de quienes quedaron dentro. Para salir, debes recuperar pruebas y llevarlas a Don Chuy antes de convertirte en otro desaparecido.

## Ejecutar

Abre `project.godot` en Godot, espera la importación y pulsa F5. Selecciona **Iniciar juego** para conocer la historia revisada. Las partidas anteriores siguen siendo compatibles; no es necesario borrarlas. Después de actualizar carpetas, cierra cualquier ejecución anterior y vuelve a abrir el proyecto.

## Recorrido de la historia

1. Busca la llave en Dirección y enciende Rectoría desde el tablero de Entrada. Recupera tu expediente.
2. Alimenta Cómputo y habla con **la de Cómputo**. Basta elegir **Apagar el monitor y ayudarla**; ya no hay examen de asistencia ni secuencia de respuestas.
3. Recoge radio y pala, y usa la bitácora de Entrada para salir al patio.
4. Revisa la luz y el agua. Recoge la nota de la banca y excava la tierra removida. La **memoria USB aparece mientras excavas**; al terminar, pulsa interactuar para recogerla.
5. Lleva ambas pruebas a la Prefecta. Ella abre Servicios y te manda con **el de Talleres, en oficinas**.
6. Entrégale la USB: recupera la grabación y permite recoger la llave de servicio. Revisa cafetería y baños, y recoge el reporte del mostrador.
7. Entrega el reporte a Don Chuy y cruza la pluma. El Sello Roto permite el desenlace alternativo si conservas al menos 50 de cordura.

## Controles

| Acción | Teclado | Mando |
|---|---|---|
| Caminar | WASD / flechas | Stick izquierdo |
| Correr | Shift | LB / L1 |
| Interactuar | E | A / Cruz |
| Apuntar linterna | Ratón | Stick derecho |
| Linterna | F | X / Cuadrado |
| Agacharse | C / Ctrl | B / Círculo |
| Mapa completo | V / Tab / M | LT / RT |
| Mochila | I | Y / Triángulo |
| Distracción | Q | RB / R1 |
| Pausa | Esc | Start / Options |
| Guardar | F5 dentro del juego | Menú de pausa |

El plano está completo desde el comienzo. El minimapa muestra el entorno cercano sin niebla de exploración; V abre toda la zona. Los accesos cerrados siguen requiriendo avanzar en la historia. Las evidencias no consumen los seis espacios de suministros.

## Carpetas

- `assets/audio/`: música, efectos, voces y sus licencias.
- `assets/sprites/`: personajes, objetos, UI y elementos del campus.
- `assets/tilesets/`: pisos y paredes.
- `assets/fuentes/`, `assets/cinematicas/`: tipografía y vídeo.
- `assets/source_art/`: láminas originales de arte, separadas de los recursos jugables.
- `src/player/`, `src/enemies/`, `src/story/`, `src/world/`, `src/ui/`, `src/audio/`, `src/core/`: lógica del juego por responsabilidad.
- `scenes/`: niveles; `scenes/objetos/`: objetos reutilizables; `scenes/secciones/`: habitaciones.
- `tests/`: pruebas de Godot; `tools/`: generadores y capturas de desarrollo.
- `docs/`: documentación, procedencia, capturas y entregables. `docs/historial/` conserva documentación antigua, no la guía vigente.
- `partidas/`: partida y opciones locales. El `.bak` de la partida es recuperación automática activa, no una copia sobrante del proyecto.

`.godot/`, temporales, partidas y compilados están excluidos mediante `.gitignore`. Godot vuelve a crear su caché al importar. Los `.uid` y `.import` de los recursos se conservan porque contienen identidad y ajustes de importación.

## Validación

Desde la raíz, usando tu ejecutable de Godot:

```powershell
godot --headless --path . --script res://tests/probar_mejoras_v13.gd
godot --headless --path . --script res://tests/probar_mejoras_v12.gd
python tools/verificar_rutas.py
```

La prueba v13 usa una ranura de prueba separada. Con Godot en modo gráfico también captura los diálogos, excavación y mapa en `docs/mejoras_v13/`. Las pruebas anteriores documentan versiones históricas y algunas expectativas narrativas ya no aplican.

## Créditos y recursos

Proyecto y materiales originales proporcionados por su autor. Se conservan los personajes y dibujos originales. Programación, ajustes narrativos y organización realizados con asistencia de Codex. La procedencia específica del audio y las licencias se encuentran en `docs/audio_y_recursos.md` y en los directorios de audio. No se inventan nombres ni roles de integrantes que no figuran en el proyecto.
