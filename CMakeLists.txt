cmake_minimum_required(VERSION 3.25)
project(cache)

include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/refs/tags/v1.17.0.zip
)

FetchContent_MakeAvailable(googletest)

include(GoogleTest)

set(SYSTEMC_HOME $ENV{SYSTEMC_HOME})
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include_directories(${SYSTEMC_HOME}/include)
link_directories(${SYSTEMC_HOME}/lib)
find_package(verilator)

enable_testing()
add_executable(cache sc_main.cpp)
target_link_libraries(cache PRIVATE GTest::gtest_main)

verilate(cache SOURCES cache.sv SYSTEMC)
verilator_link_systemc(cache)
