find_package(Boost REQUIRED COMPONENTS atomic container thread)
set(BOOST_LINK_LIBRARIES Boost::atomic Boost::container Boost::thread)
include_directories(SYSTEM ${Boost_INCLUDE_DIRS})
