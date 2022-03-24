cmake_minimum_required(VERSION 3.18)
# not necessary to speify LANGUAGES, but do it for bonus points
project(mac2iosPbxproj LANGUAGES C CXX OBJC OBJCXX)

if(NOT DEFINED ANDROID_TOOL_BASE)
    message(FATAL_ERROR "need ANDROID_TOOL_BASE")
endif()

# must be deprecated, specifying this makes garbage print out from the compiler
# set(CMAKE_C_FLAGS " -x objective-c ")
# set(CMAKE_CXX_FLAGS "-x objective-c++")

set(CMAKE_EXE_LINKER_FLAGS " -framework Cocoa -framework AppKit -framework CoreData -framework Foundation ")
set(CMAKE_SHARED_LINKER_FLAGS " -framework Cocoa -framework AppKit -framework CoreData -framework Foundation ")

add_executable(${PROJECT_NAME}.x cEntry.c XMLReader.m main.m cMain.c)
add_library(${PROJECT_NAME} SHARED XMLReader.m main.m cMain.c)

# not necessary, just sets the objc version
set_property(TARGET ${PROJECT_NAME}.x PROPERTY OBJC_STANDARD 11)
set_property(TARGET ${PROJECT_NAME} PROPERTY OBJC_STANDARD 11)

set(TARG_INC_LOC
    ${ANDROID_TOOL_BASE}/common/local_util)

target_include_directories(${PROJECT_NAME}.x PRIVATE ${TARG_INC_LOC})
target_include_directories(${PROJECT_NAME} PRIVATE ${TARG_INC_LOC})
