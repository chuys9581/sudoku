# Nexus Sudoku Cyber 👾

![Multiplataforma](https://img.shields.io/badge/Plataforma-Windows%20%7C%20macOS%20%7C%20Linux-4B0082?style=for-the-badge&logo=windows)
![C++17](https://img.shields.io/badge/C%2B%2B17-00599C?style=for-the-badge&logo=c%2B%2B&logoColor=white)
![Raylib](https://img.shields.io/badge/Raylib-5.5-FFFFFF?style=for-the-badge)
![CMake](https://img.shields.io/badge/CMake-064F8C?style=for-the-badge&logo=cmake&logoColor=white)

Aplicación de Sudoku desarrollada nativamente en **C++17 puro**. El juego cuenta con una estética moderna estilo *Cyberpunk* (Cyber), animaciones fluidas, y un sistema persistente de cuentas de usuario, puntajes y mejores tiempos. Utiliza la librería **Raylib** para gráficos universales y **CMake** para compilar automáticamente en cualquier sistema operativo.

---

## 🚀 Características del Proyecto

A continuación se detalla el estado actual de las funcionalidades integradas en el proyecto:

### 🔐 Acceso al Sistema
- [x] Pantalla de inicio de sesión animada.
- [x] Sistema de Login seguro (hasheado de contraseñas).
- [x] Creación de nuevo usuario con inputs interactivos de texto.
- [x] Menú principal (Dashboard).

### 🖥️ Interfaz
- [x] Tablero tradicional de Sudoku 9x9.
- [x] Panel de usuario en tiempo real (vidas, puntos, tiempo).
- [x] Panel interactivo de controles.
- [x] Diseño estético *Cyber* (colores oscuros, neones cian, verde y azul).
- [x] Resaltado dinámico de la casilla seleccionada.

### 🎮 Jugabilidad
- [x] Funcionalidad controlable con Mouse y Teclado.
- [x] Casillas originales bloqueadas e inmutables.
- [x] Validación matemática en tiempo real contra la solución del tablero.
- [x] Sistema de vidas limitadas (penalización por errores).
- [x] Sistema de Puntuación dinámico (+120 por acierto, -25 por error).
- [x] Pantalla y condición de *Game Over*.
- [x] Pantalla dinámica de *Victoria* con bonificación de puntos.

### 👥 Sistema de Usuarios y Ranking
- [x] Guardado de puntos al finalizar la partida.
- [x] Persistencia de datos en disco local (`users.txt`).
- [x] Ordenamiento automático por máxima puntuación (Top Players).

### 🎚️ Niveles y Dificultad
- [x] Fácil (Easy) - Más casillas reveladas, más vidas iniciales.
- [x] Medio (Medium) - Balance estándar de Sudoku.
- [x] Difícil (Hard) - Menos casillas iniciales, máximo reto.
- [x] Generación procedural de un tablero 100% distinto para cada dificultad.

### ⏱️ Tiempo y Velocidad
- [x] Cronómetro funcional en tiempo real para la partida activa.
- [x] Guardado y registro del mejor tiempo final de resolución por usuario.

### ✨ Efectos Visuales
- [x] Iluminación especial dinámica cuando se completan bloques de 3x3 celdas.
- [x] Fondo estilizado de rejilla estilo *Tron* o Cyber.

---

## ⚙️ Arquitectura Técnica

- **Lógica Matemática (`SudokuEngine.h`):** Es el cerebro de la aplicación. Se encarga de la generación aleatoria de tableros válidos de Sudoku mediante transformaciones (mezcla de bandas, columnas y filas de una semilla inicial resuelta).
- **Controlador e Interfaz Gráfica (`main.cpp`):** Maneja el Game Loop a 60 FPS utilizando **Raylib**. Lee los inputs del teclado, procesa los clics del mouse en la cuadrícula de celdas 9x9, y dibuja los gráficos visuales sin depender de ningún sistema operativo específico.
- **Sistema de Construcción (`CMakeLists.txt`):** Usa `FetchContent` para descargar dinámicamente Raylib de GitHub antes de compilar el proyecto, evitando que los usuarios instalen dependencias engorrosas a mano.

---

## 🛠️ Cómo Ejecutar el Juego (Windows, macOS, Linux)

Para ejecutar este juego, la computadora requiere tener instalado **CMake** y un compilador básico de C++ (ej. Visual Studio, Xcode, o MinGW). 

### Pasos:
1. Abre tu terminal (Símbolo del sistema en Windows / Terminal en Mac).
2. Navega al directorio del proyecto:
   ```bash
   cd /ruta/hacia/tu/proyecto/sudoku
   ```
3. Crea una carpeta de compilación y entra en ella:
   ```bash
   mkdir build
   cd build
   ```
4. Configura el proyecto con CMake (Descargará Raylib automáticamente):
   ```bash
   cmake ..
   ```
5. Compila el código ejecutable:
   ```bash
   make
   ```
   *(O alternativamente usa `cmake --build .` si usas Visual Studio)*

6. Ejecuta el juego:
   ```bash
   ./SudokuApp
   ```
   *(En Windows, haz doble clic en `SudokuApp.exe`)*
