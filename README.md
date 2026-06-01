# Sudoku en C++ con Interfaz Grafica

Aplicacion de Sudoku para macOS con ventana nativa (AppKit), hecha en C++17.

## Caracteristicas

- Interfaz moderna fuera de terminal.
- Tablero 9x9 con estilo visual de bloques 3x3.
- Tres niveles de dificultad.
- Celdas fijas bloqueadas y celdas editables.
- Validacion de jugadas en tiempo real.
- Botones de nueva partida, comprobar y resolver.

## Ejecutar en macOS

Compila y abre la app de escritorio:

```bash
clang++ -std=c++17 -fobjc-arc main.mm -framework Cocoa -framework QuartzCore -o SudokuApp
./SudokuApp
```

## Uso

- Elige dificultad en el selector.
- Escribe numeros del 1 al 9 en celdas vacias.
- Deja una celda vacia para limpiarla.
- Usa Comprobar para validar estado.
- Usa Resolver para ver la solucion completa.
