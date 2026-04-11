# depot_tools dependency configuration
# Set depot_tools path for V8 build
set(DEPOT_TOOLS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/third-party/depot_tools-530d86d40b2aab70e0541ea0f296388ec09f0576)
set(ENV{PATH} "${DEPOT_TOOLS_DIR}:$ENV{PATH}")
message(STATUS "Depot tools configured at: ${DEPOT_TOOLS_DIR}")
