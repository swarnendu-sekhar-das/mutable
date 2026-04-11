# Boost dependency configuration
# Use system Boost from Homebrew
find_package(Boost 1.90.0 REQUIRED)
if(Boost_FOUND)
    include_directories(${Boost_INCLUDE_DIRS})
    # Manually link Boost libraries that are commonly available
    set(BOOST_LINK_LIBRARIES 
        /opt/homebrew/Cellar/boost/1.90.0_1/lib/libboost_filesystem.dylib
        /opt/homebrew/Cellar/boost/1.90.0_1/lib/libboost_thread.dylib
        /opt/homebrew/Cellar/boost/1.90.0_1/lib/libboost_regex.dylib
        /opt/homebrew/Cellar/boost/1.90.0_1/lib/libboost_container.dylib
    )
    message(STATUS "Found Boost: ${Boost_INCLUDE_DIRS}")
    message(STATUS "Boost libraries: ${BOOST_LINK_LIBRARIES}")
else()
    message(FATAL_ERROR "Boost not found")
endif()
