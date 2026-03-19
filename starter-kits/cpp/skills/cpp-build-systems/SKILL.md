---
name: cpp-build-systems
description: Configure and use CMake effectively — project structure, targets, dependencies, testing integration, and preset workflows
---

# C++ Build Systems

> Skill metadata: version "1.0"; license MIT; tags [cpp, cmake, build, conan, vcpkg]; recommended tools [codebase, runCommands, editFiles].

## When to use

- Setting up or modifying a CMake build system
- Adding dependencies via Conan or vcpkg
- Configuring CTest and integrating with test frameworks
- Troubleshooting build failures

## CMake project structure

```text
project/
  CMakeLists.txt           # Root — project(), cmake_minimum_required()
  CMakePresets.json         # Build presets (debug, release, CI)
  src/
    CMakeLists.txt          # Library/executable targets
    main.cpp
    lib/
      module.cpp
      module.h
  tests/
    CMakeLists.txt          # Test targets
    test_module.cpp
  cmake/
    CompilerWarnings.cmake  # Reusable modules
```

## CMake conventions

### Minimum version and project

```cmake
cmake_minimum_required(VERSION 3.25)
project(MyProject VERSION 1.0.0 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
```

### Targets

- Use `target_*` commands — never set global `CMAKE_*` variables for compile options.
- Use `PRIVATE`/`PUBLIC`/`INTERFACE` correctly for include paths and link libraries.
- Prefer `add_library(mylib)` with sources added via `target_sources()`.

```cmake
add_library(mylib)
target_sources(mylib PRIVATE src/module.cpp)
target_include_directories(mylib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/src)
```

### Compiler warnings

```cmake
target_compile_options(mylib PRIVATE
  $<$<CXX_COMPILER_ID:GNU,Clang>:-Wall -Wextra -Wpedantic -Werror>
  $<$<CXX_COMPILER_ID:MSVC>:/W4 /WX>
)
```

### Testing with CTest

```cmake
enable_testing()
add_executable(tests tests/test_module.cpp)
target_link_libraries(tests PRIVATE mylib GTest::gtest_main)
include(GoogleTest)
gtest_discover_tests(tests)
```

### CMake presets

Use `CMakePresets.json` for reproducible builds:

```json
{
  "version": 6,
  "configurePresets": [
    {
      "name": "debug",
      "binaryDir": "${sourceDir}/build/debug",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug",
        "CMAKE_EXPORT_COMPILE_COMMANDS": "ON"
      }
    }
  ]
}
```

## Dependency management

| Manager | Best for |
|---------|----------|
| vcpkg | Microsoft ecosystem, Windows-first projects |
| Conan | Cross-platform, large dependency graphs |
| FetchContent | Single-header or small dependencies |

### FetchContent example

```cmake
include(FetchContent)
FetchContent_Declare(
  googletest
  GIT_REPOSITORY https://github.com/google/googletest.git
  GIT_TAG v1.14.0
)
FetchContent_MakeAvailable(googletest)
```

## Build commands

```bash
cmake --preset debug              # Configure
cmake --build build/debug -j      # Build
ctest --test-dir build/debug      # Test
```
