# Replxx dependency configuration
# Use system Replxx from Homebrew
find_package(replxx CONFIG QUIET PATHS /opt/homebrew/share/cmake/replxx)
if(replxx_FOUND)
    set(Replxx_LIBRARIES replxx::replxx)
    message(STATUS "Found Replxx via CMake config")
else()
    # Fallback: manual detection
    find_library(REPLXX_LIB replxx PATHS /opt/homebrew/lib)
    find_path(REPLXX_INCLUDE replxx.hxx PATHS /opt/homebrew/include)
    if(REPLXX_LIB AND REPLXX_INCLUDE)
        include_directories(${REPLXX_INCLUDE})
        set(Replxx_LIBRARIES ${REPLXX_LIB})
        message(STATUS "Found Replxx manually: ${REPLXX_LIB}")
    else()
        message(WARNING "Replxx not found, shell will be built without Replxx support")
    endif()
endif()
