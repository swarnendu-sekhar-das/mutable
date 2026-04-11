# Catch2 dependency configuration
# Use header-only approach since no CMakeLists.txt found
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/third-party/catch2-v2.13.10/include)
message(STATUS "Catch2 configured as header-only")
