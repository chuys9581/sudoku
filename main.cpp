#include "raylib.h"
#include "SudokuEngine.h"
#include <string>
#include <map>
#include <fstream>
#include <sstream>
#include <vector>
#include <functional>
#include <algorithm>

// --- Persistence ---
std::map<std::string, std::string> userPasswords;
std::map<std::string, int> userPoints;
std::map<std::string, int> userBestTimes;
std::string currentUser = "";

void LoadUsers() {
    std::ifstream file("users.txt");
    std::string line;
    while (std::getline(file, line)) {
        std::stringstream ss(line);
        std::string user, pass, pts, time;
        if (std::getline(ss, user, '|')) {
            std::getline(ss, pass, '|');
            std::getline(ss, pts, '|');
            std::getline(ss, time, '|');
            userPasswords[user] = pass;
            userPoints[user] = pts.empty() ? 0 : std::stoi(pts);
            userBestTimes[user] = time.empty() ? 0 : std::stoi(time);
        }
    }
}

void SaveUsers() {
    std::ofstream file("users.txt");
    for (auto const& [user, pass] : userPasswords) {
        file << user << "|" << pass << "|" << userPoints[user] << "|" << userBestTimes[user] << "\n";
    }
}

std::string HashPassword(const std::string& pwd) {
    std::hash<std::string> hasher;
    return std::to_string(hasher(pwd));
}

// --- App State ---
enum Screen { LOGIN, MENU, GAME };
Screen currentScreen = LOGIN;

SudokuEngine engine;
Difficulty selectedDifficulty = Difficulty::Medium;

// Game State
int selectedCell = -1;
int lives = 3;
int points = 0;
bool isGameOver = false;
bool isVictory = false;
double gameStartTime = 0;
int finalTime = 0;
bool blockCompleted[9] = {false};

// Login State
std::string loginUsername = "";
std::string loginPassword = "";
bool isUsernameFocused = true;
std::string authError = "";

// Helpers
void DrawCyberBackground() {
    ClearBackground((Color){5, 10, 25, 255});
    for (int y = 0; y < 830; y += 40) {
        DrawLine(0, y, 1180, y, (Color){25, 214, 245, 30});
    }
    for (int x = 0; x < 1180; x += 40) {
        DrawLine(x, 0, x, 830, (Color){56, 245, 183, 20});
    }
}

bool DrawButton(Rectangle rect, const char* text) {
    bool clicked = false;
    Vector2 mouse = GetMousePosition();
    bool hover = CheckCollisionPointRec(mouse, rect);

    if (hover && IsMouseButtonPressed(MOUSE_LEFT_BUTTON)) {
        clicked = true;
    }

    Color bg = hover ? (Color){30, 100, 150, 255} : (Color){15, 69, 107, 255};
    DrawRectangleRec(rect, bg);
    DrawRectangleLinesEx(rect, 2, (Color){53, 242, 224, 190});
    
    int tw = MeasureText(text, 20);
    DrawText(text, rect.x + (rect.width - tw) / 2, rect.y + (rect.height - 20) / 2, 20, (Color){209, 250, 252, 255});

    return clicked;
}

void DrawTextInput(Rectangle rect, std::string& text, bool focused, bool isPassword) {
    DrawRectangleRec(rect, (Color){7, 28, 51, 230});
    DrawRectangleLinesEx(rect, 2, focused ? (Color){40, 204, 240, 255} : (Color){40, 204, 240, 100});

    std::string display = isPassword ? std::string(text.length(), '*') : text;
    DrawText(display.c_str(), rect.x + 10, rect.y + (rect.height - 20) / 2, 20, (Color){199, 247, 252, 255});

    if (focused) {
        int key = GetCharPressed();
        while (key > 0) {
            if ((key >= 32) && (key <= 125) && text.length() < 16) {
                text += (char)key;
            }
            key = GetCharPressed();
        }

        if (IsKeyPressed(KEY_BACKSPACE) && text.length() > 0) {
            text.pop_back();
        }
    }

    if (IsMouseButtonPressed(MOUSE_LEFT_BUTTON) && CheckCollisionPointRec(GetMousePosition(), rect)) {
        isUsernameFocused = !isPassword;
    }
}

