cmake_minimum_required(VERSION 3.12 FATAL_ERROR)
project(st7789)

file(GLOB st7789_sources CONFIGURE_DEPENDS "${C_SRC}/*.cpp" "${C_SRC}/*.hpp")
find_package(OpenMP)

add_executable(st7789.so ${st7789_sources})
set_property(TARGET st7789.so PROPERTY CXX_STANDARD 14)
if(OpenMP_CXX_FOUND)
    target_link_libraries(st7789.so PUBLIC OpenMP::OpenMP_CXX)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
endif()

set_target_properties(st7789.so PROPERTIES
    INSTALL_RPATH_USE_LINK_PATH TRUE
    BUILD_WITH_INSTALL_RPATH TRUE
)

if(UNIX AND NOT APPLE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -shared")
else()
    # Although the compiler complains about not using these,
    # things only work with them set
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -undefined dynamic_lookup -dynamiclib")
    set(CMAKE_SHARED_LINKER_FLAGS "-bundle -flat_namespace -undefined suppress")
endif()

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC -I${ERTS_INCLUDE_DIR} -O3 -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers")
