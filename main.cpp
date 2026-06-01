#include <algorithm>
#include <array>
#include <chrono>
#include <iomanip>
#include <iostream>
#include <numeric>
#include <random>
#include <sstream>
#include <string>
#include <vector>

namespace {

using Grid = std::array<std::array<int, 9>, 9>;

class Sudoku {
public:
    Sudoku() : rng_(static_cast<unsigned>(std::chrono::high_resolution_clock::now().time_since_epoch().count())) {
        generar();
    }

    void jugar() {
        mostrarInstrucciones();

        while (true) {
            imprimirTablero(tablero_);

            if (tablero_ == solucion_) {
                std::cout << "\nFelicidades! Completaste el Sudoku.\n";
                break;
            }

            std::cout << "\nIngresa jugada (fila columna valor), 'resolver' o 'salir': ";
            std::string linea;
            if (!std::getline(std::cin, linea)) {
                std::cout << "\nEntrada finalizada.\n";
                break;
            }

            if (linea == "salir") {
                std::cout << "Juego terminado.\n";
                break;
            }

            if (linea == "resolver") {
                std::cout << "\nSolucion:\n";
                imprimirTablero(solucion_);
                break;
            }

            if (linea == "ayuda") {
                mostrarInstrucciones();
                continue;
            }

            std::istringstream iss(linea);
            int fila = 0;
            int columna = 0;
            int valor = 0;
            if (!(iss >> fila >> columna >> valor)) {
                std::cout << "Formato invalido. Usa: fila columna valor\n";
                continue;
            }

            if (fila < 1 || fila > 9 || columna < 1 || columna > 9 || valor < 0 || valor > 9) {
                std::cout << "Rango invalido. fila/columna: 1..9, valor: 0..9\n";
                continue;
            }

            int r = fila - 1;
            int c = columna - 1;

            if (fijas_[r][c]) {
                std::cout << "No puedes modificar una celda fija.\n";
                continue;
            }

            if (valor == 0) {
                tablero_[r][c] = 0;
                std::cout << "Celda limpiada.\n";
                continue;
            }

            if (!esMovimientoValido(tablero_, r, c, valor)) {
                std::cout << "Movimiento invalido por reglas de Sudoku.\n";
                continue;
            }

            tablero_[r][c] = valor;
        }
    }

private:
    Grid solucion_{};
    Grid tablero_{};
    std::array<std::array<bool, 9>, 9> fijas_{};
    std::mt19937 rng_;

    void mostrarInstrucciones() const {
        std::cout << "\n=== Sudoku C++ ===\n";
        std::cout << "Comandos:\n";
        std::cout << "  - fila columna valor   (ej: 3 4 9)\n";
        std::cout << "  - valor 0 limpia una celda (si no es fija)\n";
        std::cout << "  - ayuda               muestra instrucciones\n";
        std::cout << "  - resolver            muestra la solucion y termina\n";
        std::cout << "  - salir               termina el juego\n";
    }

    void generar() {
        solucion_ = generarSolucion();
        tablero_ = solucion_;

        int celdasAEliminar = elegirDificultad();
        eliminarCeldas(celdasAEliminar);

        for (int r = 0; r < 9; ++r) {
            for (int c = 0; c < 9; ++c) {
                fijas_[r][c] = (tablero_[r][c] != 0);
            }
        }
    }

    int elegirDificultad() {
        std::cout << "Selecciona dificultad:\n";
        std::cout << "1) Facil\n";
        std::cout << "2) Media\n";
        std::cout << "3) Dificil\n";
        std::cout << "Opcion [1-3]: ";

        std::string linea;
        if (!std::getline(std::cin, linea)) {
            return 40;
        }

        if (linea == "1") {
            return 35;
        }
        if (linea == "3") {
            return 50;
        }
        return 42;
    }

