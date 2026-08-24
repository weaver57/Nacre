cmake_minimum_required(VERSION 3.20)
project(nacre VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick)

# ── Nacre library (C++ backends) ───────────────────────────────────
# ConfigManager is the only C++ component for now. More services
# (audio, network, etc.) get added here as they arrive.
add_library(nacre STATIC
    config/ConfigManager.cpp
)

target_include_directories(nacre PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(nacre PUBLIC
    Qt6::Core
    Qt6::Quick
)

# ── Quickshell entry point ────────────────────────────────────────
# shell.qml is the root file Quickshell loads. No compiled binary —
# Quickshell interprets QML directly. The C++ library is loaded
# as a plugin that QML can import.
#
# To run:
#   quickshell -p .
#
# Quickshell finds the C++ types via the plugin mechanism.
