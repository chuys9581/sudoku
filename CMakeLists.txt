cmake_minimum_required(VERSION 3.16)
project(SudokuCPP LANGUAGES CXX OBJCXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_OBJCXX_STANDARD 17)
set(CMAKE_OBJCXX_STANDARD_REQUIRED ON)
set(CMAKE_OBJCXX_EXTENSIONS OFF)

add_executable(SudokuApp main.mm)
target_link_libraries(SudokuApp "-framework Cocoa" "-framework QuartzCore")
