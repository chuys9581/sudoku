# Nexus Sudoku Cyber 👾

![macOS](https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white)
![C++17](https://img.shields.io/badge/C%2B%2B17-00599C?style=for-the-badge&logo=c%2B%2B&logoColor=white)
![Objective-C++](https://img.shields.io/badge/Objective--C%2B%2B-3A95E3?style=for-the-badge&logo=apple&logoColor=white)

Aplicación de Sudoku desarrollada nativamente para macOS usando **C++17** (lógica del juego) y **Objective-C++ con AppKit** (Interfaz Gráfica). El juego cuenta con una estética moderna estilo *Cyberpunk* (Cyber), animaciones fluidas, y un sistema persistente de cuentas de usuario, puntajes y mejores tiempos.

---

## 🚀 Características del Proyecto

A continuación se detalla el estado actual de las funcionalidades integradas en el proyecto:

### 🔐 Acceso al Sistema
- [x] Pantalla de carga animada inicial.
- [x] Sistema de Login seguro (hasheado de contraseñas).
- [x] Creación de nuevo usuario.
- [x] Validación estricta de usuarios (caracteres permitidos, longitud de contraseña).
- [x] Menú principal (Dashboard).

### 🖥️ Interfaz
- [x] Tablero tradicional de Sudoku 9x9.
- [x] Panel de usuario en tiempo real (vidas, puntos, tiempo, movimientos).
- [x] Panel interactivo de controles (Nueva Partida, Comprobar, Resolver, etc.).
- [x] Diseño estético *Cyber* (colores oscuros, neones cian, verde y azul).
- [x] Resaltado dinámico de la casilla seleccionada y su eje (fila/columna).

### 🎮 Jugabilidad
- [x] Funcionalidad 100% controlable con el Mouse/Trackpad.
- [x] Selección intuitiva de casillas.
- [x] Colocar y borrar números de forma sencilla.
- [x] Casillas originales bloqueadas e inmutables.
- [x] Validación en tiempo real contra la solución del tablero.
- [x] Sistema de vidas limitadas (penalización por errores).
- [x] Sistema de Puntuación dinámico (+120 por acierto, -25 por error).
- [x] Pantalla y condición de *Game Over* (al perder todas las vidas).
- [x] Pantalla dinámica de *Victoria* con bonificación de puntos.

### 👥 Sistema de Usuarios y Ranking
- [x] Guardado de puntos al finalizar la partida.
- [x] Persistencia de datos en disco local (`users.txt`).
- [x] Sistema de Ranking *"Top Operators"*.
- [x] Visualización en el menú de los mejores jugadores.
- [x] Ordenamiento automático por máxima puntuación.

### 🎚️ Niveles y Dificultad
- [x] Fácil (Easy) - Más casillas reveladas, más vidas iniciales.
- [x] Medio (Medium) - Balance estándar de Sudoku.
- [x] Difícil (Hard) - Menos casillas iniciales, máximo reto.
- [x] Generación procedural de un tablero 100% distinto para cada dificultad.

### ⏱️ Tiempo y Velocidad
- [x] Cronómetro funcional en tiempo real para la partida activa.
- [x] Guardado y registro del mejor tiempo final de resolución por usuario.

### ✨ Efectos Visuales
- [x] Los bloques de 3x3 cambian de color de forma permanente al completarse.
- [x] Efecto visual de iluminación y destello (Glow/Flash) en el sector recién completado.
- [x] Pantalla de victoria estilizada (Overlay oscuro *Fade-in*).

---

## ⚙️ Arquitectura Técnica

- **Engine (Lógica):** Implementada puramente en C++ (`SudokuEngine`). Se encarga de la generación aleatoria de tableros válidos de Sudoku mediante transformaciones (mezcla de bandas, columnas y filas).
- **Controlador (UI):** Implementado en Objective-C++ (`SudokuController`). Usa `AppKit` (`NSWindow`, `NSView`, `NSTextField`, `NSButton`) de forma programática (sin Interface Builder / Storyboards) para dibujar la interfaz *Cyber* y comunicarse con el Engine.
- **Persistencia:** Almacenamiento local mediante archivos de texto que guardan hashes de contraseñas, puntos acumulados y récords de tiempo (`userBestTimes_`).

---

## 🛠️ Cómo Ejecutar el Juego (macOS)

Al ser una aplicación nativa, solo requieres tener las herramientas de línea de comandos de Xcode (`clang++`) instaladas en tu Mac. No necesitas dependencias externas pesadas.

1. Abre tu terminal.
2. Navega al directorio del proyecto:
   ```bash
   cd /ruta/hacia/tu/proyecto/sudoku
   ```
3. Compila el código fuente usando `clang++`:
   ```bash
   clang++ -std=c++17 -fobjc-arc main.mm -framework Cocoa -framework QuartzCore -o SudokuApp
   ```
4. Ejecuta el archivo binario generado:
   ```bash
   ./SudokuApp
   ```

*(Nota: La aplicación iniciará instantáneamente una ventana nativa de macOS).*