// --- Screens ---
void UpdateDrawLogin() {
    DrawCyberBackground();

    DrawText("ACCESO AL SISTEMA", 400, 200, 40, (Color){158, 247, 255, 255});

    DrawText("Usuario:", 350, 300, 20, LIGHTGRAY);
    DrawTextInput({450, 290, 300, 40}, loginUsername, isUsernameFocused, false);

    DrawText("Password:", 350, 360, 20, LIGHTGRAY);
    DrawTextInput({450, 350, 300, 40}, loginPassword, !isUsernameFocused, true);

    if (DrawButton({400, 450, 180, 40}, "Iniciar Sesion")) {
        if (loginUsername.empty()) authError = "Usuario invalido";
        else {
            auto it = userPasswords.find(loginUsername);
            if (it != userPasswords.end() && it->second == HashPassword(loginPassword)) {
                currentUser = loginUsername;
                currentScreen = MENU;
            } else {
                authError = "Credenciales incorrectas";
            }
        }
    }

    if (DrawButton({600, 450, 180, 40}, "Crear Usuario")) {
        if (loginUsername.length() < 3 || loginPassword.length() < 4) {
            authError = "Usuario (min 3), Password (min 4)";
        } else {
            if (userPasswords.find(loginUsername) != userPasswords.end()) {
                authError = "El usuario ya existe";
            } else {
                userPasswords[loginUsername] = HashPassword(loginPassword);
                userPoints[loginUsername] = 0;
                userBestTimes[loginUsername] = 0;
                SaveUsers();
                currentUser = loginUsername;
                currentScreen = MENU;
            }
        }
    }

    if (!authError.empty()) {
        DrawText(authError.c_str(), 450, 520, 20, RED);
    }
}

void StartGame() {
    engine.newGame(selectedDifficulty);
    selectedCell = -1;
    points = 0;
    lives = (selectedDifficulty == Difficulty::Easy) ? 5 : (selectedDifficulty == Difficulty::Medium ? 3 : 1);
    for (int i=0; i<9; i++) blockCompleted[i] = false;
    isGameOver = false;
    isVictory = false;
    gameStartTime = GetTime();
    currentScreen = GAME;
}

void UpdateDrawMenu() {
    DrawCyberBackground();

    DrawText("MENU PRINCIPAL", 400, 200, 50, (Color){148, 250, 255, 255});
    std::string info = "Usuario activo: " + currentUser + " | Puntos totales: " + std::to_string(userPoints[currentUser]);
    DrawText(info.c_str(), 350, 280, 20, (Color){191, 247, 214, 255});

    DrawText("Dificultad:", 450, 360, 20, LIGHTGRAY);
    if (DrawButton({570, 350, 100, 40}, selectedDifficulty == Difficulty::Easy ? "Facil" : (selectedDifficulty == Difficulty::Medium ? "Media" : "Dificil"))) {
        if (selectedDifficulty == Difficulty::Easy) selectedDifficulty = Difficulty::Medium;
        else if (selectedDifficulty == Difficulty::Medium) selectedDifficulty = Difficulty::Hard;
        else selectedDifficulty = Difficulty::Easy;
    }

    if (DrawButton({450, 450, 250, 50}, "Jugar Sudoku")) {
        StartGame();
    }
}

void CheckBlockCompletion() {
    for (int b = 0; b < 9; ++b) {
        if (blockCompleted[b]) continue;
        int sr = (b / 3) * 3;
        int sc = (b % 3) * 3;
        bool complete = true;
        for (int r = sr; r < sr + 3; ++r) {
            for (int c = sc; c < sc + 3; ++c) {
                if (engine.valueAt(r, c) == 0) complete = false;
            }
        }
        if (complete) blockCompleted[b] = true;
    }
}

