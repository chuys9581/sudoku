#pragma once

#include <algorithm>
#include <array>
#include <chrono>
#include <numeric>
#include <random>
#include <vector>

enum class Difficulty {
  Easy,
  Medium,
  Hard,
};

using Grid = std::array<std::array<int, 9>, 9>;

class SudokuEngine {
public:
  SudokuEngine()
      : rng_(static_cast<unsigned>(std::chrono::high_resolution_clock::now()
                                       .time_since_epoch()
                                       .count())) {
    newGame(Difficulty::Medium);
  }

  void newGame(Difficulty difficulty) {
    solution_ = generateSolution();
    board_ = solution_;

    int cellsToRemove = 42;
    switch (difficulty) {
    case Difficulty::Easy:
      cellsToRemove = 35;
      break;
    case Difficulty::Medium:
      cellsToRemove = 42;
      break;
    case Difficulty::Hard:
      cellsToRemove = 50;
      break;
    }

    removeCells(cellsToRemove);

    for (int r = 0; r < 9; ++r) {
      for (int c = 0; c < 9; ++c) {
        fixed_[r][c] = (board_[r][c] != 0);
      }
    }
  }

  int valueAt(int row, int col) const { return board_[row][col]; }

  int solutionValueAt(int row, int col) const { return solution_[row][col]; }

  bool isFixed(int row, int col) const { return fixed_[row][col]; }

  bool setValue(int row, int col, int value) {
    if (fixed_[row][col]) {
      return false;
    }

    if (value == 0) {
      board_[row][col] = 0;
      return true;
    }

    if (value < 1 || value > 9) {
      return false;
    }

    board_[row][col] = value;
    return true;
  }

  int wrongCellCount() const {
    int wrong = 0;
    for (int r = 0; r < 9; ++r) {
      for (int c = 0; c < 9; ++c) {
        if (board_[r][c] != 0 && board_[r][c] != solution_[r][c]) {
          ++wrong;
        }
      }
    }
    return wrong;
  }

  int emptyCellCount() const {
    int empty = 0;
    for (int r = 0; r < 9; ++r) {
      for (int c = 0; c < 9; ++c) {
        if (board_[r][c] == 0) {
          ++empty;
        }
      }
    }
    return empty;
  }

  bool isComplete() const { return board_ == solution_; }

  void revealSolution() { board_ = solution_; }

private:
  Grid solution_{};
  Grid board_{};
  std::array<std::array<bool, 9>, 9> fixed_{};
  std::mt19937 rng_;

  Grid generateSolution() {
    Grid base{};

    std::array<int, 9> numbers{};
    std::iota(numbers.begin(), numbers.end(), 1);
    std::shuffle(numbers.begin(), numbers.end(), rng_);

    for (int r = 0; r < 9; ++r) {
      for (int c = 0; c < 9; ++c) {
        int pattern = (r * 3 + r / 3 + c) % 9;
        base[r][c] = numbers[pattern];
      }
    }

    shuffleBands(base);
    shuffleRowsInBands(base);
    shuffleStacks(base);
    shuffleColsInStacks(base);

    return base;
  }

  void shuffleBands(Grid &grid) {
    std::array<int, 3> bands{0, 1, 2};
    std::shuffle(bands.begin(), bands.end(), rng_);

    Grid copy = grid;
    for (int b = 0; b < 3; ++b) {
      for (int i = 0; i < 3; ++i) {
        grid[b * 3 + i] = copy[bands[b] * 3 + i];
      }
    }
  }

  void shuffleRowsInBands(Grid &grid) {
    Grid copy = grid;
    for (int b = 0; b < 3; ++b) {
      std::array<int, 3> order{0, 1, 2};
      std::shuffle(order.begin(), order.end(), rng_);
      for (int i = 0; i < 3; ++i) {
        grid[b * 3 + i] = copy[b * 3 + order[i]];
      }
    }
  }

  void shuffleStacks(Grid &grid) {
    std::array<int, 3> stacks{0, 1, 2};
    std::shuffle(stacks.begin(), stacks.end(), rng_);

    Grid copy = grid;
    for (int r = 0; r < 9; ++r) {
      for (int s = 0; s < 3; ++s) {
        for (int i = 0; i < 3; ++i) {
          grid[r][s * 3 + i] = copy[r][stacks[s] * 3 + i];
        }
      }
    }
  }

  void shuffleColsInStacks(Grid &grid) {
    Grid copy = grid;
    for (int s = 0; s < 3; ++s) {
      std::array<int, 3> order{0, 1, 2};
      std::shuffle(order.begin(), order.end(), rng_);
      for (int r = 0; r < 9; ++r) {
        for (int i = 0; i < 3; ++i) {
          grid[r][s * 3 + i] = copy[r][s * 3 + order[i]];
        }
      }
    }
  }

  void removeCells(int count) {
    std::vector<int> indexes(81);
    std::iota(indexes.begin(), indexes.end(), 0);
    std::shuffle(indexes.begin(), indexes.end(), rng_);

    int removed = 0;
    for (int idx : indexes) {
      if (removed >= count) {
        break;
      }

      int r = idx / 9;
      int c = idx % 9;
      board_[r][c] = 0;
      ++removed;
    }
  }
};
