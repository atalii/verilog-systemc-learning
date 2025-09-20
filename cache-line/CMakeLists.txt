cmake_minimum_required(VERSION 3.25)
project(cache)

set(SYSTEMC_HOME $ENV{SYSTEMC_HOME})
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include_directories(${SYSTEMC_HOME}/include)
link_directories(${SYSTEMC_HOME}/lib)

find_package(verilator)
add_executable(cache sc_main.cpp)
verilate(cache SOURCES cacheline.v SYSTEMC)
verilate(cache SOURCES cache.v SYSTEMC)
verilator_link_systemc(cache)
