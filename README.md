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

## Novedades v14: atmósfera, historia y tablero

- **Introducción y finales narrados.** Al iniciar se cuenta cómo Lalo se quedó dormido en Dirección (una vez por sesión; Esc la omite). Los dos finales terminan con un amanecer y un epílogo distinto.
- **Cordura según el GDD.** Cada detección cercana del Archivero y cada susto restan cordura. Si llega a 0, Lalo se convierte en Eco: aparece «expediente cerrado» y puedes reintentar desde el guardado (vuelves con al menos 20 de cordura).
- **Archivero por nivel.** Lento en el edificio principal, normal en patio y servicios, rápido en el estacionamiento. Al investigar emite un resplandor rojo, deja una estela, suelta hojas de expediente y a veces susurra.
- **Radio de Don Chuy.** Habla al cambiar de nivel. Lalo comenta los objetos clave. Excavar el patio entrega el **Archivo 001**, con el origen del Archivero y la pista del Sello Roto en Rectoría.
- **Efectos visuales.**
  - Polvo visible en el haz de la linterna.
  - Sombras bajo los personajes y polvo de pisadas.
  - Mensajes en el piso que solo revela la luz.
  - La linterna falla cuando el Archivero está cerca.
  - Viñeta que respira y sobresalto de cámara.
  - Fundido al cambiar de lugar y Ecos que flotan y parpadean.
  - Marca flotante sobre el objeto interactivo más cercano.
- **Tablero eléctrico rediseñado.**
  - El cable sigue al ratón o al terminal enfocado.
  - Los cortocircuitos lanzan chispas y sacuden la pantalla.
  - A mitad de la reparación algo golpea la caja.
  - El último paso es un medidor de aguja con ritmo variable.
  - Los chispazos se oyen en el pasillo al cerrar el tablero.
  - Un circuito **ya reparado se conmuta sin repetir los cables**.

## Novedades v17: salones, HUD, caminado y funciones del plan de trabajo

- **Salones** (al cargar, sin editar `escuela.tscn`):
  - pupitres negros de paleta en pixel art, que sustituyen mesa y silla;
  - escritorio del maestro, pizarrón blanco con plumón, minisplit con LED y aire frío;
  - puertas de vidrio que dejan pasar la luz.
  - Sprites en `assets/sprites/aula/`.
- **Interior.** Vitropiso color crema con brillo bajo las luces, piso de baño de baldosa chica y muros blanquecinos con zócalo.
- **HUD.** Panel de estado con icono, barra con estela de daño, valor y aviso rojo por debajo de 25 para cordura, resistencia, pila y sigilo. Al pie: dinero, mochila, circuito y postura.
- **Caminado de Lalo.** Fundido entre cuadros, rebote de cadera, balanceo sin deformar el pixel art, zancada de carrera y respiración en reposo.
- **Plan de trabajo:**
  - **puntos seguros** que guardan y recuperan cordura (sala de espera, cafetería, caseta);
  - **tutorial contextual**;
  - **puzle de la de Cómputo** (asustarla delata a Lalo);
  - **gafete de un solo uso**;
  - **pasillo en bucle** hasta tener la llave maestra;
  - **flashback** al leer los 10 documentos;
  - **atuendos** persistentes (en Controles y opciones);
  - **música por nivel**;
  - «Volver al último punto seguro» en la pausa.
- **Depurador.**
  - Corregida una división entera (`sonidos.gd`) y una conversión con pérdida (`archivero.gd`).
  - El haz de la linterna ya no genera errores de triangulación pegado a una pared.

## Novedades v16: dirección artística, terror e IA (prueba, se puede revertir)

- **Escenario.**
  - Muros con cara visible (vista 3/4) y sombra de contacto.
  - Suelos con manchas, humedad y grano según la posición en el mundo.
  - Los muebles proyectan sombras con la linterna y la luz de Lalo; las lámparas no, para cuidar el rendimiento.
- **Luz y color.**
  - Haz de linterna volumétrico con polvo animado, recortado por muros y muebles.
  - Una sola gradación de pantalla: sombras frías, contraste y aberración cromática con el peligro.
- **Personajes.** Lalo, el Archivero, Don Chuy y los Ecos usan mipmaps: el pixel art reducido ya no parpadea al moverse.
- **Terror.**
  - El Archivero emite un murmullo continuo que se oye más apagado tras las paredes. Solo brilla en rojo al investigar.
  - El director de tensión silencia el ambiente antes de cada evento: apagón que avanza hacia ti, pasos que imitan los tuyos, el Archivero asomándose al fondo del haz y una llamada por el altavoz.
- **IA.**
  - De cerca, el Archivero sigue a Lalo si hace ruido o lleva la linterna.
  - Si te pierde junto a tu escondite, lo revisa; mientras escucha, tu sigilo se agota y, si llega a cero, te encuentra.
- **Historia.**
  - Diez documentos repartidos por las salas y el campus, guardados en el diario de la mochila.
  - Los finales revelan el bucle de seis años.
  - La ayuda de controles desaparece tras los primeros minutos.

## Novedades v15: interfaz, misiones, lugares y caminado

- **Menú principal.** El título falla como neón y la frase de abajo cambia cada pocos segundos. Hay líneas de video, un contador «● REC» y las opciones aparecen una tras otra. Los botones deslizan su texto y hacen clic al enfocarlos.
- **HUD.**
  - Barras de cordura, resistencia y pila que laten en rojo por debajo de 25.
  - Aviso «OBJETIVO ACTUALIZADO» que entra desde la izquierda.
- **Mochila y tienda.**
  - Franja de color por categoría.
  - El icono crece al seleccionarlo y la imagen del objeto flota.
  - Botón **Misiones**: lista por nivel con lo hecho y lo pendiente, incluidos los pasos opcionales del final alternativo.
- **Minimapa.** Barrido de radar, marcas de brújula y anillo rojo de peligro.
- **Plano.** Cuadrícula de plano técnico, ruta animada, destino que pulsa y cono de la linterna.
- **Salones y baños.**
  - Pizarrones con mensajes de gis que cambian con poca cordura.
  - Relojes detenidos a las 00:00.
  - Sillas que se arrastran solas (solo visual).
  - Reflejos fugaces en los espejos.
- **Cafetería.** Hornilla encendida con vapor hasta revisarla, luz de neón que falla sobre el mostrador y luz roja en los baños pendientes.
- **Caminado de Lalo.** Arranque y frenado con peso, inclinación al avanzar (más al correr), compresión al girar y en cada paso.
- **Depurador.** Se corrigieron dos avisos de división entera y se libera el video de muerte si cierras el juego durante la cinemática.

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
godot --headless --path . --script res://tests/probar_mejoras_v14.gd
godot --headless --path . --script res://tests/probar_mejoras_v13.gd
godot --headless --path . --script res://tests/probar_mejoras_v12.gd
python tools/verificar_rutas.py
```

La prueba v13 usa una ranura de prueba separada. Con Godot en modo gráfico también captura los diálogos, excavación y mapa en `docs/mejoras_v13/`. Las pruebas anteriores documentan versiones históricas y algunas expectativas narrativas ya no aplican.

## Créditos y recursos

Proyecto y materiales originales proporcionados por su autor. Se conservan los personajes y dibujos originales. Programación, ajustes narrativos y organización realizados con asistencia de Codex. La procedencia específica del audio y las licencias se encuentran en `docs/audio_y_recursos.md` y en los directorios de audio. No se inventan nombres ni roles de integrantes que no figuran en el proyecto.