    Grid generarSolucion() {
        Grid base{};

        std::array<int, 9> numeros{};
        std::iota(numeros.begin(), numeros.end(), 1);
        std::shuffle(numeros.begin(), numeros.end(), rng_);

        for (int r = 0; r < 9; ++r) {
            for (int c = 0; c < 9; ++c) {
                int patron = (r * 3 + r / 3 + c) % 9;
                base[r][c] = numeros[patron];
            }
        }

        permutarBandas(base);
        permutarFilasDentroBandas(base);
        permutarPilas(base);
        permutarColumnasDentroPilas(base);

        return base;
    }

    void permutarBandas(Grid& g) {
        std::array<int, 3> bandas{0, 1, 2};
        std::shuffle(bandas.begin(), bandas.end(), rng_);

        Grid copia = g;
        for (int b = 0; b < 3; ++b) {
            for (int i = 0; i < 3; ++i) {
                g[b * 3 + i] = copia[bandas[b] * 3 + i];
            }
        }
    }

    void permutarFilasDentroBandas(Grid& g) {
        for (int b = 0; b < 3; ++b) {
            std::array<int, 3> orden{0, 1, 2};
            std::shuffle(orden.begin(), orden.end(), rng_);

            Grid copia = g;
            for (int i = 0; i < 3; ++i) {
                g[b * 3 + i] = copia[b * 3 + orden[i]];
            }
        }
    }

    void permutarPilas(Grid& g) {
        std::array<int, 3> pilas{0, 1, 2};
        std::shuffle(pilas.begin(), pilas.end(), rng_);

        Grid copia = g;
        for (int r = 0; r < 9; ++r) {
            for (int p = 0; p < 3; ++p) {
                for (int i = 0; i < 3; ++i) {
                    g[r][p * 3 + i] = copia[r][pilas[p] * 3 + i];
                }
            }
        }
    }

    void permutarColumnasDentroPilas(Grid& g) {
        for (int p = 0; p < 3; ++p) {
            std::array<int, 3> orden{0, 1, 2};
            std::shuffle(orden.begin(), orden.end(), rng_);

            Grid copia = g;
            for (int r = 0; r < 9; ++r) {
                for (int i = 0; i < 3; ++i) {
                    g[r][p * 3 + i] = copia[r][p * 3 + orden[i]];
                }
            }
        }
    }

    void eliminarCeldas(int cantidad) {
        std::vector<int> indices(81);
        std::iota(indices.begin(), indices.end(), 0);
        std::shuffle(indices.begin(), indices.end(), rng_);

        int eliminadas = 0;
        for (int idx : indices) {
            if (eliminadas >= cantidad) {
                break;
            }

            int r = idx / 9;
            int c = idx % 9;
            tablero_[r][c] = 0;
            ++eliminadas;
        }
    }

    bool esMovimientoValido(const Grid& g, int fila, int columna, int valor) const {
        for (int c = 0; c < 9; ++c) {
            if (c != columna && g[fila][c] == valor) {
                return false;
            }
        }

        for (int r = 0; r < 9; ++r) {
            if (r != fila && g[r][columna] == valor) {
                return false;
            }
        }

        int inicioFila = (fila / 3) * 3;
        int inicioColumna = (columna / 3) * 3;
        for (int r = inicioFila; r < inicioFila + 3; ++r) {
            for (int c = inicioColumna; c < inicioColumna + 3; ++c) {
                if ((r != fila || c != columna) && g[r][c] == valor) {
                    return false;
                }
            }
        }

        return true;
    }

    void imprimirTablero(const Grid& g) const {
        std::cout << "\n    1 2 3   4 5 6   7 8 9\n";
        std::cout << "   +-------+-------+-------+\n";

        for (int r = 0; r < 9; ++r) {
            std::cout << " " << (r + 1) << " | ";
            for (int c = 0; c < 9; ++c) {
                if (g[r][c] == 0) {
                    std::cout << ". ";
                } else {
                    std::cout << g[r][c] << " ";
                }

                if ((c + 1) % 3 == 0) {
                    std::cout << "| ";
                }
            }
            std::cout << "\n";

            if ((r + 1) % 3 == 0) {
                std::cout << "   +-------+-------+-------+\n";
            }
        }
    }
};

}  // namespace

int main() {
    Sudoku juego;
    juego.jugar();
    return 0;
}