void UpdateDrawGame() {
    DrawCyberBackground();

    if (DrawButton({30, 30, 120, 40}, "Volver")) {
        currentScreen = MENU;
    }

    // Status Panel
    DrawRectangle(800, 150, 300, 400, (Color){7, 20, 38, 200});
    DrawRectangleLines(800, 150, 300, 400, (Color){33, 211, 237, 160});
    
    DrawText(TextFormat("Vidas: %d", lives), 820, 180, 24, (Color){250, 143, 127, 255});
    DrawText(TextFormat("Puntos: %d", points), 820, 220, 24, (Color){145, 247, 194, 255});
    
    int elapsed = isGameOver || isVictory ? finalTime : (int)(GetTime() - gameStartTime);
    DrawText(TextFormat("Tiempo: %02d:%02d", elapsed / 60, elapsed % 60), 820, 260, 24, WHITE);

    // Draw Board
    int startX = 200;
    int startY = 150;
    int cellSize = 60;

    for (int r = 0; r < 9; ++r) {
        for (int c = 0; c < 9; ++c) {
            int idx = r * 9 + c;
            int bIdx = (r / 3) * 3 + (c / 3);
            Rectangle rect = {(float)(startX + c * cellSize), (float)(startY + r * cellSize), (float)cellSize, (float)cellSize};
            
            Color bg = (idx == selectedCell) ? (Color){28, 74, 112, 255} : (Color){10, 28, 48, 255};
            if (blockCompleted[bIdx] && idx != selectedCell) bg = (Color){0, 102, 102, 100};
            
            DrawRectangleRec(rect, bg);
            DrawRectangleLinesEx(rect, 1, blockCompleted[bIdx] ? (Color){51, 229, 204, 255} : (Color){40, 193, 234, 178});

            if (IsMouseButtonPressed(MOUSE_LEFT_BUTTON) && CheckCollisionPointRec(GetMousePosition(), rect) && !isGameOver && !isVictory) {
                selectedCell = idx;
            }

            int val = engine.valueAt(r, c);
            if (val != 0) {
                Color txtCol = engine.isFixed(r, c) ? (Color){147, 247, 214, 255} : (Color){199, 242, 255, 255};
                int w = MeasureText(TextFormat("%d", val), 30);
                DrawText(TextFormat("%d", val), rect.x + (cellSize - w)/2, rect.y + 15, 30, txtCol);
            }
        }
    }

    // Thicker block lines
    for (int i = 0; i <= 9; i += 3) {
        DrawLineEx({(float)(startX + i * cellSize), (float)startY}, {(float)(startX + i * cellSize), (float)(startY + 9 * cellSize)}, 3, (Color){40, 193, 234, 255});
        DrawLineEx({(float)startX, (float)(startY + i * cellSize)}, {(float)(startX + 9 * cellSize), (float)(startY + i * cellSize)}, 3, (Color){40, 193, 234, 255});
    }

    // Input Handling
    if (selectedCell >= 0 && !isGameOver && !isVictory) {
        int r = selectedCell / 9;
        int c = selectedCell % 9;
        
        int key = GetKeyPressed();
        if (key >= KEY_ONE && key <= KEY_NINE) {
            int val = key - KEY_ZERO;
            if (!engine.isFixed(r, c)) {
                if (val == engine.solutionValueAt(r, c)) {
                    if (engine.valueAt(r, c) == 0) points += 120;
                    engine.setValue(r, c, val);
                    CheckBlockCompletion();
                    if (engine.isComplete()) {
                        isVictory = true;
                        finalTime = elapsed;
                        points += lives * 75;
                        userPoints[currentUser] += points;
                        if (userBestTimes[currentUser] == 0 || finalTime < userBestTimes[currentUser]) {
                            userBestTimes[currentUser] = finalTime;
                        }
                        SaveUsers();
                    }
                } else {
                    lives--;
                    points = std::max(0, points - 25);
                    if (lives <= 0) {
                        isGameOver = true;
                        finalTime = elapsed;
                    }
                }
            }
        } else if (key == KEY_BACKSPACE || key == KEY_ZERO) {
            engine.setValue(r, c, 0);
        }
    }

    // Overlays
    if (isGameOver) {
        DrawRectangle(0, 0, 1180, 830, (Color){0, 0, 0, 200});
        DrawText("GAME OVER", 400, 300, 60, RED);
        if (DrawButton({500, 450, 180, 40}, "Menu Principal")) currentScreen = MENU;
    } else if (isVictory) {
        DrawRectangle(0, 0, 1180, 830, (Color){0, 12, 25, 220});
        DrawText("VICTORIA!", 450, 250, 60, (Color){51, 250, 204, 255});
        DrawText(TextFormat("Tiempo: %02d:%02d | Puntos: %d", finalTime / 60, finalTime % 60, points), 400, 350, 30, WHITE);
        if (DrawButton({500, 450, 180, 40}, "Menu Principal")) currentScreen = MENU;
    }
}

int main() {
    LoadUsers();
    InitWindow(1180, 830, "Sudoku Cyber (Raylib)");
    SetTargetFPS(60);

    while (!WindowShouldClose()) {
        BeginDrawing();
        
        switch (currentScreen) {
            case LOGIN: UpdateDrawLogin(); break;
            case MENU: UpdateDrawMenu(); break;
            case GAME: UpdateDrawGame(); break;
        }

        EndDrawing();
    }

    CloseWindow();
    return 0;
}
