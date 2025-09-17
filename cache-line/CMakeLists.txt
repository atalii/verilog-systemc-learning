cmake_minimum_required(VERSION 3.25)
project(cache)

set(SYSTEMC_HOME $ENV{SYSTEMC_HOME})
include_directories(${SYSTEMC_HOME}/include)
link_directories(${SYSTEMC_HOME}/lib)

find_package(verilator)
add_executable(cache sc_main.cpp)
verilate(cache SOURCES cacheline.v SYSTEMC)
verilator_link_systemc(cache)
