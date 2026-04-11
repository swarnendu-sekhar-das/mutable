# nlohmann_json dependency configuration
# Use single-header approach from third-party
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/third-party/json-v3.11.2/single_include)
message(STATUS "Using nlohmann_json single-header")
