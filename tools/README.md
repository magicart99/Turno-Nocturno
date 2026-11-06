# Herramientas de desarrollo

`verificar_rutas.py` comprueba referencias estáticas de los recursos jugables.

`generadores/` conserva las fuentes de audio, SVG, atlas y escenas. Varios generadores pertenecen a etapas históricas y reescriben niveles completos: no son pasos de instalación ni deben ejecutarse para jugar. La versión jugable vigente está en `src/` y `scenes/`.

`capturas/` contiene utilidades de captura y exportación de Godot. Ejecutarlas desde la raíz con `--path . --script res://tools/capturas/<archivo>.gd`.
